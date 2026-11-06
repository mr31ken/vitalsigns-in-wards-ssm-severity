# Builds the measurement table df_j (vital signs in the 48 h before each unplanned ICU admission),
# used in this repository only for the aPS-4 comparison in p7_final_numbers_v23.Rmd.
#
# The file used in the article, dat/df_j20240524_052253.rds, was written on 2024-05-24 by the authors'
# working notebook, which was edited afterwards; no copy of it as run on that day survives. This script
# reconstructs it from p5_vit_dist_inhosp/copy_of_p5_01.Rmd (2024-07), copied verbatim -- lines 11-20
# (packages), 26-30 (timestamp), 83-99 (inputs), 103-105 and 109-133 (df_j), 583-586 (output) -- except
# for the two lines marked "as run 2024-05-24", which restore the code of the notebooks of May-June 2024
# (p5_02_define_earlysigns.Rmd line 88; p5_01_vit_dist_inhosp.Rmd lines 102-103). Re-run on 2026-11-07,
# it reproduced df_j20240524_052253.rds (18,166 rows; all values equal).
#
# Note: mean blood pressure is computed here as BPL + (BPH - BPL) / 3 even when only one of systolic
# (BPH) or diastolic (BPL) pressure was recorded and the other is stored as 0. For those 13 measurements
# (31 rows of df_j, which repeats some measurements) the value is two-thirds of the diastolic or one-third
# of the systolic pressure, not a mean pressure. The state-space model does not use df_j (p7 sets mean
# pressure to 0, i.e. missing, in that case).
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
  mutate(BPM = BPL + (BPH - BPL) / 3)  # as run 2024-05-24

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
