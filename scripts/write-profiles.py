import argparse
import csv
import pathlib

from heavyedge import ProfileData

parser = argparse.ArgumentParser()
parser.add_argument("profiles", type=pathlib.Path, help="h5 file of profiles")
parser.add_argument(
    "-o", "--output", type=pathlib.Path, help="Output CSV file", required=True
)
args = parser.parse_args()

with ProfileData(args.profiles) as data:
    _, L = data.shape()
    with args.output.open("w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["name", *range(L)])
        for Y, _, name in data:
            writer.writerow([name, *Y])
