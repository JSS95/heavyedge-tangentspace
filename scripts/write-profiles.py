import argparse
import csv
import pathlib

from heavyedge import ProfileData

parser = argparse.ArgumentParser()
parser.add_argument(
    "input_dir", type=pathlib.Path, help="Directory containing mean profiles"
)
parser.add_argument(
    "-o", "--output", type=pathlib.Path, help="Output CSV file", required=True
)
args = parser.parse_args()

args.output.parent.mkdir(parents=True, exist_ok=True)

files = sorted(args.input_dir.glob("*.h5"))

with args.output.open("w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    wrote_header = False
    for f in files:
        with ProfileData(f) as data:
            Y, _, _ = data[:]
        for y in Y:
            if not wrote_header:
                writer.writerow(["name", *range(len(y))])
                wrote_header = True
            writer.writerow([f.stem, *y])
