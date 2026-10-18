.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

PROFILES_HDF5 := \
	$(patsubst _data/v1/profiles/all_profiles/%,data/profiles/all_profiles/%.h5,$(filter-out %.tar.gz,$(wildcard _data/v1/profiles/all_profiles/dataset*))) \
	$(patsubst _data/v1/profiles/mean_profiles/%,data/profiles/mean_profiles/%.h5,$(filter-out %.tar.gz,$(wildcard _data/v1/profiles/mean_profiles/dataset*)))

PROFILES_CSV := \
	$(patsubst _data/v1/profiles/all_profiles/%,data/profiles/all_profiles/%.csv,$(filter-out %.tar.gz,$(wildcard _data/v1/profiles/all_profiles/dataset*))) \
	$(patsubst _data/v1/profiles/mean_profiles/%,data/profiles/mean_profiles/%.csv,$(filter-out %.tar.gz,$(wildcard _data/v1/profiles/mean_profiles/dataset*)))

DIMLESS_CSV := \
	$(patsubst _data/v1/process_variables/all_profiles/%.csv,data/dimless/all_profiles/%.csv,$(wildcard _data/v1/process_variables/all_profiles/*.csv)) \
	$(patsubst _data/v1/process_variables/mean_profiles/%.csv,data/dimless/mean_profiles/%.csv,$(wildcard _data/v1/process_variables/mean_profiles/*.csv))

LABELS_CSV := $(patsubst _data/v1/labels/%/knees.csv,data/labels/mean_profiles/%.csv,$(wildcard _data/v1/labels/dataset*/knees.csv))

all: $(PROFILES_HDF5) $(PROFILES_CSV) $(DIMLESS_CSV) $(LABELS_CSV)

define MERGE_PROFILES
data/profiles/$(1)/$(2).h5: $(shell ls _data/v1/profiles/$(1)/$(2)/*.h5)
	mkdir -p $$(@D)
	heavyedge merge $$^ -o $$@
endef
$(foreach \
	target, \
	all_profiles mean_profiles, \
	$(foreach \
		dataset, \
		dataset1 dataset2 dataset3 dataset4 dataset5, \
		$(eval $(call MERGE_PROFILES,$(target),$(dataset))) \
	) \
)

data/profiles/all_profiles/%.csv: scripts/write-profiles.py data/profiles/all_profiles/%.h5
	mkdir -p $(@D)
	python3 $^ -o $@

data/profiles/mean_profiles/%.csv: scripts/write-profiles.py data/profiles/mean_profiles/%.h5
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
