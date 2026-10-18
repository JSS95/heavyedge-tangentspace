#!/bin/sh

set -e

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required but not installed." >&2
  exit 1
fi

# Download profile dataset
archive_path="_data/heavyedge-profiles-v1.0.0.tar.gz"
mkdir -p "$(dirname "$archive_path")"
uvx --from 'gdown<6.0.0' gdown --fuzzy "$PROFILES_V1_GDRIVE" -O "$archive_path"
if [ -f "$archive_path" ]; then
  tar -xf "$archive_path" -C _data
fi

# Download label data
archive_path="_data/v1/labels.tar"
mkdir -p "$(dirname "$archive_path")"
uvx --from 'gdown<6.0.0' gdown --fuzzy "$LABELS_V1_GDRIVE" -O "$archive_path"

# Extract profiles
for dataset in _data/v1/profiles/all_profiles/*.tar.gz; do
    stem=$(basename "$dataset" .tar.gz)
    dirname=_data/v1/profiles/all_profiles/"$stem"
    mkdir -p "$dirname"
    tar -xzf "$dataset" -C "$dirname"
done
for dataset in _data/v1/profiles/mean_profiles/*.tar.gz; do
    stem=$(basename "$dataset" .tar.gz)
    dirname=_data/v1/profiles/mean_profiles/"$stem"
    mkdir -p "$dirname"
    tar -xzf "$dataset" -C "$dirname"
done

# Extract labels
mkdir -p _data/v1/labels
tar -xf _data/v1/labels.tar -C _data/v1/labels
