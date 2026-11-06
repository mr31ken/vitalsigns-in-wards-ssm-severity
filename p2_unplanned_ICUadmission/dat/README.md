# Inputs and outputs (not included): unplanned ICU admission cohort and follow-up

Not distributable (personal health information).

## Read by `p2_unplanned_ICUadmission_fromJIPAD.Rmd`

The department's intensive care records as submitted to JIPAD, one Excel file per year, kept in
`../../dat/JIPAD/unlock/`: `2020＿JIPAD.xlsx`, `2021_JIPAD.xlsx`, `2022_JIPAD.xlsx` (ICU admissions
2020-04-01 to 2022-12-22). The 2022 file was updated on 2024-10-17, after the cohort file below was made;
re-running p2 with the current files gives the same 160 admissions, with later-completed values in four
columns (ICU discharge time filled in for 4 admissions, hospital discharge date changed for 1, discharge
outcome filled in for 1).

## Files used downstream

| File | Source | Read by | MD5 |
|---|---|---|---|
| `icu_target20240517_044716.297905.rds` | `p2_unplanned_ICUadmission_fromJIPAD.Rmd` (run 2024-05-17) | p5, p7 | `844d7d976f51de20b9c0733769ba6fe3` |
| `admit_col78_20241019_005911_315947.csv` | clinical data warehouse export: hospital admissions (last contact) | p7 evaluation (follow-up) | `e62f1e0cd4600e434cba6746a832265c` |
| `book_col57_20241019_005911_315947.csv` | clinical data warehouse export: attended outpatient appointments (last contact) | p7 evaluation (follow-up) | `ec6c2c804778beda90e6f07129176bd2` |
| `ptprof_col25_20241201_031325_735194.csv` | clinical data warehouse export: patient profile (date and time of death) | p7 evaluation (30-day death) | `ad21e5ed7c60f763edbb0f8dc9bcc9af` |
