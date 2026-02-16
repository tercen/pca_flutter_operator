import 'dart:math';

/// Result of PCA computation
class PcaResult {
  /// Scores matrix: n_obs x n_comp (observations projected onto PCs)
  final List<List<double>> scores;

  /// Loadings matrix: n_vars x n_comp (variable contributions to PCs)
  final List<List<double>> loadings;

  /// Eigenvalues for the first nComponents PCs
  final List<double> eigenvalues;

  /// Percentage of total variance for the first nComponents PCs (0-100)
  final List<double> variancePercent;

  /// ALL eigenvalues from decomposition (for screeplot)
  final List<double> allEigenvalues;

  /// ALL variance percentages (for screeplot)
  final List<double> allVariancePercent;

  /// Number of score/loading components returned
  final int nComponents;

  PcaResult({
    required this.scores,
    required this.loadings,
    required this.eigenvalues,
    required this.variancePercent,
    required this.allEigenvalues,
    required this.allVariancePercent,
    required this.nComponents,
  });
}

/// PCA computation using the dual method (n_obs x n_obs Gram matrix).
/// Optimal when n_obs << n_vars (typical: 10-500 obs, 100-20000 vars).
///
/// Algorithm:
/// 1. Center (and optionally scale) the data matrix X (n_obs x n_vars)
/// 2. Compute Gram matrix G = X * X^T / (n_obs - 1)  [n_obs x n_obs]
/// 3. Eigendecompose G using Householder tridiagonalization + QL iteration
/// 4. Recover scores and loadings from eigenvectors
class PcaComputation {
  /// Test the eigenvalue algorithm with a known matrix.
  /// Returns the eigenvalues (sorted descending).
  static List<double> testEigen(List<List<double>> A) {
    final n = A.length;
    final (eigenvalues, _) = _symmetricEigen(
        List.generate(n, (i) => List<double>.from(A[i])), n);
    return eigenvalues;
  }

  /// Compute PCA from a data matrix.
  ///
  /// [X] is n_obs x n_vars (each row = one observation, each col = one variable).
  /// [scale] if true, divide centered columns by their std dev before PCA.
  /// [nComponents] max number of PCs to return (clamped to available).
  /// [subtractComponent] if > 0 (1-indexed), remove that PC's contribution and re-run.
  static PcaResult compute({
    required List<List<double>> X,
    required bool scale,
    required int nComponents,
    int subtractComponent = 0,
  }) {
    final nObs = X.length;
    if (nObs < 2) {
      throw ArgumentError('PCA requires at least 2 observations, got $nObs');
    }
    final nVars = X[0].length;
    if (nVars < 2) {
      throw ArgumentError('PCA requires at least 2 variables, got $nVars');
    }

    // Check for NaN/infinity
    for (int i = 0; i < nObs; i++) {
      for (int j = 0; j < nVars; j++) {
        if (X[i][j].isNaN || X[i][j].isInfinite) {
          throw ArgumentError(
              'Missing or infinite value at observation $i, variable $j');
        }
      }
    }

    // Center and optionally scale
    var centered = _centerAndScale(X, nObs, nVars, scale);

    // Component subtraction: remove a PC and re-run
    if (subtractComponent > 0) {
      final maxComp = min(nObs - 1, nVars);
      if (subtractComponent <= maxComp) {
        // First PCA pass to get the component to subtract
        final firstPass = _computePca(centered, nObs, nVars, maxComp);
        // Subtract: X_new = X - score_k * loading_k^T
        final k = subtractComponent - 1; // 0-indexed
        centered = _subtractComponent(centered, nObs, nVars,
            firstPass.scores, firstPass.loadings, k);
      }
    }

    // Clamp nComponents
    final maxComponents = min(nObs - 1, nVars);
    final nc = nComponents.clamp(1, maxComponents);

    return _computePca(centered, nObs, nVars, nc);
  }

