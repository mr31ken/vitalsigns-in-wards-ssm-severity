# Builds the measurement table df_j (vital signs in the 48 h before each unplanned ICU admission),
# used in this repository only for the aPS-4 comparison in p7_final_numbers_v23.Rmd.
#
# Code: p5_vit_dist_inhosp/copy_of_p5_01.Rmd (the authors' working notebook, 2024-07), copied verbatim --
# lines 11-20 (packages), 26-30 (timestamp), 83-99 (inputs), 103-105 and 109-133 (df_j), 583-586
# (output) -- except for the line marked "as run 2024-05-24" (notebook p5_01_vit_dist_inhosp.Rmd,
# lines 102-103), which keeps JIPAD_ID out of the join as in the file first used.
#
# Mean blood pressure (BPM) is computed only when both systolic (BPH) and diastolic (BPL) pressure were
# recorded, as in the state-space model (p7); otherwise it is 0 and dropped by filter(value != 0).
# The file first used for the aPS-4 comparison, dat/df_j20240524_052253.rds (2024-05-24), was made
# with BPM = BPL + (BPH - BPL) / 3 for every record. Where only one side was recorded (the other is
# stored as 0) this gave two-thirds of the diastolic or one-third of the systolic pressure: 13
# measurements, 31 rows of that file. The article (v2.3) uses the file written by this script.
# To reproduce df_j20240524_052253.rds (18,166 rows; checked 2026-11-07, all values equal), replace
# the BPM step with  mutate(BPM = BPL + (BPH - BPL) / 3).
#
# Run with this folder (p5_vit_dist_inhosp/) as the working directory:
#   Rscript p5_build_df_j.R

require(tidyverse)
require(openxlsx)
require(jsonlite)
require(officer)
require(ggpubr)
require(IRdisplay)
require(data.table)
require(lubridate)
require(repr)
require(tictoc)

ts <- Sys.time()  %>% 
    as.character() %>% 
    str_remove_all(., "[-:]*") %>% 
    str_replace(.," ", "_")
ts

f_in <- "../p1_whole_admtc_vit_fromCIS/dat/ir_admtc_20240329_075221.rds"
df_admtc <- readRDS(f_in)

# f2_in <- "../p1_whole_admtc_vit_fromCIS/dat/ir_vit_20240329_075221.rds"
f2_in <- "../p1_whole_admtc_vit_fromCIS/dat/vit_20240329_075221.rds"
df_vit <- readRDS(f2_in)  %>% 
  mutate(BPM = case_when(
    BPH * BPL > 0 ~ BPL + (BPH - BPL) / 3,
    BPH * BPL == 0 ~ 0,
    T ~ 0
  ))

f3_in <- "../p2_unplanned_ICUadmission/dat/icu_target20240517_044716.297905.rds"
df_icu_target <- readRDS(f3_in)

f_setting <- "../p1_whole_admtc_vit_fromCIS/dat/setting_20240329_082442.rds"
setting_list <- readRDS(f_setting)

df_vit <- df_vit %>%
    mutate(dt = str_c(MEASURED_DATE, MEASURED_TIME, sep=" ") %>%
        lubridate::ymd_hms())

df_j <- left_join(df_vit, df_icu_target %>% dplyr::select(PT_ID, ADM_DT),  # as run 2024-05-24
                by = c("PT_ID"="PT_ID"), relationship = "many-to-many") %>% 
  dplyr::select(PT_ID, ADM_DT, everything()) %>% 
  mutate(sub_DT=ADM_DT-dt) %>% 
  filter(sub_DT>=0) %>% 
  mutate(in_24h=sub_DT<=24*60*60) %>% 
  mutate(in_48h=sub_DT<=48*60*60) %>% 
  mutate(in_96h=sub_DT<=96*60*60) %>% 
  dplyr::filter(in_96h) %>% 
  dplyr::select(PT_ID, ADM_DT, dt, sub_DT, in_24h, in_48h, everything()) %>% 
  tidyr::pivot_longer(cols=c("PULSE", "RESP", "BPL", "BPH", "BPM", "TEMPR")) %>% 
  filter(value!=0) %>% 
  mutate(hour = sub_DT/3600) %>% 
  mutate(hrs = as.numeric(hour)) %>% 
  mutate(hrs_int = round(hrs)) %>%
  dplyr::select(-MEASURED_SEQ) %>%
  distinct() %>% 
  # not input date -> MEASURED_DATE
  group_by(PT_ID, name, MEASURED_DATE) %>% 
  mutate(vit_mes_count = n()) %>%
  filter(hrs < 48) %>% 
  # after ICU admission, vit count may over 36 in same date. so this filtering is not apropriate. removed.
  # filter(vit_mes_count <= 36) %>%
  filter((name == "RESP" & value<=50 & value>=1) | name != "RESP") %>%
  mutate(nhrs = -hrs)

f_out <- c("./dat/df_j",ts,".rds") %>% 
  str_c(sep="",collapse = "")
saveRDS(df_j, file = f_out)
f_out
