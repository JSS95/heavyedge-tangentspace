.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASET_DIMLESS := \
	$(patsubst _data/v1/process_variables/all_profiles/%.csv,data/dimless/all_profiles/%.csv,$(wildcard _data/v1/process_variables/all_profiles/*.csv)) \
	$(patsubst _data/v1/process_variables/mean_profiles/%.csv,data/dimless/mean_profiles/%.csv,$(wildcard _data/v1/process_variables/mean_profiles/*.csv))
DATASET_LABELS := $(patsubst _data/v1/labels/%/knees.csv,data/labels/mean_profiles/%.csv,$(wildcard _data/v1/labels/dataset*/knees.csv))

all: $(DATASET_DIMLESS) $(DATASET_LABELS)

data/dimless/all_profiles/%.csv: _data/v1/process_variables/all_profiles/%.csv _data/v1/datapackage.json scripts/write-dimless.py
	mkdir -p $(@D)
	python3 scripts/write-dimless.py $< _data/v1/datapackage.json -o $@

data/dimless/mean_profiles/%.csv: _data/v1/process_variables/mean_profiles/%.csv _data/v1/datapackage.json scripts/write-dimless.py
	mkdir -p $(@D)
	python3 scripts/write-dimless.py $< _data/v1/datapackage.json -o $@

data/labels/mean_profiles/%.csv: scripts/write-labels.py _data/v1/labels/%/knees.csv _data/v1/labels/%/canonical.csv
	mkdir -p $(@D)
	python3 $^ -o $@

clean:
	rm -rf data
