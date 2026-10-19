import argparse
import csv
import pathlib

import numpy as np
from heavyedge import ProfileData
from scipy.ndimage import gaussian_filter1d

parser = argparse.ArgumentParser()
parser.add_argument("profiles", type=pathlib.Path, help="h5 file of profiles")
parser.add_argument("--sigma", type=float, help="Sigma value for smoothing")
parser.add_argument(
    "-o", "--output", type=pathlib.Path, help="Output CSV file", required=True
)
args = parser.parse_args()


def vectorize(Y, sigma):
    smooth_Y = gaussian_filter1d(Y, sigma, order=0)
    smooth_tan = gaussian_filter1d(Y, sigma, order=1)

    func_space = [part.mean() for part in np.array_split(smooth_Y, 10)]
    tan_space = [part.mean() for part in np.array_split(smooth_tan, 10)]

    func_space = np.array(func_space) / np.linalg.norm(func_space)
    tan_space = np.array(tan_space) / np.linalg.norm(tan_space)
    return np.concatenate([func_space, tan_space])


with ProfileData(args.profiles) as data:
    x = data.x()
    dx = x[1] - x[0]
    with args.output.open("w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["name", *range(20)])
        for Y, L, name in data:
            y = Y / np.trapezoid(Y[:L], x[:L])
            v = vectorize(y[:L], args.sigma / dx)
            writer.writerow([name, *v])
