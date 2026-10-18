.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASET_LABELS := $(patsubst _data/v1/labels/%/knees.csv,data/labels/%.csv,$(wildcard _data/v1/labels/dataset*/knees.csv))

all: $(DATASET_LABELS)

# Build data/labels/dataset*.csv from the dataset-specific knee and canonical labels.
data/labels/%.csv: _data/v1/labels/%/knees.csv _data/v1/labels/%/canonical.csv scripts/write-labels.py
	mkdir -p $(@D)
	python3 scripts/write-labels.py $< $(word 2,$^) -o $@

clean:
	rm -rf data
