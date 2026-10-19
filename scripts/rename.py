import argparse
import csv
import pathlib

import h5py


def load_names(profiles: pathlib.Path) -> dict[str, str]:
    names = {}
    for path in sorted(profiles.rglob("*.h5")):
        with h5py.File(path) as data:
            group_name = data.attrs["name"]
            for profile_name in data["names"].asstr()[:]:
                if profile_name in names:
                    raise ValueError(f"Duplicate profile name: {profile_name}")
                names[profile_name] = group_name

    if not names:
        raise ValueError(f"No profiles found in {profiles}")
    return names


parser = argparse.ArgumentParser()
parser.add_argument("input", type=pathlib.Path, help="Input CSV")
parser.add_argument(
    "profiles",
    type=pathlib.Path,
    help="Merged all_profiles HDF5 file or source directory",
)
parser.add_argument("-o", "--output", type=pathlib.Path, required=True)
args = parser.parse_args()

project_root = pathlib.Path(__file__).resolve().parent.parent
dataset = args.profiles.stem if args.profiles.is_file() else args.profiles.name
source_profiles = project_root / "_data/v1/profiles/all_profiles" / dataset
merged_profiles = project_root / "data/profiles/all_profiles" / f"{dataset}.h5"
if args.profiles.is_dir():
    source_profiles = args.profiles
else:
    merged_profiles = args.profiles
    if dataset == "all_profiles":
        source_profiles = project_root / "_data/v1/profiles/all_profiles"

groups = load_names(source_profiles)
with h5py.File(merged_profiles) as data:
    profile_names = data["names"].asstr()[:]

output_names = []
seen = set()
for profile_name in profile_names:
    profile_id, marker, _ = profile_name.partition("_HEAD_")
    if not marker:
        raise ValueError(f"Profile name has no _HEAD_ suffix: {profile_name}")
    group_name = groups[profile_name]
    full_name = f"{group_name}/{profile_id}"
    if full_name in seen:
        raise ValueError(f"Duplicate output name: {full_name}")
    seen.add(full_name)
    output_names.append(full_name)

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
        row_count = 0
        for index, row in enumerate(reader):
            if index >= len(profile_names):
                raise ValueError(f"More CSV rows than profiles in {merged_profiles}")
            original_name = row[name_column]
            profile_name = profile_names[index]
            group_name = groups[profile_name]
            if original_name not in (profile_name, group_name, output_names[index]):
                raise ValueError(
                    f"Row {index + 1} name does not match {profile_name}: {original_name}"
                )
            row[name_column] = output_names[index]
            writer.writerow(row)
            row_count += 1
        if row_count != len(profile_names):
            raise ValueError(f"CSV row count does not match {merged_profiles}")
    temporary_output.replace(args.output)
finally:
    temporary_output.unlink(missing_ok=True)
