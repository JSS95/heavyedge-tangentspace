import argparse
import json
import pathlib

import numpy as np
import pandas as pd
import pint

parser = argparse.ArgumentParser()
parser.add_argument("pv", type=pathlib.Path, help="Process variable csv file")
parser.add_argument("metadata", type=pathlib.Path, help="Datapackage json file.")
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output csv file")
args = parser.parse_args()


def read_pv(pv_csv_path, datapackage_json_path):
    with open(datapackage_json_path) as file:
        datapackage = json.load(file)

    resource = next(
        (
            item
            for item in datapackage["resources"]
            if item["name"] == "Process variables"
        ),
        None,
    )
    if resource is None:
        raise ValueError(f"No resource found in {datapackage_json_path}")

    field_units = {
        field["name"]: field["unit"]
        for field in resource["schema"]["fields"]
        if "unit" in field
    }

    df = pd.read_csv(pv_csv_path, dtype={"name": str, "slurry": str})
    ureg = pint.UnitRegistry()
    for field, unit_name in field_units.items():
        if field not in df.columns:
            raise ValueError(f"PV CSV is missing unit-bearing field: {field}")
        unit = ureg.Unit(unit_name)
        df[field] = df[field].map(lambda value, unit=unit: value * unit)

    return df


df = read_pv(args.pv, args.metadata)


wet_thickness = df["flow_rate_per_width"] / df["coating_speed"]
Rgt = (df["coating_gap"] / wet_thickness).apply(lambda x: x.to_reduced_units())
Ca = (df["viscosity"] * df["coating_speed"] / df["surface_tension"]).apply(
    lambda x: x.to_reduced_units()
)
cos_theta = df["contact_angle"].apply(lambda x: np.cos(x.to("radian").magnitude))
feed_slot_height_ratio = (df["shim_thickness"] / df["coating_gap"]).apply(
    lambda x: x.to_reduced_units().magnitude
)
downstream_lip_length_ratio = (df["downstream_lip_length"] / df["coating_gap"]).apply(
    lambda x: x.to_reduced_units().magnitude
)
upstream_lip_length_ratio = (df["upstream_lip_length"] / df["coating_gap"]).apply(
    lambda x: x.to_reduced_units().magnitude
)


dimless = pd.DataFrame(
    {
        "name": df["name"].apply(lambda x: f"{args.out.stem}/{x}"),
        "slurry": df["slurry"],
        "gap_to_thickness_ratio": Rgt.apply(lambda x: x.magnitude),
        "capillary_number": Ca.apply(lambda x: x.magnitude),
        "cosine_of_contact_angle": cos_theta,
        "feed_slot_height_ratio": feed_slot_height_ratio,
        "downstream_lip_length_ratio": downstream_lip_length_ratio,
        "upstream_lip_length_ratio": upstream_lip_length_ratio,
    }
)


if args.out is not None:
    dimless.to_csv(args.out, index=False)
