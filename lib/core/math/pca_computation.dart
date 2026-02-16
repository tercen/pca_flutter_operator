import 'dart:math';

/// Result of PCA computation
class PcaResult {
  /// Scores matrix: n_obs x n_comp (observations projected onto PCs)
  final List<List<double>> scores;

  /// Loadings matrix: n_vars x n_comp (variable contributions to PCs)
  final List<List<double>> loadings;

  /// Eigenvalues (variance captured by each PC, before normalization)
  final List<double> eigenvalues;

  /// Percentage of total variance explained by each PC (0-100)
  final List<double> variancePercent;

  /// Number of components returned
  final int nComponents;

  PcaResult({
    required this.scores,
    required this.loadings,
    required this.eigenvalues,
    required this.variancePercent,
    required this.nComponents,
  });
}

/// PCA computation using the dual method (n_obs x n_obs Gram matrix).
/// Optimal when n_obs << n_vars (typical: 10-500 obs, 100-20000 vars).
///
/// Algorithm:
/// 1. Center (and optionally scale) the data matrix X (n_obs x n_vars)
/// 2. Compute Gram matrix G = X * X^T / (n_obs - 1)  [n_obs x n_obs]
/// 3. Eigendecompose G using Jacobi algorithm
/// 4. Recover scores and loadings from eigenvectors
class PcaComputation {
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
    final (eigenvalues, eigenvectors) = _jacobiEigen(G, nObs);

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

    return PcaResult(
      scores: scores,
      loadings: loadings,
      eigenvalues: eigenvalues.sublist(0, nc),
      variancePercent: variancePercent,
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

  /// Jacobi eigenvalue algorithm for real symmetric matrices.
  /// Returns (eigenvalues sorted descending, eigenvectors as columns of V).
  /// V[i][k] is the i-th component of the k-th eigenvector.
  static (List<double>, List<List<double>>) _jacobiEigen(
      List<List<double>> A, int n) {
    // Work on a copy
    final S = List.generate(n, (i) => List<double>.from(A[i]));
    // Eigenvectors start as identity
    final V = List.generate(n, (i) =>
        List.generate(n, (j) => i == j ? 1.0 : 0.0));

    const maxSweeps = 100;
    const tolerance = 1e-12;

    for (int sweep = 0; sweep < maxSweeps; sweep++) {
      // Sum of squares of off-diagonal elements
      double offDiag = 0;
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          offDiag += S[i][j] * S[i][j];
        }
      }
      if (offDiag < tolerance) break;

      for (int p = 0; p < n - 1; p++) {
        for (int q = p + 1; q < n; q++) {
          if (S[p][q].abs() < tolerance * 0.001) continue;

          // Compute rotation angle
          final diff = S[p][p] - S[q][q];
          double t;
          if (diff.abs() < 1e-15) {
            t = 1.0;
          } else {
            final phi = diff / (2.0 * S[p][q]);
            t = 1.0 / (phi.abs() + sqrt(phi * phi + 1.0));
            if (phi < 0) t = -t;
          }

          final c = 1.0 / sqrt(t * t + 1.0);
          final s = t * c;
          final tau = s / (1.0 + c);

          final spq = S[p][q];
          S[p][q] = 0.0;
          S[p][p] -= t * spq;
          S[q][q] += t * spq;

          // Rotate rows and columns of S
          for (int r = 0; r < p; r++) {
            _rotate(S, r, p, r, q, s, tau);
          }
          for (int r = p + 1; r < q; r++) {
            _rotate(S, p, r, r, q, s, tau);
          }
          for (int r = q + 1; r < n; r++) {
            _rotate(S, p, r, q, r, s, tau);
          }

          // Rotate eigenvector matrix V
          for (int r = 0; r < n; r++) {
            final vp = V[r][p];
            final vq = V[r][q];
            V[r][p] = vp - s * (vq + tau * vp);
            V[r][q] = vq + s * (vp - tau * vq);
          }
        }
      }
    }

    // Extract eigenvalues
    final eigenvalues = List.generate(n, (i) => S[i][i]);

    // Sort descending
    final indices = List.generate(n, (i) => i);
    indices.sort((a, b) => eigenvalues[b].compareTo(eigenvalues[a]));

    final sortedEigenvalues = indices.map((i) => eigenvalues[i]).toList();
    final sortedV = List.generate(n, (row) =>
        indices.map((i) => V[row][i]).toList());

    return (sortedEigenvalues, sortedV);
  }

  /// Apply Givens rotation to symmetric matrix element pair.
  static void _rotate(List<List<double>> S,
      int i1, int j1, int i2, int j2, double s, double tau) {
    final g = S[i1][j1];
    final h = S[i2][j2];
    S[i1][j1] = g - s * (h + tau * g);
    S[i2][j2] = h + s * (g - tau * h);
  }
}
