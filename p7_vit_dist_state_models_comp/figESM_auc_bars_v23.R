# Figs ESM-2 and ESM-3 as published (manuscript v2.3 / ESM v2.4).
#
# Same data and layout as the drafts written by p7_final_numbers_v23.Rmd (section 7),
# redrawn from figs_final_v23/final_numbers_v23.csv so that the AUC labels at the bar
# tips sit on a white background: the dashed full-model reference line (AUC 0.630)
# runs close to several tips and otherwise crosses the numbers.
#
# Usage:  Rscript figESM_auc_bars_v23.R [path/to/final_numbers_v23.csv] [outdir]
# Needs only ggplot2 (works with 3.4 and 4.x).

suppressPackageStartupMessages(library(ggplot2))
args <- commandArgs(trailingOnly = TRUE)
csv <- if (length(args) >= 1) args[1] else file.path("figs_final_v23", "final_numbers_v23.csv")
out <- if (length(args) >= 2) args[2] else "figs_final_v23"
dir.create(out, showWarnings = FALSE)

num <- read.csv(csv, stringsAsFactors = FALSE)
get <- function(block, model) {
  r <- num[num$block == block & num$model == model, ]
  stopifnot(nrow(r) == 1); r
}
auc_full <- num$auc[num$block == "primary"]; stopifnot(length(auc_full) == 1)
n_full   <- num$n[num$block == "primary"]

FAM <- "Times"
COL <- c("TRUE" = "#DA0017", "FALSE" = "#959595")
# value label on a white box, so the reference line passes behind it
tip_label <- function(size, ...) {
  border <- if (utils::packageVersion("ggplot2") >= "4.0.0") list(border.colour = NA) else list(label.size = 0)
  do.call(geom_label, c(list(..., hjust = 0, fill = "white", family = FAM, size = size,
                             label.padding = unit(0.30, "lines"), label.r = unit(0, "lines")), border))
}
save_pdf <- function(p, name, w, h, units = "cm")
  ggsave(file.path(out, paste0(name, ".pdf")), p, width = w, height = h, units = units, device = "pdf")

## Fig ESM-2: leave-one-channel-out
lv <- c("Full model", "Excluding temperature", "Excluding blood pressure",
        "Excluding respiratory rate", "Excluding heart rate")
key <- c("full", "exTEMPR", "exBPM", "exRESP", "exPULSE")
lo <- data.frame(ch = factor(lv, levels = rev(lv)),
                 auc = vapply(key, function(k) get("leave_one_out", k)$auc, numeric(1)))
lo$is_full <- lo$ch == "Full model"
stopifnot(abs(lo$auc[1] - auc_full) < 1e-12)
ge2 <- ggplot(lo, aes(ch, auc, fill = is_full)) +
  geom_col(width = 0.62) + coord_flip(ylim = c(0.55, 0.66)) +
  geom_hline(yintercept = auc_full, linetype = "dashed", colour = "grey40") +
  tip_label(3.1, aes(y = auc + 0.0012, label = sprintf("%.3f", auc))) +
  scale_fill_manual(values = COL, guide = "none") +
  theme_classic(base_family = FAM) +
  theme(axis.text = element_text(colour = "black", size = 11), axis.title = element_text(size = 11)) +
  labs(x = NULL, y = "AUC for 30-day mortality")
save_pdf(ge2, "FigESM2_leave_one_out_AUC_v23b", 13, 9)

## Fig ESM-3: single-channel models
lab <- c(onTEMPR = "Temperature", onRESP = "Respiratory rate", onBPM = "Blood pressure",
         onPULSE = "Heart rate")
sc <- num[num$block == "single_channel", ]
stopifnot(setequal(sc$model, names(lab)))
P <- rbind(data.frame(ch = unname(lab[sc$model]), n = sc$n, auc = sc$auc, is_full = FALSE),
           data.frame(ch = "Full model", n = n_full, auc = auc_full, is_full = TRUE))
P$ch <- factor(P$ch, levels = c("Temperature", "Respiratory rate", "Blood pressure",
                                "Heart rate", "Full model"))
P <- P[order(P$ch), ]
P$lab_ch <- factor(sprintf("%s (n = %d)", P$ch, P$n), levels = sprintf("%s (n = %d)", P$ch, P$n))
ge3 <- ggplot(P, aes(lab_ch, auc, fill = is_full)) +
  geom_col(width = 0.62) +
  geom_hline(yintercept = auc_full, linetype = "dashed", colour = "grey40", linewidth = 0.8) +
  tip_label(5.6, aes(y = auc + 0.002, label = sprintf("%.3f", auc))) +
  scale_fill_manual(values = COL, guide = "none") +
  scale_y_continuous(breaks = seq(0.50, 0.65, 0.05), expand = expansion(mult = c(0, 0.12))) +
  coord_flip(ylim = c(0.49, 0.685)) +
  labs(x = NULL, y = "AUC for 30-day mortality") +
  theme_classic(base_size = 21, base_family = FAM) +
  theme(axis.text = element_text(colour = "black", size = 18),
        axis.title.x = element_text(size = 19, margin = margin(t = 9)),
        axis.ticks.y = element_blank(), plot.margin = margin(10, 22, 8, 8))
save_pdf(ge3, "FigESM3_single_channel_AUC_v23b", 8.6, 5.2, units = "in")
cat("written:", file.path(out, c("FigESM2_leave_one_out_AUC_v23b.pdf", "FigESM3_single_channel_AUC_v23b.pdf")), sep = "\n")
