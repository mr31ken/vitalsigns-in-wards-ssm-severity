# Latent severity from sparse ward vital signs (state–space model)

Analysis code for:

> Saito K, Fukuyama K, Mori Y, Ueshima H, Tsutsumi T, Takeda C, Kai S, Kuroda T.
> *Estimating the Effect of Respiratory Rate on Patient Condition Using a State–Space Model in a University Hospital Setting.*
> Submitted to the Journal of Anesthesia.

A Bayesian state–space model estimates a latent severity from irregularly recorded
general-ward vital signs (temperature, heart rate, respiratory rate, mean blood pressure)
in the 72 h before an unplanned ICU admission. The 24-h time-weighted mean severity is
related to 30-day mortality, and each vital sign's contribution is assessed by refitting
the model without it (leave-one-channel-out) and with it alone (single-channel).
The repository covers the whole chain, from the hospital's data exports to the reported
statistics; no data are included.

## Data

**No data are included.** The analysis used institutional intensive care records of
Kyoto University Hospital (the records the Department of Intensive Care Medicine submits
to JIPAD) and vital signs from the hospital's clinical data warehouse. They contain
personal health information and cannot be shared publicly; access requires approval by
the institution and its ethics committee (Kyoto University Graduate School of Medicine,
approval R3900). The input and intermediate files are listed, with MD5 checksums, in
`p1_*/dat/README.md`, `p2_*/dat/README.md` and `p5_*/dat/README.md`.

## Layout and run order

The folders mirror the original project layout, because every file reads its inputs by
relative path. Run each file with its own folder as the working directory. Output files carry
a time stamp in their names; each later step names its inputs explicitly (the files used for
the article are those listed in the `dat/README.md` files), so after a re-run the input paths
of the next step must be edited.

### Part A — cohort and input tables

| Step | File | Reads | Writes | Time* |
|---|---|---|---|---|
| A1 | `p1_whole_admtc_vit_fromCIS/p1_whole_admtc_vit_fromCIS.Rmd` — ward stays and vital signs, January 2020 – February 2023 | monthly data-warehouse exports in `../../dat/p1_pts_parse/` | `admtc_<ts>.rds`, `vit_<ts>.rds` | ~2 min |
| A2 | `p1_whole_admtc_vit_fromCIS/p1_02_whole_in_range.Rmd` — lists of excluded units and departments; tables without them | A1 | `setting_<ts>.rds`, `ir_admtc_…`, `ir_vit_…` | ~1 min |
| A3 | `p2_unplanned_ICUadmission/p2_unplanned_ICUadmission_fromJIPAD.Rmd` — the unplanned ICU admission cohort | ICU records (`../../dat/JIPAD/unlock/*.xlsx`); A1 `admtc`; A2 `setting` | `icu_target<ts>.rds` | ~1 min |
| A4 | `p5_vit_dist_inhosp/p5_build_df_j.R` — vital signs in the 48 h before ICU admission (aPS-4 comparison only) | A1 `vit`; A2; A3 | `df_j<ts>.rds` | <1 min |

The state–space model (Part B) builds its own 72-h measurement table from A1 `vit` and A3
(it also reads A2 files without using them); the 30-day outcome comes from three further data-warehouse exports listed
in `p2_*/dat/README.md`. The original server ran in UTC; set `TZ=UTC` when re-running A3 to
reproduce the stored date-time columns exactly.

### Part B — model, evaluation and reported statistics

