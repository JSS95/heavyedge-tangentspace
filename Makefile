.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all clean

all: \
result/vectorized/all_profiles/gap_to_thickness_ratio.ipynb result/vectorized/all_profiles/capillary_number.ipynb result/vectorized/all_profiles/cosine_of_contact_angle.ipynb \
result/vectorized/mean_profiles/gap_to_thickness_ratio.ipynb result/vectorized/mean_profiles/capillary_number.ipynb result/vectorized/mean_profiles/cosine_of_contact_angle.ipynb

clean:
	rm -rf data _temp result

# Preprocess PROFILES

# e.g.) _temp/profiles/mean_profiles/dataset5.h5
define MERGE_PROFILES
_temp/profiles/$(1)/$(2).h5: $(shell ls _data/v1/profiles/$(1)/$(2)/*.h5)
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

# e.g.) _temp/profiles/all_profiles.h5 _temp/profiles/mean_profiles.h5
_temp/profiles/%.h5: _temp/profiles/%/dataset3.h5 _temp/profiles/%/dataset4.h5 _temp/profiles/%/dataset5.h5
	mkdir -p $(@D)
	tmp=$$(mktemp); trap 'rm -f "$$tmp"' EXIT; \
		heavyedge merge $^ -o "$$tmp" && \
		heavyedge fill --fill-value nan "$$tmp" -o $@

# e.g.) data/profiles/mean_profiles.h5
data/profiles/%.h5: _temp/profiles/%.h5
	mkdir -p $(@D)
	tmp=$$(mktemp); trap 'rm -f "$$tmp"' EXIT; \
		heavyedge pad $< -o "$$tmp" && \
		heavyedge scale "$$tmp" -o $@

# e.g.) _temp/profiles/mean_profiles.csv
_temp/profiles/%.csv: scripts/profiles.py data/profiles/%.h5
	mkdir -p $(@D)
	python3 $^ -o $@

data/profiles/mean_profiles.csv: _temp/profiles/mean_profiles.csv
	mkdir -p $(@D)
	cp $< $@

data/profiles/all_profiles.csv: scripts/rename.py _temp/profiles/all_profiles.csv data/profiles/all_profiles.h5
	mkdir -p $(@D)
	python3 $^ -o $@

# Preprocess DIMLESS

# e.g.) _temp/dimless/mean_profiles/dataset5.csv
define TO_DIMLESS
_temp/dimless/$(1)/$(2).csv: scripts/dimless.py _data/v1/process_variables/$(1)/$(2).csv _data/v1/datapackage.json
	mkdir -p $$(@D)
	python3 $$^ -o $$@
endef
$(foreach \
	target, \
	all_profiles mean_profiles, \
	$(foreach \
		dataset, \
		dataset1 dataset2 dataset3 dataset4 dataset5, \
		$(eval $(call TO_DIMLESS,$(target),$(dataset))) \
	) \
)

# e.g.) _temp/dimless/all_profiles.csv _temp/dimless/mean_profiles.csv
_temp/dimless/%.csv: _temp/dimless/%/dataset3.csv _temp/dimless/%/dataset4.csv _temp/dimless/%/dataset5.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd; pd.concat([pd.read_csv(f) for f in '$^'.split()]).to_csv('$@', index=False)"

data/dimless/mean_profiles.csv: _temp/dimless/mean_profiles.csv
	mkdir -p $(@D)
	cp $< $@

data/dimless/all_profiles.csv: scripts/rename.py _temp/dimless/all_profiles.csv data/profiles/all_profiles.h5
	mkdir -p $(@D)
	python3 $^ -o $@

# preprocess LABELS

_temp/labels/mean_profiles/%.csv: scripts/labels.py _data/v1/labels/%/knees.csv _data/v1/labels/%/canonical.csv
	mkdir -p $(@D)
	python3 $^ -o $@

data/labels/mean_profiles.csv: _temp/labels/mean_profiles/dataset3.csv _temp/labels/mean_profiles/dataset4.csv _temp/labels/mean_profiles/dataset5.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd; pd.concat([pd.read_csv(f) for f in '$^'.split()]).to_csv('$@', index=False)"

# Results

# e.g.) _temp/vectorized/mean_profiles/dataset5.csv
define VECTORIZE
_temp/vectorized/$(1)/$(2).csv: scripts/vectorize.py data/profiles/$(1)/$(2).h5
	mkdir -p $$(@D)
	python3 $$^ --sigma 0.16 -o $$@
endef
$(foreach \
	target, \
	all_profiles mean_profiles, \
	$(foreach \
		dataset, \
		dataset1 dataset2 dataset3 dataset4 dataset5, \
		$(eval $(call VECTORIZE,$(target),$(dataset))) \
	) \
)

# e.g.) _temp/vectorized/all_profiles.csv _temp/vectorized/mean_profiles.csv
_temp/vectorized/%.csv: _temp/vectorized/%/dataset3.csv _temp/vectorized/%/dataset4.csv _temp/vectorized/%/dataset5.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd; pd.concat([pd.read_csv(f) for f in '$^'.split()]).to_csv('$@', index=False)"

result/vectorized/mean_profiles.csv: _temp/vectorized/mean_profiles.csv
	mkdir -p $(@D)
	cp $< $@

result/vectorized/all_profiles.csv: scripts/rename.py _temp/vectorized/all_profiles.csv data/profiles/all_profiles.h5
	mkdir -p $(@D)
	python3 $^ -o $@

## embedding

result/umap/all_profiles.csv: scripts/embed.py result/vectorized/all_profiles.csv
	mkdir -p $(@D)
	python3 $^ -o $@

result/umap/mean_profiles.csv: scripts/embed.py result/vectorized/mean_profiles.csv
	mkdir -p $(@D)
	python3 $^ -o $@

result/vectorized/all_profiles/%.ipynb: notebooks/vectorized.ipynb data/dimless/all_profiles.csv result/umap/all_profiles.csv
	mkdir -p $(@D)
	papermill $< $@ -k python3 -l python -p X data/dimless/all_profiles.csv -p y result/umap/all_profiles.csv -p color $*

result/vectorized/mean_profiles/%.ipynb: notebooks/vectorized.ipynb data/dimless/mean_profiles.csv result/umap/mean_profiles.csv
	mkdir -p $(@D)
	papermill $< $@ -k python3 -l python -p X data/dimless/mean_profiles.csv -p y result/umap/mean_profiles.csv -p color $*
