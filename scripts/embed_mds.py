import argparse

import numpy as np
import pandas as pd
from scipy.spatial.distance import pdist, squareform
from sklearn.manifold import MDS

parser = argparse.ArgumentParser()
parser.add_argument("y", type=str, help="CSV file of features")
parser.add_argument("--n", type=int, default=50, help="Number of MDS components")
parser.add_argument("-o", type=str, required=True, help="Output CSV file")
args = parser.parse_args()

if args.n < 1:
    parser.error("--n must be at least 1")

# Read the header separately so pandas parses the wide feature matrix directly
# as float32. This keeps the ~N x D input matrix around 40 MB for N=1000,D=10000.
columns = pd.read_csv(args.y, nrows=0).columns
if "name" not in columns:
    raise ValueError(f"Feature CSV must contain a 'name' column: {args.y}")

feature_columns = [column for column in columns if column != "name"]
if not feature_columns:
    raise ValueError(f"Feature CSV contains no feature columns: {args.y}")

features = pd.read_csv(
    args.y,
    dtype={"name": str, **{column: np.float32 for column in feature_columns}},
)
names = features.pop("name")
X = features.to_numpy(dtype=np.float32, copy=False)
del features

if not np.isfinite(X).all():
    raise ValueError("Feature CSV contains NaN or infinite values")

# pdist computes distances without creating a temporary N x N x D array. MDS
# then works on the compact N x N distance matrix rather than the wide input.
distances = squareform(pdist(X, metric="euclidean"))
del X

embedding = MDS(
    n_components=args.n,
    dissimilarity="precomputed",
    random_state=42,
    n_init=1,
).fit_transform(distances)

output = pd.DataFrame(embedding, columns=range(args.n))
output.insert(0, "name", names)
output.to_csv(args.o, index=False)
