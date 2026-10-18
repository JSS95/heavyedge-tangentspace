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

VECTORIZED_CSV := \
	$(patsubst data/profiles/all_profiles/%.h5,data/vectorized/all_profiles/%.csv,$(PROFILES_HDF5)) \
	$(patsubst data/profiles/mean_profiles/%.h5,data/vectorized/mean_profiles/%.csv,$(PROFILES_HDF5))

all: \
$(PROFILES_HDF5) $(PROFILES_CSV) $(DIMLESS_CSV) $(LABELS_CSV) $(VECTORIZED_CSV) \
result/vectorized/all_profiles.csv result/vectorized/mean_profiles.csv

# Preprocessed data

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

_temp/profiles/all_profiles/%.csv: scripts/profiles.py data/profiles/all_profiles/%.h5
	mkdir -p $(@D)
	python3 $^ -o $@

data/profiles/all_profiles/%.csv: scripts/rename.py _temp/profiles/all_profiles/%.csv data/profiles/all_profiles/%.h5
	mkdir -p $(@D)
	python3 $^ -o $@

data/profiles/mean_profiles/%.csv: scripts/profiles.py data/profiles/mean_profiles/%.h5
	mkdir -p $(@D)
	python3 $^ -o $@

_temp/dimless/all_profiles/%.csv: scripts/dimless.py _data/v1/process_variables/all_profiles/%.csv _data/v1/datapackage.json
	mkdir -p $(@D)
	python3 $^ -o $@

data/dimless/all_profiles/%.csv: scripts/rename.py _temp/dimless/all_profiles/%.csv data/profiles/all_profiles/%.h5
	mkdir -p $(@D)
	python3 $^ -o $@

data/dimless/mean_profiles/%.csv: scripts/dimless.py _data/v1/process_variables/mean_profiles/%.csv _data/v1/datapackage.json
	mkdir -p $(@D)
	python3 $^ -o $@

data/labels/mean_profiles/%.csv: scripts/labels.py _data/v1/labels/%/knees.csv _data/v1/labels/%/canonical.csv
	mkdir -p $(@D)
	python3 $^ -o $@

_temp/vectorized/all_profiles/%.csv: scripts/vectorize.py data/profiles/all_profiles/%.h5
	mkdir -p $(@D)
	python3 $^ --sigma 0.16 -o $@

data/vectorized/all_profiles/%.csv: scripts/rename.py _temp/vectorized/all_profiles/%.csv data/profiles/all_profiles/%.h5
	mkdir -p $(@D)
	python3 $^ -o $@

data/vectorized/mean_profiles/%.csv: scripts/vectorize.py data/profiles/mean_profiles/%.h5
	mkdir -p $(@D)
	python3 $^ --sigma 0.16 -o $@

# Results

result/dimless/all_profiles.csv: data/dimless/all_profiles/dataset3.csv data/dimless/all_profiles/dataset4.csv data/dimless/all_profiles/dataset5.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd; pd.concat([pd.read_csv(f) for f in '$^'.split()]).to_csv('$@', index=False)"

result/dimless/mean_profiles.csv: data/dimless/mean_profiles/dataset3.csv data/dimless/mean_profiles/dataset4.csv data/dimless/mean_profiles/dataset5.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd; pd.concat([pd.read_csv(f) for f in '$^'.split()]).to_csv('$@', index=False)"

result/vectorized/all_profiles.csv: data/vectorized/all_profiles/dataset3.csv data/vectorized/all_profiles/dataset4.csv data/vectorized/all_profiles/dataset5.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd; pd.concat([pd.read_csv(f) for f in '$^'.split()]).to_csv('$@', index=False)"

result/vectorized/mean_profiles.csv: data/vectorized/mean_profiles/dataset3.csv data/vectorized/mean_profiles/dataset4.csv data/vectorized/mean_profiles/dataset5.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd; pd.concat([pd.read_csv(f) for f in '$^'.split()]).to_csv('$@', index=False)"

result/vectorized/all_profiles.ipynb: notebooks/vectorized.ipynb result/dimless/all_profiles.csv result/vectorized/all_profiles.csv
	mkdir -p $(@D)
	papermill $< $@ -p X result/dimless/all_profiles.csv -p y result/vectorized/all_profiles.csv

result/vectorized/mean_profiles.ipynb: notebooks/vectorized.ipynb result/dimless/mean_profiles.csv result/vectorized/mean_profiles.csv
	mkdir -p $(@D)
	papermill $< $@ -p X result/dimless/mean_profiles.csv -p y result/vectorized/mean_profiles.csv

clean:
	rm -rf data _temp result