  static PcaResult _computePca(
      List<List<double>> X, int nObs, int nVars, int nComponents) {
    // Compute Gram matrix G = X * X^T
    final G = _gramMatrix(X, nObs, nVars);

    // Divide by (n-1) to get covariance-like matrix
    final divisor = nObs - 1;
    for (int i = 0; i < nObs; i++) {
      for (int j = 0; j < nObs; j++) {
        G[i][j] /= divisor;
      }
    }

    // Eigendecompose (returns eigenvalues descending + eigenvectors as columns)
    final (eigenvalues, eigenvectors) = _symmetricEigen(G, nObs);

    // Clamp negative eigenvalues (numerical noise) to 0
    for (int i = 0; i < eigenvalues.length; i++) {
      if (eigenvalues[i] < 0) eigenvalues[i] = 0;
    }

    final nc = min(nComponents, eigenvalues.length);

    // Scores: U_k * sqrt(lambda_k) for each observation
    // eigenvectors[i][k] is the k-th eigenvector component for observation i
    final scores = List.generate(nObs, (i) =>
        List.generate(nc, (k) {
          final ev = eigenvalues[k];
          return ev > 1e-12 ? eigenvectors[i][k] * sqrt(ev * divisor) : 0.0;
        }));

    // Loadings: X^T * U_k / sqrt(lambda_k * (n-1)) for each variable
    final loadings = List.generate(nVars, (j) =>
        List.generate(nc, (k) {
          final ev = eigenvalues[k];
          if (ev < 1e-12) return 0.0;
          double dot = 0;
          for (int i = 0; i < nObs; i++) {
            dot += X[i][j] * eigenvectors[i][k];
          }
          return dot / sqrt(ev * divisor);
        }));

    // Variance
    final totalVariance = eigenvalues.fold(0.0, (a, b) => a + b);
    final variancePercent = List.generate(nc, (k) =>
        totalVariance > 0 ? 100.0 * eigenvalues[k] / totalVariance : 0.0);
    final allVariancePercent = List.generate(eigenvalues.length, (k) =>
        totalVariance > 0 ? 100.0 * eigenvalues[k] / totalVariance : 0.0);

    return PcaResult(
      scores: scores,
      loadings: loadings,
      eigenvalues: eigenvalues.sublist(0, nc),
      variancePercent: variancePercent,
      allEigenvalues: List.unmodifiable(eigenvalues),
      allVariancePercent: allVariancePercent,
      nComponents: nc,
    );
  }

  /// Center columns (subtract mean) and optionally scale (divide by std dev).
  static List<List<double>> _centerAndScale(
      List<List<double>> X, int nObs, int nVars, bool scale) {
    final result = List.generate(nObs, (i) => List<double>.from(X[i]));

    for (int j = 0; j < nVars; j++) {
      // Column mean
      double sum = 0;
      for (int i = 0; i < nObs; i++) {
        sum += result[i][j];
      }
      final mean = sum / nObs;

      // Center
      for (int i = 0; i < nObs; i++) {
        result[i][j] -= mean;
      }

      // Optionally scale
      if (scale) {
        double ssq = 0;
        for (int i = 0; i < nObs; i++) {
          ssq += result[i][j] * result[i][j];
        }
        final stdDev = sqrt(ssq / (nObs - 1));
        if (stdDev > 1e-12) {
          for (int i = 0; i < nObs; i++) {
            result[i][j] /= stdDev;
          }
        }
      }
    }
    return result;
  }

  /// Compute Gram matrix G = X * X^T (n_obs x n_obs).
  static List<List<double>> _gramMatrix(
      List<List<double>> X, int nObs, int nVars) {
    final G = List.generate(nObs, (_) => List.filled(nObs, 0.0));
    for (int i = 0; i < nObs; i++) {
      for (int j = i; j < nObs; j++) {
        double dot = 0;
        for (int k = 0; k < nVars; k++) {
          dot += X[i][k] * X[j][k];
        }
        G[i][j] = dot;
        G[j][i] = dot;
      }
    }
    return G;
  }

  /// Subtract a component's contribution from the data matrix.
  /// X_new = X - scores[:,k] * loadings[:,k]^T
  static List<List<double>> _subtractComponent(
      List<List<double>> X, int nObs, int nVars,
      List<List<double>> scores, List<List<double>> loadings, int k) {
    final result = List.generate(nObs, (i) => List<double>.from(X[i]));
    for (int i = 0; i < nObs; i++) {
      for (int j = 0; j < nVars; j++) {
        result[i][j] -= scores[i][k] * loadings[j][k];
      }
    }
    return result;
  }

