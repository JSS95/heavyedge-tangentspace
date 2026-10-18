.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASET_PROFILES := \
	$(patsubst _data/v1/profiles/all_profiles/%,data/profiles/all_profiles/%.csv,$(filter-out %.tar.gz,$(wildcard _data/v1/profiles/all_profiles/dataset*))) \
	$(patsubst _data/v1/profiles/mean_profiles/%,data/profiles/mean_profiles/%.csv,$(filter-out %.tar.gz,$(wildcard _data/v1/profiles/mean_profiles/dataset*)))

DATASET_DIMLESS := \
	$(patsubst _data/v1/process_variables/all_profiles/%.csv,data/dimless/all_profiles/%.csv,$(wildcard _data/v1/process_variables/all_profiles/*.csv)) \
	$(patsubst _data/v1/process_variables/mean_profiles/%.csv,data/dimless/mean_profiles/%.csv,$(wildcard _data/v1/process_variables/mean_profiles/*.csv))

DATASET_LABELS := $(patsubst _data/v1/labels/%/knees.csv,data/labels/mean_profiles/%.csv,$(wildcard _data/v1/labels/dataset*/knees.csv))

all: $(DATASET_PROFILES) $(DATASET_DIMLESS) $(DATASET_LABELS)

data/profiles/all_profiles/%.csv: scripts/write-profiles.py _data/v1/profiles/all_profiles/%
	mkdir -p $(@D)
	python3 $^ -o $@

data/profiles/mean_profiles/%.csv: scripts/write-profiles.py _data/v1/profiles/mean_profiles/%
	mkdir -p $(@D)
	python3 $^ -o $@

data/dimless/all_profiles/%.csv: scripts/write-dimless.py _data/v1/process_variables/all_profiles/%.csv _data/v1/datapackage.json
	mkdir -p $(@D)
	python3 $^ -o $@

data/dimless/mean_profiles/%.csv: scripts/write-dimless.py _data/v1/process_variables/mean_profiles/%.csv _data/v1/datapackage.json
	mkdir -p $(@D)
	python3 $^ -o $@

data/labels/mean_profiles/%.csv: scripts/write-labels.py _data/v1/labels/%/knees.csv _data/v1/labels/%/canonical.csv
	mkdir -p $(@D)
	python3 $^ -o $@

clean:
	rm -rf data
