# Tangent Space Analysis of Heavy Edge Profiles

## Setup

Requires `uv` and `make`.

```sh
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
export PROFILES_V1_GDRIVE="<Google drive link>"
export LABELS_V1_GDRIVE="<Google drive link>"
./setup.sh
```

## Build

To build:

```sh
make
```

To clean:

```sh
make clean
```

## Developing

### Jupyter notebooks

To contribute to notebooks, additionally install `nbstripout`:

```sh
uv pip install jupyter ipykernel nbstripout
```

Then enable the Git filter.
This needs to be done only once after cloning:

```sh
nbstripout --install --attributes .gitattributes
git config --local filter.nbstripout.extrakeys 'metadata.kernelspec metadata.language_info cell.metadata.tags'
```

### Lint

```sh
ruff format .
ruff check --fix .
```