  /// Symmetric eigenvalue decomposition using Householder tridiagonalization
  /// followed by QL iteration with implicit shifts.
  /// This is the standard LAPACK approach (tred2 + tql2), robust for
  /// degenerate (repeated) eigenvalues.
  ///
  /// Returns (eigenvalues sorted descending, eigenvectors as columns of V).
  /// V[i][k] is the i-th component of the k-th eigenvector.
  static (List<double>, List<List<double>>) _symmetricEigen(
      List<List<double>> A, int n) {
    // V accumulates eigenvectors; starts as copy of A, modified in-place
    final V = List.generate(n, (i) => List<double>.from(A[i]));
    final d = List<double>.filled(n, 0.0); // eigenvalues (diagonal)
    final e = List<double>.filled(n, 0.0); // off-diagonal

    // Step 1: Householder tridiagonalization (tred2)
    _tred2(V, d, e, n);

    // Step 2: QL iteration with implicit shifts (tql2)
    _tql2(V, d, e, n);

    // Sort descending by eigenvalue
    final indices = List.generate(n, (i) => i);
    indices.sort((a, b) => d[b].compareTo(d[a]));

    final sortedEigenvalues = indices.map((i) => d[i]).toList();
    final sortedV = List.generate(n, (row) =>
        indices.map((i) => V[row][i]).toList());

    return (sortedEigenvalues, sortedV);
  }

  /// Householder tridiagonalization of a symmetric matrix.
  /// Based on EISPACK/JAMA tred2. Reduces A to tridiagonal form T = Q^T A Q,
  /// where Q is orthogonal. On exit:
  ///   d[] = diagonal of T
  ///   e[] = off-diagonal of T (e[0] = 0)
  ///   V[][] = orthogonal matrix Q (eigenvectors accumulated later)
  static void _tred2(List<List<double>> V, List<double> d,
      List<double> e, int n) {
    // Copy last row of V into d
    for (int j = 0; j < n; j++) {
      d[j] = V[n - 1][j];
    }

    // Householder reduction to tridiagonal form
    for (int i = n - 1; i > 0; i--) {
      // Scale to avoid under/overflow
      double scale = 0.0;
      double h = 0.0;
      for (int k = 0; k < i; k++) {
        scale += d[k].abs();
      }

      if (scale == 0.0) {
        e[i] = d[i - 1];
        for (int j = 0; j < i; j++) {
          d[j] = V[i - 1][j];
          V[i][j] = 0.0;
          V[j][i] = 0.0;
        }
      } else {
        // Generate Householder vector
        for (int k = 0; k < i; k++) {
          d[k] /= scale;
          h += d[k] * d[k];
        }
        double f = d[i - 1];
        double g = sqrt(h);
        if (f > 0) g = -g;
        e[i] = scale * g;
        h -= f * g;
        d[i - 1] = f - g;
        for (int j = 0; j < i; j++) {
          e[j] = 0.0;
        }

        // Apply Householder similarity transformation
        for (int j = 0; j < i; j++) {
          f = d[j];
          V[j][i] = f;
          g = e[j] + V[j][j] * f;
          for (int k = j + 1; k <= i - 1; k++) {
            g += V[k][j] * d[k];
            e[k] += V[k][j] * f;
          }
          e[j] = g;
        }
        f = 0.0;
        for (int j = 0; j < i; j++) {
          e[j] /= h;
          f += e[j] * d[j];
        }
        double hh = f / (h + h);
        for (int j = 0; j < i; j++) {
          e[j] -= hh * d[j];
        }
        for (int j = 0; j < i; j++) {
          f = d[j];
          g = e[j];
          for (int k = j; k <= i - 1; k++) {
            V[k][j] -= (f * e[k] + g * d[k]);
          }
          d[j] = V[i - 1][j];
          V[i][j] = 0.0;
        }
      }
      d[i] = h;
    }

    // Accumulate transformations
    for (int i = 0; i < n - 1; i++) {
      V[n - 1][i] = V[i][i];
      V[i][i] = 1.0;
      double h = d[i + 1];
      if (h != 0.0) {
        for (int k = 0; k <= i; k++) {
          d[k] = V[k][i + 1] / h;
        }
        for (int j = 0; j <= i; j++) {
          double g = 0.0;
          for (int k = 0; k <= i; k++) {
            g += V[k][i + 1] * V[k][j];
          }
          for (int k = 0; k <= i; k++) {
            V[k][j] -= g * d[k];
          }
        }
      }
      for (int k = 0; k <= i; k++) {
        V[k][i + 1] = 0.0;
      }
    }
    for (int j = 0; j < n; j++) {
      d[j] = V[n - 1][j];
      V[n - 1][j] = 0.0;
    }
    V[n - 1][n - 1] = 1.0;
    e[0] = 0.0;
  }

