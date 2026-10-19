import argparse
import csv
import pathlib

import numpy as np
from aeon.transformations.collection.convolution_based import MiniRocket
from heavyedge import ProfileData

parser = argparse.ArgumentParser()
parser.add_argument("profiles", type=pathlib.Path, help="h5 file of profiles")
parser.add_argument(
    "-o", "--output", type=pathlib.Path, help="Output CSV file", required=True
)
args = parser.parse_args()


with ProfileData(args.profiles) as data:
    profiles = [(np.asarray(y[:L], dtype=np.float32), name) for y, L, name in data]

if not profiles:
    raise ValueError(f"No profiles found in {args.profiles}")

X = np.stack([profile for profile, _ in profiles])
names = [name for _, name in profiles]
del profiles

features = MiniRocket(random_state=42).fit_transform(X)

with args.output.open("w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["name", *range(features.shape[1])])
    for name, row in zip(names, features):
        writer.writerow([name, *row])
