# Analysis Notebook

Open `collections_recovery_analysis.ipynb`.

The notebook is designed to run from the repository without access to the original raw-data folder. Its primary calculations use the files in `03_golden_dataset/`.

## Run

```bash
pip install -r requirements.txt
jupyter notebook 02_notebook/collections_recovery_analysis.ipynb
```

Or execute headlessly:

```bash
jupyter nbconvert --to notebook --execute 02_notebook/collections_recovery_analysis.ipynb --output executed.ipynb
```

## Reproducibility design

- Primary KPI calculations are recomputed from Golden tables.
- `evidence/` is used only for an end-of-notebook reconciliation check.
- August is excluded from trend conclusions because it is partial.
- Exact duplicate call rows are removed; non-identical repeated `call_id` values are retained and treated as source-ID recycling.
- No causal claim is made from observational channel/attempt exposure.
