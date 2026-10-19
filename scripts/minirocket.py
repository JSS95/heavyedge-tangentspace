import argparse
import csv
import pathlib

from aeon.transformations.collection.convolution_based import MiniRocket
from heavyedge import ProfileData

parser = argparse.ArgumentParser()
parser.add_argument("profiles", type=pathlib.Path, help="h5 file of profiles")
parser.add_argument(
    "-o", "--output", type=pathlib.Path, help="Output CSV file", required=True
)
args = parser.parse_args()


minirocket = MiniRocket()
fitted = False

with ProfileData(args.profiles) as data, args.output.open("w", newline="") as csvfile:
    writer = csv.writer(csvfile)

    for y, L, name in data:
        y = y[:L].reshape(1, -1)
        if not fitted:
            features = minirocket.fit_transform(y)
            writer.writerow(["name", *range(features.shape[1])])
            fitted = True
        else:
            features = minirocket.transform(y)
        writer.writerow([name, *features.flatten()])
