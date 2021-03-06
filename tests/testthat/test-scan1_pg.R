context("LMM genome scan by scan1 with kinship matrix")


test_that("scan1 with kinship with intercross, vs ported lmmlite code", {

    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs)

    out_reml <- scan1(probs, iron$pheno, kinship, reml=TRUE)
    out_ml <- scan1(probs, iron$pheno, kinship, reml=FALSE)

    # "by hand" calculation
    y <- iron$pheno
    X <- cbind(rep(1, nrow(iron$pheno)))
    Ke <- decomp_kinship(kinship) # eigen decomp
    yp <- Ke$vectors %*% y
    Xp <- Ke$vectors %*% X
    # double the eigenvalues (== kinship matrix * 2)
    Ke$values <- Ke$values*2

    byhand1_reml <- Rcpp_fitLMM(Ke$values, yp[,1], Xp, reml=TRUE, tol=1e-12)
    byhand2_reml <- Rcpp_fitLMM(Ke$values, yp[,2], Xp, reml=TRUE, tol=1e-12)
    byhand1_ml <- Rcpp_fitLMM(Ke$values, yp[,1], Xp, reml=FALSE, tol=1e-12)
    byhand2_ml <- Rcpp_fitLMM(Ke$values, yp[,2], Xp, reml=FALSE, tol=1e-12)

    # hsq the same?
    expect_equal(as.numeric(out_reml$hsq[1,]),
                 c(byhand1_reml$hsq, byhand2_reml$hsq))
    expect_equal(as.numeric(out_ml$hsq[1,]),
                 c(byhand1_ml$hsq, byhand2_ml$hsq))

    # compare chromosome 1 LOD scores
    d <- dim(probs$probs[[1]])[3]
    loglik_reml1 <- loglik_reml2 <-
        loglik_ml1 <- loglik_ml2 <- rep(NA, d)
    for(i in 1:d) {
        Xp <- Ke$vectors %*% cbind(X, probs$probs[[1]][,-1,i])
        # calculate likelihoods using plain ML (not the residual log likelihood)
        loglik_reml1[i] <- Rcpp_calcLL(byhand1_reml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_reml2[i] <- Rcpp_calcLL(byhand2_reml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
        loglik_ml1[i] <- Rcpp_calcLL(byhand1_ml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_ml2[i] <- Rcpp_calcLL(byhand2_ml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
    }
    lod_reml1 <- (loglik_reml1 - byhand1_reml$loglik)/log(10)
    lod_reml2 <- (loglik_reml2 - byhand2_reml$loglik)/log(10)
    lod_ml1 <- (loglik_ml1 - byhand1_ml$loglik)/log(10)
    lod_ml2 <- (loglik_ml2 - byhand2_ml$loglik)/log(10)

    dimnames(out_reml$lod) <- dimnames(out_ml$lod) <- NULL
    expect_equal(out_reml$lod[1:d,1], lod_reml1)
    expect_equal(out_reml$lod[1:d,2], lod_reml2)
    expect_equal(out_ml$lod[1:d,1], lod_ml1)
    expect_equal(out_ml$lod[1:d,2], lod_ml2)

})

test_that("scan1 with intercross with X covariates for null", {

    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs)
    Xc <- get_x_covar(iron)

    out_reml <- scan1(probs, iron$pheno, kinship, Xcovar=Xc, reml=TRUE)
    out_ml <- scan1(probs, iron$pheno, kinship, Xcovar=Xc, reml=FALSE)

    # "by hand" calculation
    y <- iron$pheno
    X <- cbind(rep(1, nrow(iron$pheno)))
    Ke <- decomp_kinship(kinship) # eigen decomp
    yp <- Ke$vectors %*% y
    Xp <- Ke$vectors %*% X
    Xcp <- Ke$vectors %*% Xc
    # double the eigenvalues (== kinship matrix * 2)
    Ke$values <- Ke$values*2

    byhand1_reml <- Rcpp_fitLMM(Ke$values, yp[,1], cbind(Xp, Xcp), reml=TRUE, tol=1e-12)
    byhand2_reml <- Rcpp_fitLMM(Ke$values, yp[,2], cbind(Xp, Xcp), reml=TRUE, tol=1e-12)
    byhand1_ml <- Rcpp_fitLMM(Ke$values, yp[,1], cbind(Xp, Xcp), reml=FALSE, tol=1e-12)
    byhand2_ml <- Rcpp_fitLMM(Ke$values, yp[,2], cbind(Xp, Xcp), reml=FALSE, tol=1e-12)

    # hsq the same?
    expect_equal(as.numeric(out_reml$hsq[2,]),
                 c(byhand1_reml$hsq, byhand2_reml$hsq), tolerance=1e-6)
    expect_equal(as.numeric(out_ml$hsq[2,]),
                 c(byhand1_ml$hsq, byhand2_ml$hsq))

    # compare chromosome X LOD scores
    d <- dim(probs$probs[["X"]])[3]
    loglik_reml1 <- loglik_reml2 <-
        loglik_ml1 <- loglik_ml2 <- rep(NA, d)
    for(i in 1:d) {
        Xp <- Ke$vectors %*% cbind(1, probs$probs[["X"]][,-1,i])
        # calculate likelihoods using plain ML (not the residual log likelihood)
        loglik_reml1[i] <- Rcpp_calcLL(byhand1_reml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_reml2[i] <- Rcpp_calcLL(byhand2_reml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
        loglik_ml1[i] <- Rcpp_calcLL(byhand1_ml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_ml2[i] <- Rcpp_calcLL(byhand2_ml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
    }
    lod_reml1 <- (loglik_reml1 - byhand1_reml$loglik)/log(10)
    lod_reml2 <- (loglik_reml2 - byhand2_reml$loglik)/log(10)
    lod_ml1 <- (loglik_ml1 - byhand1_ml$loglik)/log(10)
    lod_ml2 <- (loglik_ml2 - byhand2_ml$loglik)/log(10)

    index <- nrow(out_reml$lod) - rev(1:d) + 1
    dimnames(out_reml$lod) <- dimnames(out_ml$lod) <- NULL
    expect_equal(out_reml$lod[index,1], lod_reml1)
    expect_equal(out_reml$lod[index,2], lod_reml2, tolerance=1e-6)
    expect_equal(out_ml$lod[index,1], lod_ml1)
    expect_equal(out_ml$lod[index,2], lod_ml2)

})


test_that("scan1 with kinship with intercross with an additive covariate", {

    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs)
    Xc <- get_x_covar(iron)
    X <- match(iron$covar$sex, c("f", "m"))-1
    names(X) <- rownames(iron$covar)

    out_reml <- scan1(probs, iron$pheno, kinship, addcovar=X, Xcovar=Xc, reml=TRUE, tol=1e-12)
    out_ml <- scan1(probs, iron$pheno, kinship, addcovar=X, Xcovar=Xc, reml=FALSE, tol=1e-12)

    # "by hand" calculation
    y <- iron$pheno
    Ke <- decomp_kinship(kinship) # eigen decomp
    yp <- Ke$vectors %*% y
    Xp <- Ke$vectors %*% cbind(1, X)
    Xcp <- Ke$vectors %*% Xc
    # double the eigenvalues (== kinship matrix * 2)
    Ke$values <- Ke$values*2

    # autosome null
    byhand1A_reml <- Rcpp_fitLMM(Ke$values, yp[,1], Xp, reml=TRUE, tol=1e-12)
    byhand2A_reml <- Rcpp_fitLMM(Ke$values, yp[,2], Xp, reml=TRUE, tol=1e-12)
    byhand1A_ml <- Rcpp_fitLMM(Ke$values, yp[,1], Xp, reml=FALSE, tol=1e-12)
    byhand2A_ml <- Rcpp_fitLMM(Ke$values, yp[,2], Xp, reml=FALSE, tol=1e-12)

    expect_equal(as.numeric(out_reml$hsq[1,]),
                 c(byhand1A_reml$hsq, byhand2A_reml$hsq))
    expect_equal(as.numeric(out_ml$hsq[1,]),
                 c(byhand1A_ml$hsq, byhand2A_ml$hsq))

    # X chr null
    byhand1X_reml <- Rcpp_fitLMM(Ke$values, yp[,1], cbind(Xp, Xcp[,-1]), reml=TRUE, tol=1e-12)
    byhand2X_reml <- Rcpp_fitLMM(Ke$values, yp[,2], cbind(Xp, Xcp[,-1]), reml=TRUE, tol=1e-12)
    byhand1X_ml <- Rcpp_fitLMM(Ke$values, yp[,1], cbind(Xp, Xcp[,-1]), reml=FALSE, tol=1e-12)
    byhand2X_ml <- Rcpp_fitLMM(Ke$values, yp[,2], cbind(Xp, Xcp[,-1]), reml=FALSE, tol=1e-12)

    # hsq the same?
    expect_equal(as.numeric(out_reml$hsq[2,]),
                 c(byhand1X_reml$hsq, byhand2X_reml$hsq), tolerance=1e-6)
    expect_equal(as.numeric(out_ml$hsq[2,]),
                 c(byhand1X_ml$hsq, byhand2X_ml$hsq))


    # compare chromosome 2 LOD scores
    d <- dim(probs$probs[["2"]])[3]
    loglik_reml1 <- loglik_reml2 <-
        loglik_ml1 <- loglik_ml2 <- rep(NA, d)
    for(i in 1:d) {
        Xp <- Ke$vectors %*% cbind(1, X, probs$probs[["2"]][,-1,i])
        # calculate likelihoods using plain ML (not the residual log likelihood)
        loglik_reml1[i] <- Rcpp_calcLL(byhand1A_reml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_reml2[i] <- Rcpp_calcLL(byhand2A_reml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
        loglik_ml1[i] <- Rcpp_calcLL(byhand1A_ml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_ml2[i] <- Rcpp_calcLL(byhand2A_ml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
    }
    lod_reml1 <- (loglik_reml1 - byhand1A_reml$loglik)/log(10)
    lod_reml2 <- (loglik_reml2 - byhand2A_reml$loglik)/log(10)
    lod_ml1 <- (loglik_ml1 - byhand1A_ml$loglik)/log(10)
    lod_ml2 <- (loglik_ml2 - byhand2A_ml$loglik)/log(10)

    index <- dim(probs$probs[["1"]])[3] + 1:dim(probs$probs[["2"]])[3]
    dimnames(out_reml$lod) <- dimnames(out_ml$lod) <- NULL
    expect_equal(out_reml$lod[index,1], lod_reml1)
    expect_equal(out_reml$lod[index,2], lod_reml2)
    expect_equal(out_ml$lod[index,1], lod_ml1)
    expect_equal(out_ml$lod[index,2], lod_ml2)

    # compare chromosome X LOD scores
    d <- dim(probs$probs[["X"]])[3]
    loglik_reml1 <- loglik_reml2 <-
        loglik_ml1 <- loglik_ml2 <- rep(NA, d)
    for(i in 1:d) {
        Xp <- Ke$vectors %*% cbind(1, probs$probs[["X"]][,-1,i])
        # calculate likelihoods using plain ML (not the residual log likelihood)
        loglik_reml1[i] <- Rcpp_calcLL(byhand1X_reml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_reml2[i] <- Rcpp_calcLL(byhand2X_reml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
        loglik_ml1[i] <- Rcpp_calcLL(byhand1X_ml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_ml2[i] <- Rcpp_calcLL(byhand2X_ml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
    }
    lod_reml1 <- (loglik_reml1 - byhand1X_reml$loglik)/log(10)
    lod_reml2 <- (loglik_reml2 - byhand2X_reml$loglik)/log(10)
    lod_ml1 <- (loglik_ml1 - byhand1X_ml$loglik)/log(10)
    lod_ml2 <- (loglik_ml2 - byhand2X_ml$loglik)/log(10)

    index <- nrow(out_reml$lod) - rev(1:d) + 1
    dimnames(out_reml$lod) <- dimnames(out_ml$lod) <- NULL
    ## FIX_ME
    ## REML not yet working on X chromosome, when (X, probs) is not full rank
#    expect_equal(out_reml[index,1], lod_reml1)
#    expect_equal(out_reml[index,2], lod_reml2)
    expect_equal(out_ml$lod[index,1], lod_ml1)
    expect_equal(out_ml$lod[index,2], lod_ml2)

})


test_that("scan1 with kinship with intercross with an interactive covariate", {

    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs)
    Xc <- get_x_covar(iron)
    X <- match(iron$covar$sex, c("f", "m"))-1
    names(X) <- rownames(iron$covar)

    out_reml <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12, intcovar_method="lowmem")
    out_ml <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                    Xcovar=Xc, reml=FALSE, tol=1e-12, intcovar_method="lowmem")
    out_reml_himem <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                            Xcovar=Xc, reml=TRUE, tol=1e-12, intcovar_method="highmem")
    out_ml_himem <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                          Xcovar=Xc, reml=FALSE, tol=1e-12, intcovar_method="highmem")

    # same result using "highmem" and "lowmem" methods
    expect_equal(out_reml_himem, out_reml)
    expect_equal(out_ml_himem, out_ml)

    # "by hand" calculation
    y <- iron$pheno
    Ke <- decomp_kinship(kinship) # eigen decomp
    yp <- Ke$vectors %*% y
    Xp <- Ke$vectors %*% cbind(1, X)
    Xcp <- Ke$vectors %*% Xc
    # double the eigenvalues (== kinship matrix * 2)
    Ke$values <- Ke$values*2

    # autosome null (same as w/o interactive covariate)
    byhand1A_reml <- Rcpp_fitLMM(Ke$values, yp[,1], Xp, reml=TRUE, tol=1e-12)
    byhand2A_reml <- Rcpp_fitLMM(Ke$values, yp[,2], Xp, reml=TRUE, tol=1e-12)
    byhand1A_ml <- Rcpp_fitLMM(Ke$values, yp[,1], Xp, reml=FALSE, tol=1e-12)
    byhand2A_ml <- Rcpp_fitLMM(Ke$values, yp[,2], Xp, reml=FALSE, tol=1e-12)

    expect_equal(as.numeric(out_reml$hsq[1,]),
                 c(byhand1A_reml$hsq, byhand2A_reml$hsq))
    expect_equal(as.numeric(out_ml$hsq[1,]),
                 c(byhand1A_ml$hsq, byhand2A_ml$hsq))

    # X chr null (same as w/o interactive covariate)
    byhand1X_reml <- Rcpp_fitLMM(Ke$values, yp[,1], cbind(Xp, Xcp[,-1]), reml=TRUE, tol=1e-12)
    byhand2X_reml <- Rcpp_fitLMM(Ke$values, yp[,2], cbind(Xp, Xcp[,-1]), reml=TRUE, tol=1e-12)
    byhand1X_ml <- Rcpp_fitLMM(Ke$values, yp[,1], cbind(Xp, Xcp[,-1]), reml=FALSE, tol=1e-12)
    byhand2X_ml <- Rcpp_fitLMM(Ke$values, yp[,2], cbind(Xp, Xcp[,-1]), reml=FALSE, tol=1e-12)

    # hsq the same?
    expect_equal(as.numeric(out_reml$hsq[2,]),
                 c(byhand1X_reml$hsq, byhand2X_reml$hsq), tolerance=1e-6)
    expect_equal(as.numeric(out_ml$hsq[2,]),
                 c(byhand1X_ml$hsq, byhand2X_ml$hsq))


    # compare chromosome 4 LOD scores
    npos <- sapply(probs$probs, function(a) dim(a)[[3]])
    d <- npos["4"]
    loglik_reml1 <- loglik_reml2 <-
        loglik_ml1 <- loglik_ml2 <- rep(NA, d)
    for(i in 1:d) {
        Xp <- Ke$vectors %*% cbind(1, X, probs$probs[["4"]][,-1,i], probs$probs[["4"]][,-1,i]*X)
        # calculate likelihoods using plain ML (not the residual log likelihood)
        loglik_reml1[i] <- Rcpp_calcLL(byhand1A_reml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_reml2[i] <- Rcpp_calcLL(byhand2A_reml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
        loglik_ml1[i] <- Rcpp_calcLL(byhand1A_ml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_ml2[i] <- Rcpp_calcLL(byhand2A_ml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
    }
    lod_reml1 <- (loglik_reml1 - byhand1A_reml$loglik)/log(10)
    lod_reml2 <- (loglik_reml2 - byhand2A_reml$loglik)/log(10)
    lod_ml1 <- (loglik_ml1 - byhand1A_ml$loglik)/log(10)
    lod_ml2 <- (loglik_ml2 - byhand2A_ml$loglik)/log(10)

    index <- sum(npos[1:3]) + 1:npos[4]
    dimnames(out_reml$lod) <- dimnames(out_ml$lod) <- NULL
    expect_equal(out_reml$lod[index,1], lod_reml1)
    expect_equal(out_reml$lod[index,2], lod_reml2)
    expect_equal(out_ml$lod[index,1], lod_ml1)
    expect_equal(out_ml$lod[index,2], lod_ml2)

    # compare chromosome X LOD scores
    d <- dim(probs$probs[["X"]])[3]
    loglik_reml1 <- loglik_reml2 <-
        loglik_ml1 <- loglik_ml2 <- rep(NA, 3)
    for(i in 1:d) {
        Xp <- Ke$vectors %*% cbind(1, X, probs$probs[["X"]][,-1,i], probs$probs[["X"]][,-1,i]*X)
        # calculate likelihoods using plain ML (not the residual log likelihood)
        loglik_reml1[i] <- Rcpp_calcLL(byhand1X_reml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_reml2[i] <- Rcpp_calcLL(byhand2X_reml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
        loglik_ml1[i] <- Rcpp_calcLL(byhand1X_ml$hsq, Ke$values, yp[,1], Xp, reml=FALSE)
        loglik_ml2[i] <- Rcpp_calcLL(byhand2X_ml$hsq, Ke$values, yp[,2], Xp, reml=FALSE)
    }
    lod_reml1 <- (loglik_reml1 - byhand1X_reml$loglik)/log(10)
    lod_reml2 <- (loglik_reml2 - byhand2X_reml$loglik)/log(10)
    lod_ml1 <- (loglik_ml1 - byhand1X_ml$loglik)/log(10)
    lod_ml2 <- (loglik_ml2 - byhand2X_ml$loglik)/log(10)

    index <- nrow(out_reml) - rev(1:d) + 1
    ## FIX ME
    ## Not yet working on X chromosome, when (X, probs) is not full rank
#    expect_equal(out_reml[index,1], lod_reml1)
#    expect_equal(out_reml[index,2], lod_reml2)
#    expect_equal(out_ml[index,1], lod_ml1)
#    expect_equal(out_ml[index,2], lod_ml2)

})

test_that("scan1 with kinship works with LOCO, additive covariates", {

    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs, "loco")
    Xc <- get_x_covar(iron)
    X <- match(iron$covar$sex, c("f", "m"))-1
    names(X) <- rownames(iron$covar)

    out_reml <- scan1(probs, iron$pheno, kinship, addcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12)
    out_ml <- scan1(probs, iron$pheno, kinship, addcovar=X,
                    Xcovar=Xc, reml=FALSE, tol=1e-12)

    y <- iron$pheno
    Ke <- decomp_kinship(kinship) # eigen decomp
    # double the eigenvalues (== kinship matrix * 2)
    Ke <- lapply(Ke, function(a) { a$values <- 2*a$values; a})

    # compare chromosomes 1, 6, 9, 18
    chrs <- paste(c(1,6,9,18))
    npos <- sapply(probs$probs, function(a) dim(a)[[3]])

    for(chr in chrs) {
        nchr <- which(names(npos) == chr)
        d <- npos[chr]

        yp <- Ke[[chr]]$vectors %*% y
        Xp <- Ke[[chr]]$vectors %*% cbind(1, X)

        # autosome null
        byhand1_reml <- Rcpp_fitLMM(Ke[[chr]]$values, yp[,1], Xp, reml=TRUE, tol=1e-12)
        byhand2_reml <- Rcpp_fitLMM(Ke[[chr]]$values, yp[,2], Xp, reml=TRUE, tol=1e-12)
        byhand1_ml <- Rcpp_fitLMM(Ke[[chr]]$values, yp[,1], Xp, reml=FALSE, tol=1e-12)
        byhand2_ml <- Rcpp_fitLMM(Ke[[chr]]$values, yp[,2], Xp, reml=FALSE, tol=1e-12)

        expect_equal(as.numeric(out_reml$hsq[nchr,]),
                     c(byhand1_reml$hsq, byhand2_reml$hsq), tolerance=1e-5)
        expect_equal(as.numeric(out_ml$hsq[nchr,]),
                     c(byhand1_ml$hsq, byhand2_ml$hsq), tolerance=1e-6)

        # chromosome scan
        loglik_reml1 <- loglik_reml2 <-
            loglik_ml1 <- loglik_ml2 <- rep(NA, d)
        for(i in 1:d) {
            Xp <- Ke[[chr]]$vectors %*% cbind(1, X, probs$probs[[chr]][,-1,i])
            # calculate likelihoods using plain ML (not the residual log likelihood)
            loglik_reml1[i] <- Rcpp_calcLL(byhand1_reml$hsq, Ke[[chr]]$values, yp[,1], Xp, reml=FALSE)
            loglik_reml2[i] <- Rcpp_calcLL(byhand2_reml$hsq, Ke[[chr]]$values, yp[,2], Xp, reml=FALSE)
            loglik_ml1[i] <- Rcpp_calcLL(byhand1_ml$hsq, Ke[[chr]]$values, yp[,1], Xp, reml=FALSE)
            loglik_ml2[i] <- Rcpp_calcLL(byhand2_ml$hsq, Ke[[chr]]$values, yp[,2], Xp, reml=FALSE)
        }
        lod_reml1 <- (loglik_reml1 - byhand1_reml$loglik)/log(10)
        lod_reml2 <- (loglik_reml2 - byhand2_reml$loglik)/log(10)
        lod_ml1 <- (loglik_ml1 - byhand1_ml$loglik)/log(10)
        lod_ml2 <- (loglik_ml2 - byhand2_ml$loglik)/log(10)

        if(nchr > 1) index <- sum(npos[1:(nchr-1)]) + 1:d
        else index <- 1:d
        dimnames(out_reml$lod) <- dimnames(out_ml$lod) <- NULL
        expect_equal(out_reml$lod[index,1], lod_reml1)
        expect_equal(out_reml$lod[index,2], lod_reml2, tolerance=1e-5)
        expect_equal(out_ml$lod[index,1], lod_ml1)
        expect_equal(out_ml$lod[index,2], lod_ml2)
    }

})

test_that("scan1 with kinship works with LOCO, interactive covariates", {

    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs, "loco")
    Xc <- get_x_covar(iron)
    X <- match(iron$covar$sex, c("f", "m"))-1
    names(X) <- rownames(iron$covar)

    out_reml <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12)
    out_ml <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                    Xcovar=Xc, reml=FALSE, tol=1e-12)


    y <- iron$pheno
    Ke <- decomp_kinship(kinship) # eigen decomp
    # double the eigenvalues (== kinship matrix * 2)
    Ke <- lapply(Ke, function(a) { a$values <- 2*a$values; a})

    # compare chromosomes 1, 6, 9, 18
    chrs <- paste(c(1,6,9,18))
    npos <- sapply(probs$probs, function(a) dim(a)[[3]])

    for(chr in chrs) {
        nchr <- which(names(npos) == chr)
        d <- npos[chr]

        yp <- Ke[[chr]]$vectors %*% y
        Xp <- Ke[[chr]]$vectors %*% cbind(1, X)

        # autosome null (same as w/o interactive covariate)
        byhand1_reml <- Rcpp_fitLMM(Ke[[chr]]$values, yp[,1], Xp, reml=TRUE, tol=1e-12)
        byhand2_reml <- Rcpp_fitLMM(Ke[[chr]]$values, yp[,2], Xp, reml=TRUE, tol=1e-12)
        byhand1_ml <- Rcpp_fitLMM(Ke[[chr]]$values, yp[,1], Xp, reml=FALSE, tol=1e-12)
        byhand2_ml <- Rcpp_fitLMM(Ke[[chr]]$values, yp[,2], Xp, reml=FALSE, tol=1e-12)

        expect_equal(as.numeric(out_reml$hsq[nchr,]),
                     c(byhand1_reml$hsq, byhand2_reml$hsq), tolerance=1e-5)
        expect_equal(as.numeric(out_ml$hsq[nchr,]),
                     c(byhand1_ml$hsq, byhand2_ml$hsq), tolerance=1e-6)

        # chromosome scan
        loglik_reml1 <- loglik_reml2 <-
            loglik_ml1 <- loglik_ml2 <- rep(NA, d)
        for(i in 1:d) {
            Xp <- Ke[[chr]]$vectors %*% cbind(1, X, probs$probs[[chr]][,-1,i], probs$probs[[chr]][,-1,i]*X)
            # calculate likelihoods using plain ML (not the residual log likelihood)
            loglik_reml1[i] <- Rcpp_calcLL(byhand1_reml$hsq, Ke[[chr]]$values, yp[,1], Xp, reml=FALSE)
            loglik_reml2[i] <- Rcpp_calcLL(byhand2_reml$hsq, Ke[[chr]]$values, yp[,2], Xp, reml=FALSE)
            loglik_ml1[i] <- Rcpp_calcLL(byhand1_ml$hsq, Ke[[chr]]$values, yp[,1], Xp, reml=FALSE)
            loglik_ml2[i] <- Rcpp_calcLL(byhand2_ml$hsq, Ke[[chr]]$values, yp[,2], Xp, reml=FALSE)
        }
        lod_reml1 <- (loglik_reml1 - byhand1_reml$loglik)/log(10)
        lod_reml2 <- (loglik_reml2 - byhand2_reml$loglik)/log(10)
        lod_ml1 <- (loglik_ml1 - byhand1_ml$loglik)/log(10)
        lod_ml2 <- (loglik_ml2 - byhand2_ml$loglik)/log(10)

        if(nchr > 1) index <- sum(npos[1:(nchr-1)]) + 1:d
        else index <- 1:d
        dimnames(out_reml$lod) <- dimnames(out_ml$lod) <- NULL
        expect_equal(out_reml$lod[index,1], lod_reml1)
        expect_equal(out_reml$lod[index,2], lod_reml2, tolerance=1e-6)
        expect_equal(out_ml$lod[index,1], lod_ml1)
        expect_equal(out_ml$lod[index,2], lod_ml2)
    }


})


test_that("scan1 with kinship works with multicore", {
    if(isnt_karl()) skip("this test only run locally")

    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs, "loco")
    Xc <- get_x_covar(iron)
    X <- match(iron$covar$sex, c("f", "m"))-1
    names(X) <- rownames(iron$covar)

    out_reml <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12)
    out_reml_4core <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                            Xcovar=Xc, reml=TRUE, tol=1e-12, cores=4)
    expect_equal(out_reml, out_reml_4core)


    out_ml <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                    Xcovar=Xc, reml=FALSE, tol=1e-12)
    out_ml_4core <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                          Xcovar=Xc, reml=FALSE, tol=1e-12, cores=4)
    expect_equal(out_ml, out_ml_4core)

})


test_that("scan1 with kinship LOD results invariant to change in scale to pheno and covar", {
    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs, "loco")
    Xc <- get_x_covar(iron)
    X <- match(iron$covar$sex, c("f", "m"))-1
    names(X) <- rownames(iron$covar)

    out_reml <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12)
    out_reml_scale <- scan1(probs, iron$pheno/100, kinship, addcovar=X*2, intcovar=X*2,
                            Xcovar=Xc*2, reml=TRUE, tol=1e-12)
    expect_equal(out_reml, out_reml_scale, tol=1e-6)


    out_ml <- scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                    Xcovar=Xc, reml=FALSE, tol=1e-12)
    out_ml_scale <- scan1(probs, iron$pheno/100, kinship, addcovar=X*4, intcovar=X*4,
                          Xcovar=Xc*4, reml=FALSE, tol=1e-12)
    expect_equal(out_ml, out_ml_scale, tol=1e-6)

})

test_that("scan1 deals with mismatching individuals", {
    library(qtl2geno)
    iron <- read_cross2(system.file("extdata", "iron.zip", package="qtl2geno"))
    probs <- calc_genoprob(iron, step=2.5, error_prob=0.002)
    kinship <- calc_kinship(probs, "loco")
    Xc <- get_x_covar(iron)
    X <- match(iron$covar$sex, c("f", "m"))-1
    names(X) <- rownames(iron$covar)

    ind <- c(1:50, 101:150)
    subK <- lapply(kinship, "[", ind, ind)
    expected <- scan1(probs[ind,], iron$pheno[ind,,drop=FALSE], subK, addcovar=X[ind], intcovar=X[ind],
                      Xcovar=Xc[ind,], reml=TRUE, tol=1e-12)
    expect_equal(scan1(probs[ind,], iron$pheno, kinship, addcovar=X, intcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12), expected)
    expect_equal(scan1(probs, iron$pheno[ind,], kinship, addcovar=X, intcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12), expected)
    expect_equal(scan1(probs, iron$pheno, subK, addcovar=X, intcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12), expected)
    expect_equal(scan1(probs, iron$pheno, kinship, addcovar=X[ind], intcovar=X,
                      Xcovar=Xc, reml=TRUE, tol=1e-12), expected)
    expect_equal(scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X[ind],
                      Xcovar=Xc, reml=TRUE, tol=1e-12), expected)
    expect_equal(scan1(probs, iron$pheno, kinship, addcovar=X, intcovar=X,
                      Xcovar=Xc[ind,], reml=TRUE, tol=1e-12), expected)

})
