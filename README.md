# Vietnam Trade Forecasting (R)

Data-science research project in R for **DSR301m** at FPT University: cleaning Vietnam's monthly export / import statistics by partner country (2022–2024), exploring trade patterns, and forecasting monthly trade values with **Prophet**.

## Workflow

1. **Data cleaning** — the raw customs spreadsheets have two-row, merged-cell headers. `01_data_cleaning_and_eda.R` detects the month columns automatically, rebuilds clean column names (`January_Quantity`, `January_Value`, …), and merges the monthly files of 2022–2024 into one table per flow with a `Year` column.
2. **Exploratory analysis** — export and import markets for 2024 split into large (> 10 M USD) and small partners, yearly export / import totals, trade balance of the top-10 partners per year, a partner × month heatmap, and stacked-area charts by product.
3. **Forecasting** — `02_prophet_forecasting.R` reshapes a partner's monthly values to a time series, fits Prophet on 2022–2024, forecasts the next 12 months, plots trend and seasonality components, and compares the forecast with the actual 2025 figures.

## Project structure

```
├── scripts/
│   ├── 01_data_cleaning_and_eda.R   # header reconstruction, merging, EDA charts
│   └── 02_prophet_forecasting.R     # Prophet models and 2025 comparison
├── data/
│   ├── export_2022_2024_merged.csv  # monthly export quantity & value by partner
│   └── import_2022_2024_merged.csv  # monthly import quantity & value by partner
└── slides/
    └── DSR_Model.pptx               # project presentation
```

## Requirements

R with `readxl`, `readr`, `dplyr`, `tidyr`, `stringr`, `ggplot2`, `scales`, `lubridate`, `prophet`.

The scripts read and write files with absolute paths (`D:/Download/Data for subject/...`); point them to the `data/` folder before running.

---
Author: Nguyen Quoc Anh — FPT University