| Step | File (`p7_vit_dist_state_models_comp/`) | Reads | Writes | Time* |
|---|---|---|---|---|
| 1a | `p7_vit_dist_state_models_v2_compe_fix20260929.Rmd` — full model and four leave-one-channel-out fits | p1, p2 inputs; `ssm_801_4_redvar_rs.stan` | `ssm_801_4_redvar_rs_ex{ZERO,BPM,PULSE,RESP,TEMPR}_<timestamp>_exres_list.rds` | ~6.4 h |
| 1b | `p7_vit_dist_state_models_v2_onlys_fix20260930.Rmd` — four single-channel fits | as 1a | `ssm_801_4_redvar_rs_on{BPM,PULSE,RESP,TEMPR}_<timestamp>_exres_list.rds` | ~2.8 h |
| 2a | `p7_vit_dist_state_models_v2_compe_eval_fix20260930.Rmd` — 24-h severity, logistic regression, AUC | 1a fits; p2 inputs | `eval_sources_model_fix20260930.rds` | minutes |
| 2b | `p7_vit_dist_state_models_v2_compe_on_eval_fix20261001.Rmd` — same for single-channel fits | 1a full fit, 1b fits; p2 inputs | `eval_sources_model_on_add_fix.rds` | minutes |
| 3 | `p7_final_numbers_v23.Rmd` — all reported statistics, Figs 3a/3b, ESM Figs 2/3, convergence diagnostics | 2a, 2b outputs; p2, p5 inputs | `figs_final_v23/` | minutes (+ fits for diagnostics) |
| 4 | `value_effort_mismatch_v23.py` — Fig. 4 | `figs_final_v23/final_numbers_v23.csv` | `figs_final_v23/` | seconds |
| 4 | `figESM_auc_bars_v23.R` — ESM Figs 2 and 3 as published (the step 3 drafts with the AUC labels kept clear of the reference line) | `figs_final_v23/final_numbers_v23.csv` | `figs_final_v23/` | seconds |

\* Part A: on a laptop (2026-11-07); Part B: wall time on the original server (4 chains in parallel).

1a and 1b are independent. 2a needs 1a; 2b needs both 1a and 1b (it also reads the full
model). The evaluation Rmds pick the fits by their position in `list.files()`, so the
working folder should contain only the fits of one run; the knitted output prints the
selected files (`fs`) at the top. The timestamps of the fits used for the manuscript
are `20260929_100700.473068` (ex) and `20260930_004943.381441` (on);
`p7_final_numbers_v23.Rmd` names these files explicitly and checks its AUCs against the
values printed by 2a and 2b.

Fig. 2 (`p7_vit_dist_state_models/`) is drawn by
`p7_vit_dist_state_models_v2_resvis.Rmd` from a separate fit of the same model made by
`p7_vit_dist_state_models_v2.Rmd`; it plots state-level posterior means and does not use
the 24-h aggregation.

Long fits can be run in the background, e.g.

```bash
nohup Rscript -e "rmarkdown::render('p7_vit_dist_state_models_v2_onlys_fix20260930.Rmd')" > knit.log 2>&1 &
```

## Definitions as implemented

- **Cohort** (A3; the department and unit lists are in A2): ICU admissions recorded
  2020-04-01 to 2022-12-22 (2,147); admission route *ward*, admission type *emergency* (planned
  admissions and admissions for ICU procedures excluded) and adult category (all aged ≥ 16):
  246 admissions, 210 patients. Excluded next: admissions of patients with a ward-stay record
  on the day of ICU admission but none on the day before, i.e. hospitalised that day (22;
  224 admissions, 192 patients remain); admissions of patients who, on the calendar day 24 h
  before ICU admission, were in an intensive or special-care unit (ICU, C/HCU, CCU, ESICU, SCU,
  NICU, GCU; 9; 215, 184 remain) or under one of the departments of cardiology, cardiovascular
  surgery, respiratory medicine, respiratory surgery, emergency medicine, paediatrics,
  paediatric surgery, neonatology or neurosurgery (55). Analysed: 160 admissions, 136 patients.
