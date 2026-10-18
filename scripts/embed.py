import argparse

import pandas as pd
import umap

parser = argparse.ArgumentParser()
parser.add_argument("y", type=str, help="CSV file of features")
parser.add_argument("-o", type=str, required=True, help="Output CSV file")
args = parser.parse_args()

y = args.y
output = args.o

features = pd.read_csv(y).set_index("name")

embedding = umap.UMAP(n_components=2, random_state=42).fit_transform(
    features.to_numpy()
)

pd.DataFrame(embedding, index=features.index, columns=["UMAP 1", "UMAP 2"]).to_csv(
    output
)
