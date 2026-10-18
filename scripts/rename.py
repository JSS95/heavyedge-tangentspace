import argparse
import csv
import pathlib

import h5py


def load_names(profiles: pathlib.Path) -> dict[str, str]:
    if profiles.is_file():
        profiles = (
            pathlib.Path(__file__).resolve().parent.parent
            / "_data/v1/profiles/all_profiles"
            / profiles.stem
        )

    names = {}
    for path in sorted(profiles.glob("*.h5")):
        with h5py.File(path) as data:
            group_name = data.attrs["name"]
            names[group_name] = group_name
            for profile_name in data["names"].asstr()[:]:
                if profile_name in names and names[profile_name] != group_name:
                    raise ValueError(f"Duplicate profile name: {profile_name}")
                names[profile_name] = group_name

    if not names:
        raise ValueError(f"No profiles found in {profiles}")
    return names


parser = argparse.ArgumentParser()
parser.add_argument("input", type=pathlib.Path, help="Input CSV")
parser.add_argument(
    "profiles", type=pathlib.Path, help="Source profile directory or merged HDF5 file"
)
parser.add_argument("-o", "--output", type=pathlib.Path, required=True)
args = parser.parse_args()

names = load_names(args.profiles)

temporary_output = args.output.with_name(args.output.name + ".tmp")
try:
    with (
        args.input.open(newline="") as source,
        temporary_output.open("w", newline="") as target,
    ):
        reader = csv.reader(source)
        writer = csv.writer(target)
        header = next(reader)
        name_column = header.index("name")
        writer.writerow(header)
        for row in reader:
            row[name_column] = names[row[name_column]]
            writer.writerow(row)
    temporary_output.replace(args.output)
finally:
    temporary_output.unlink(missing_ok=True)
