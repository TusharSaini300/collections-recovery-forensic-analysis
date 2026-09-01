# Golden Dataset / Pipeline

The CSVs in this folder are the current Golden outputs used by the analysis.
`build_golden.py` is the reproducible transformation starting from raw source tables.

Run from the submission root after placing raw data under `data/raw`:

`python 03_golden_dataset/build_golden.py`

The pipeline preserves source identifiers and timestamps, resolves collision-prone dimensions conservatively, removes only validated payment duplicates, reconstructs account status point-in-time, and records business-impact decisions.