  /// QL iteration with implicit shifts for symmetric tridiagonal matrix.
  /// Based on EISPACK/JAMA tql2. On entry d[] and e[] hold the tridiagonal
  /// matrix, V[][] holds the accumulated Householder transforms. On exit
  /// d[] holds eigenvalues, V[][] holds eigenvectors.
  static void _tql2(List<List<double>> V, List<double> d,
      List<double> e, int n) {
    // Shift e so e[i] = off-diagonal element between d[i-1] and d[i]
    for (int i = 1; i < n; i++) {
      e[i - 1] = e[i];
    }
    e[n - 1] = 0.0;

    double f = 0.0;
    double tst1 = 0.0;
    const eps = 2.220446049250313e-16; // double machine epsilon

    for (int l = 0; l < n; l++) {
      // Find small sub-diagonal element
      tst1 = max(tst1, d[l].abs() + e[l].abs());
      int m = l;
      while (m < n) {
        if (e[m].abs() <= eps * tst1) break;
        m++;
      }

      // If m == l, d[l] is an eigenvalue; otherwise iterate
      if (m > l) {
        int iter = 0;
        do {
          iter++;
          if (iter > 300) break; // safety limit

          // Compute implicit shift
          double g = d[l];
          double p = (d[l + 1] - g) / (2.0 * e[l]);
          double r = _hypot(p, 1.0);
          if (p < 0) r = -r;

          d[l] = e[l] / (p + r);
          d[l + 1] = e[l] * (p + r);
          double dl1 = d[l + 1];
          double h = g - d[l];
          for (int i = l + 2; i < n; i++) {
            d[i] -= h;
          }
          f += h;

          // QL implicit shift
          p = d[m];
          double c = 1.0;
          double c2 = c;
          double c3 = c;
          double el1 = e[l + 1];
          double s = 0.0;
          double s2 = 0.0;
          for (int i = m - 1; i >= l; i--) {
            c3 = c2;
            c2 = c;
            s2 = s;
            g = c * e[i];
            h = c * p;
            r = _hypot(p, e[i]);
            e[i + 1] = s * r;
            s = e[i] / r;
            c = p / r;
            p = c * d[i] - s * g;
            d[i + 1] = h + s * (c * g + s * d[i]);

            // Accumulate transformation in eigenvector matrix
            for (int k = 0; k < n; k++) {
              h = V[k][i + 1];
              V[k][i + 1] = s * V[k][i] + c * h;
              V[k][i] = c * V[k][i] - s * h;
            }
          }
          p = -s * s2 * c3 * el1 * e[l] / dl1;
          e[l] = s * p;
          d[l] = c * p;
        } while (e[l].abs() > eps * tst1);
      }
      d[l] = d[l] + f;
      e[l] = 0.0;
    }
  }

  /// Stable hypot: sqrt(a^2 + b^2) without overflow.
  static double _hypot(double a, double b) {
    final aa = a.abs();
    final bb = b.abs();
    if (aa > bb) {
      final r = bb / aa;
      return aa * sqrt(1.0 + r * r);
    } else if (bb != 0) {
      final r = aa / bb;
      return bb * sqrt(1.0 + r * r);
    }
    return 0.0;
  }
}
