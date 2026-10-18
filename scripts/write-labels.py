import argparse
import pathlib

import numpy as np
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("knees", type=pathlib.Path, help="Knee labels.")
parser.add_argument("canonical", type=pathlib.Path, help="Canonical labels.")
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output csv file")
args = parser.parse_args()


def combine_labels(knees, canonical):
    canonical = canonical.astype(bool)
    out = np.empty_like(knees, dtype=object)
    out[knees == 0] = "Type 0"
    out[(knees == 1) & canonical] = "Type 1a"
    out[(knees == 1) & (~canonical)] = "Type 1b"
    out[(knees == 2) & canonical] = "Type 2a"
    out[(knees == 2) & (~canonical)] = "Type 2b"
    out[(knees == 3) & canonical] = "Type 3a"
    out[(knees == 3) & (~canonical)] = "Type 3b"
    return out


knees_df = pd.read_csv(args.knees)
canonical_df = pd.read_csv(args.canonical)

name_col = next((col for col in knees_df.columns if col.lower() == "name"), None)
type_col = next((col for col in knees_df.columns if col.lower() == "type"), None)
canonical_name_col = next((col for col in canonical_df.columns if col.lower() == "name"), None)
canonical_type_col = next((col for col in canonical_df.columns if col.lower() == "type"), None)

if name_col is None or type_col is None or canonical_name_col is None or canonical_type_col is None:
    raise ValueError("Label files must contain both 'name' and 'Type' columns.")

name = knees_df[name_col].to_numpy()
knees = knees_df[type_col].to_numpy()
canonical = canonical_df[canonical_type_col].to_numpy()
labels = combine_labels(knees, canonical)

pd.DataFrame({"name": name, "type": labels}).to_csv(args.out, index=False)
