#!/bin/sh

set -e

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required but not installed." >&2
  exit 1
fi

profiles_gdrive_url="$(printenv 'PROFILES_V1_GDRIVE' || true)"
if [ -z "$profiles_gdrive_url" ]; then
  profiles_gdrive_url="${PROFILES_V1_0_0_GDRIVE:-${PROFILES_V1_GDRIVE:-}}"
fi
if [ -z "$profiles_gdrive_url" ]; then
  echo "One of PROFILES_V1_GDRIVE / PROFILES_V1_0_0_GDRIVE must be set." >&2
  exit 1
fi

archive_path="_data/heavyedge-profiles-v1.0.0.tar.gz"
mkdir -p "$(dirname "$archive_path")"
uvx --from 'gdown<6.0.0' gdown --fuzzy "$profiles_gdrive_url" -O "$archive_path"
if [ -f "$archive_path" ]; then
  tar -xf "$archive_path" -C _data
fi
