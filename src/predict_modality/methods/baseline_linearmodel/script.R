cat("Loading dependencies\n")
options(tidyverse.quiet = TRUE)
library(tidyverse)
requireNamespace("anndata", quietly = TRUE)
library(Matrix, warn.conflicts = FALSE, quietly = TRUE)

## VIASH START
par <- list(
  input_mod1 = "work/ea/93e6cd67b9d52bac9c71ee00bf853d/lymph_node_lymphoma_14k_mod2.censor_dataset.output_mod1.h5ad",
  input_mod2 = "work/ea/93e6cd67b9d52bac9c71ee00bf853d/lymph_node_lymphoma_14k_mod2.censor_dataset.output_mod2.h5ad",
  output = "output.h5ad",
  n_pcs = 4L
)
## VIASH END

cat("Reading h5ad files\n")
ad1 <- anndata::read_h5ad(par$input_mod1)
ad2 <- anndata::read_h5ad(par$input_mod2)

cat("Performing DR on the mod1 values\n")
dr <- lmds::lmds(
  ad1$X, 
  ndim = par$n_pcs,
  distance_method = par$distance_method
)

dr_train <- dr[ad1$obs$group == "train",]
responses_train <- ad2$X
dr_test <- dr[ad1$obs$group == "test",]

cat("Predicting for each column in modality 2\n")
preds <- lapply(seq_len(ncol(responses_train)), function(i) {
  y <- responses_train[,i]
  if (length(unique(y)) > 1) {
    lm <- lm(YTRAIN~., data.frame(dr_train, YTRAIN=y))
    stats::predict(lm, data.frame(dr_test))
  } else {
    setNames(rep(unique(y), nrow(dr_test)), rownames(dr_test))
  }
})

cat("Creating outputs object\n")
prediction <- Matrix::Matrix(do.call(cbind, preds), sparse = TRUE)
rownames(prediction) <- rownames(dr_test)
colnames(prediction) <- colnames(ad2)

out <- anndata::AnnData(
  X = prediction,
  uns = list(
    dataset_id = ad1$uns[["dataset_id"]],
    method_id = "baseline_linearmodel"
  )
)

cat("Writing predictions to file\n")
zzz <- out$write_h5ad(par$output, compression = "gzip")
