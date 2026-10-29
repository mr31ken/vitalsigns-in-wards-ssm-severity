# -*- coding: utf-8 -*-
"""Fig. 4 — measurement effort versus information value (manuscript v2.3).

Vertical axis: change in AUC when the vital sign is removed from the state-space
model (leave-one-channel-out), read from figs_final_v23/final_numbers_v23.csv
(written by p7_final_numbers_v23.Rmd).
Horizontal axis: share of general-ward patient-days on which the vital sign was
recorded in the reference population (April 2020 - December 2022): respiratory
rate 13.3 %, heart rate 93.3 %, blood pressure 91.5 %, temperature 93.8 %.

Usage:  python value_effort_mismatch_v23.py [path/to/final_numbers_v23.csv] [outdir]
Layout follows the previous version (v7, 2026-08-25).
"""
import csv
import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["Times New Roman", "Times", "DejaVu Serif"]
plt.rcParams["mathtext.fontset"] = "stix"

HERE = os.path.dirname(os.path.abspath(__file__))
CSV = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "figs_final_v23", "final_numbers_v23.csv")
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "figs_final_v23")
os.makedirs(OUT, exist_ok=True)

d_auc = {}
with open(CSV, newline="", encoding="utf-8") as fh:
    for row in csv.DictReader(fh):
        if row["block"] == "leave_one_out" and row["d_auc"] not in ("", "NA"):
            d_auc[row["model"]] = float(row["d_auc"])
assert set(d_auc) == {"exRESP", "exPULSE", "exBPM", "exTEMPR"}, d_auc

FREQ = {"exRESP": 13.3, "exPULSE": 93.3, "exBPM": 91.5, "exTEMPR": 93.8}
# (model, label, colour, comment, label x, comment x, alignment)
V = [
    ("exRESP", "Respiratory rate", "#009E73", "informative,\nyet rarely measured", 17, 17, "left"),
    ("exPULSE", "Pulse (heart rate)", "#D55E00", "most informative;\neffort matches value", 89.5, 58, "right"),
    ("exBPM", "Blood pressure", "#E69F00", "often measured,\nlittle added value", 88.5, 58, "right"),
    ("exTEMPR", "Temperature", "#56B4E9", "measured most;\nremoval raised the AUC", 90.5, 58, "right"),
]

fig, ax = plt.subplots(figsize=(7.4, 5.8), dpi=200)
ax.axvspan(0, 40, color="#009E73", alpha=0.05, zorder=0)
ax.axhline(0, color="grey", lw=0.9, ls="--", zorder=1)
for model, name, col, comment, lx, cx, ha in V:
    freq, dy = FREQ[model], d_auc[model]
    ax.scatter(freq, dy, s=200, color=col, edgecolor="black", lw=0.9, zorder=3)
    if model == "exRESP":
        ly, cy = dy + 0.004, dy - 0.007
    elif model == "exTEMPR":
        ly, cy = dy + 0.0035, dy - 0.0005
    else:
        ly, cy = dy + 0.003, dy + 0.0015
    ax.annotate(f"{name} ({freq:.1f}%)", xy=(lx, ly), ha=ha, va="center", fontsize=11.5, color="black")
    ax.annotate(comment, xy=(cx, cy), ha=ha, va="center", fontsize=10.5,
                color=col if col != "#56B4E9" else "#2b6a8f", style="italic")

ax.set_xlim(0, 100)
ax.set_ylim(-0.025, 0.040)
ax.tick_params(labelsize=11)
ax.set_xlabel("Measurement frequency\n(% of general-ward patient-days the vital was recorded)", fontsize=12)
ax.set_ylabel("Contribution to discrimination\n(ΔAUC when removed from the state-space model)", fontsize=12)
ax.set_title("Measurement effort is misaligned with information value", fontsize=13.5, fontweight="bold")
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.text(0.99, 0.02, "Above 0: removal lowered the AUC · Below 0: removal raised it",
        transform=ax.transAxes, ha="right", va="bottom", fontsize=9.5, color="#555", style="italic")
plt.tight_layout()
for ext in ("png", "pdf"):
    plt.savefig(os.path.join(OUT, f"Fig4_value_effort_mismatch_v23.{ext}"), bbox_inches="tight", dpi=200)
print("dAUC used:", {k: round(v, 4) for k, v in d_auc.items()})
