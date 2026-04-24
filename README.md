# PCA Flutter

## Description

Interactive Principal Component Analysis operator for Tercen, implemented in Flutter. Replaces the ShinyR implementation at [pca_shiny](https://github.com/tercen/pca_shiny).

## Usage

Input projection|.
---|---
`y-axis`        | numeric measurement values
`row`           | variables (features/spots) — one row per variable
`column`        | observations (samples) — one column per sample
`colors`        | (optional) categorical factor used as the default *Color By* in the viewer

The input is interpreted as an observations × variables matrix: each column becomes a point projected onto the principal components, and each row becomes a loading vector.

Output relations|.
---|---
`PC1..PCn`      | score for each observation on each principal component
`X1..Xn`        | loading for each variable on each principal component
`Operator view` | interactive 3D scores, biplot, pairs, and scree plots

Scores and loadings are returned together as a single flat cross-tab (one row per observation × variable pair), matching the output format of `pca_shiny`.

## Factors (operator properties)

These are set on the operator before the app opens. They control the computation itself — the viewer controls only change what's displayed.

Factor|Default|Description
---|---|---
`Scale Spots`          | `No` | If `Yes`, each variable is standardised (zero mean, unit variance) before PCA. Use when variables are on different scales. If `No`, PCA runs on centered-only data (covariance PCA).
`Number of Components` | `5`  | Maximum number of principal components to compute and return. Capped at `min(nObs − 1, nVars)`.
`Subtract component`   | `0`  | If non-zero, the specified component is subtracted from the data before PCA is re-run. Useful for isolating structure orthogonal to a dominant signal (e.g. removing a batch effect captured by PC1). `0` disables this step.

## Details

PCA is computed once at app startup using the factors above. All interactive controls in the viewer (view mode, color-by, label-by, 3D axis selection, biplot thresholds, number of components to display) affect only rendering — they do not change the underlying computation. To change the computation, update the operator properties and re-run the step.

The implementation uses the dual PCA / Gram-matrix formulation (Householder tridiagonalisation + QL iteration for the eigendecomposition), which is efficient for the common Tercen case of many variables and relatively few observations.

## See Also

[pca_shiny](https://github.com/tercen/pca_shiny) — original ShinyR implementation
