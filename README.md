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

## Data

**No data are included.** The analysis used institutional intensive care records of
Kyoto University Hospital (the records the Department of Intensive Care Medicine submits
to JIPAD) and vital signs from the hospital's clinical data warehouse. They contain
personal health information and cannot be shared publicly; access requires approval by
the institution and its ethics committee (Kyoto University Graduate School of Medicine,
approval R3900). The expected input files are listed, with MD5 checksums, in
`p1_*/dat/README.md`, `p2_*/dat/README.md` and `p5_*/dat/README.md`.

## Layout and run order

The folders mirror the original project layout, because every Rmd reads its inputs by
relative path. Run each file with its own folder as the working directory.

| Step | File (`p7_vit_dist_state_models_comp/`) | Reads | Writes | Time* |
|---|---|---|---|---|
| 1a | `p7_vit_dist_state_models_v2_compe_fix20260929.Rmd` — full model and four leave-one-channel-out fits | p1, p2 inputs; `ssm_801_4_redvar_rs.stan` | `ssm_801_4_redvar_rs_ex{ZERO,BPM,PULSE,RESP,TEMPR}_<timestamp>_exres_list.rds` | ~6.4 h |
| 1b | `p7_vit_dist_state_models_v2_onlys_fix20260930.Rmd` — four single-channel fits | as 1a | `ssm_801_4_redvar_rs_on{BPM,PULSE,RESP,TEMPR}_<timestamp>_exres_list.rds` | ~2.8 h |
| 2a | `p7_vit_dist_state_models_v2_compe_eval_fix20260930.Rmd` — 24-h severity, logistic regression, AUC | 1a fits; p2 inputs | `eval_sources_model_fix20260930.rds` | minutes |
| 2b | `p7_vit_dist_state_models_v2_compe_on_eval_fix20261001.Rmd` — same for single-channel fits | 1a full fit, 1b fits; p2 inputs | `eval_sources_model_on_add_fix.rds` | minutes |
| 3 | `p7_final_numbers_v23.Rmd` — all reported statistics, Figs 3a/3b, ESM Figs 2/3, convergence diagnostics | 2a, 2b outputs; p2, p5 inputs | `figs_final_v23/` | minutes (+ fits for diagnostics) |
| 4 | `value_effort_mismatch_v23.py` — Fig. 4 | `figs_final_v23/final_numbers_v23.csv` | `figs_final_v23/` | seconds |

\* Wall time on the original server (4 chains in parallel).

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

- **Normalization** (`p7_vit_dist_state_models_v2_compe_fix20260929.Rmd`, lines 131–146 and 219–223): |value − midpoint of the reference range| ÷ half-width of the range (temperature 36.0–38.4 °C, heart rate and mean blood pressure 70–109, respiratory rate 12–24 /min).
- **Model** (`ssm_801_4_redvar_rs.stan`): one latent severity per admission × measurement time; a random walk whose step SD is proportional to √(elapsed days); each normalized value ~ Normal(a<sub>k</sub> × severity, σ), with channel coefficients a<sub>k</sub> averaging 1. Sampling: 4 chains × 5,000 iterations (3,000 warm-up), adapt_delta 0.90, max_treedepth 15, seed 12345.
- **Exposure** (`..._compe_eval_fix20260930.Rmd`, lines 353–368): in the 24 h before ICU admission, the posterior-mean severity of each record is weighted by the time to the next measurement (the last by the time to ICU admission) and averaged per admission.
- **Outcome**: death within 30 days of ICU admission.
- **Statistics** (`p7_final_numbers_v23.Rmd`): AUC from the fitted probabilities of a univariable logistic regression (ROCR), DeLong 95 % CI (pROC); odds ratio per 1 SD with patient-level cluster-robust standard errors (sandwich); patient-level cluster bootstrap (2,000 resamples, seed 42); first-admission-only analysis; comparison with an abbreviated APACHE II physiology score from the same four vital signs (aPS-4, last value within 3 h and 12 h, missing = 0), DeLong test.

## Software

R 4.3.3, rstan 2.32.6 (StanHeaders 2.32.10), tidyverse 2.0.0, ROCR 1.0-11, lme4 1.1-35.1
(as recorded in the knitted outputs of steps 1–2); pROC and sandwich for step 3; Python 3
with matplotlib for step 4.

## License and citation

Code: MIT License (see `LICENSE`). Please cite the article above and this repository
(`CITATION.cff`).