- **Normalization** (`p7_vit_dist_state_models_v2_compe_fix20260929.Rmd`, lines 131–146 and 219–223): |value − midpoint of the reference range| ÷ half-width of the range (temperature 36.0–38.4 °C, heart rate and mean blood pressure 70–109, respiratory rate 12–24 /min).
- **Model** (`ssm_801_4_redvar_rs.stan`): one latent severity per admission × measurement time; a random walk whose step SD is proportional to √(elapsed days); each normalized value ~ Normal(a<sub>k</sub> × severity, σ), with channel coefficients a<sub>k</sub> averaging 1. Sampling: 4 chains × 5,000 iterations (3,000 warm-up), adapt_delta 0.90, max_treedepth 15, seed 12345.
- **Exposure** (`..._compe_eval_fix20260930.Rmd`, lines 353–368): in the 24 h before ICU admission, the posterior-mean severity of each record is weighted by the time to the next measurement (the last by the time to ICU admission) and averaged per admission.
- **Outcome**: death within 30 days of ICU admission.
- **Statistics** (`p7_final_numbers_v23.Rmd`): AUC from the fitted probabilities of a univariable logistic regression (ROCR), DeLong 95 % CI (pROC); odds ratio per 1 SD with patient-level cluster-robust standard errors (sandwich); patient-level cluster bootstrap (2,000 resamples, seed 42); first-admission-only analysis; comparison with an abbreviated APACHE II physiology score from the same four vital signs (aPS-4, last value within 3 h and 12 h, missing = 0; mean blood pressure only from records with both systolic and diastolic pressure, as in the model), DeLong test.

## Software

R 4.3.3, rstan 2.32.6 (StanHeaders 2.32.10, Stan 2.32.2), tidyverse 2.0.0, ROCR 1.0-11,
lme4 1.1-35.1 (as recorded in the knitted outputs of steps 1–2); pROC 1.18.4, sandwich 3.1-1
and ggplot2 3.4.4 for step 3; Python 3 with matplotlib for step 4. Part A also uses data.table, lubridate, openxlsx and table1
(several other packages are loaded by `require()` but not needed). Steps 1–3 were run on
RStudio Server 2023.09.0+463 / JupyterLab 4.3.5 (Ubuntu 22.04).

The numbers in the article come from the step 3 run of 2026-11-07, whose inputs were
`eval_sources_model_fix20260930.rds` (MD5 8a6228457debe503fe01188de6fa76c9),
`eval_sources_model_on_add_fix.rds` (MD5 8d3f50252de1f91407bd8144015ccc66) and
`df_j20261106_183454.947914.rds` (MD5 ef0c6009f28ae8730afb3e9e2b991b0d). An earlier run
(2026-11-06) used the first version of `df_j` (see `p5_build_df_j.R`); the 2026-11-07 run
reproduced all of its numbers exactly except those for aPS-4. The convergence diagnostics are
from the 2026-11-06 run (the 2026-11-07 run skipped that section): all nine fits had
R-hat ≤ 1.003 and n_eff ≥ 1,100 for every parameter, with no divergent transitions.

Part A was checked on 2026-11-07 by re-running it on a copy of the stored inputs: A1 and A2
reproduced `admtc`, `vit`, `setting` and `ir_admtc` exactly; A3 selected the same 160
admissions as `icu_target20240517_044716.297905.rds` (with the current ICU records, four
later-completed columns differ; see `p2_*/dat/README.md`); A4, with the mean
blood pressure step of the first version (see its header), reproduced `df_j20240524_052253.rds`
(all values equal); as published, it writes the file used in the article, which differs only
by the absence of the 31 rows from records with one blood pressure side missing.

**Changes to the authors' files.** `p1_whole_admtc_vit_fromCIS.Rmd`: paths on the
institutional file server replaced by the equivalent relative path `../../dat/`.
`p1_02_whole_in_range.Rmd`: as knitted on 2024-03-29; a chunk added later (mean blood
pressure in `ir_vit`, not used by any step, and not runnable as written) is omitted.
`p2_unplanned_ICUadmission_fromJIPAD.Rmd`: unchanged. `p5_build_df_j.R`: extracted from a
working notebook (see its header). The Part B files are unchanged. Exploratory parts of the
working notebooks, including checks on individual patients, are not published.

## License and citation

Code: MIT License (see `LICENSE`). Please cite the article above and this repository
(`CITATION.cff`).
