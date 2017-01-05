quantile <- function(x, w, type = 1:9, probs = 0.5) {
  # Compute the quantile for weighted data (e.g. survey data). Includes the 9 methods
  # described by Hyndman and Fan (1996).
  #
  # Args:
  #  x: numeric vector giving the values taken by the variable of interest.
  #  w: vector of weights. The default is 1.
  #  type: an integer between 1 and 9 selecting one of the nine quantile algorithms detailed
  #in Hyndman and Fan (1996).
  #  probs: numeric vector of probabilities with values between 0 and 1.
  #
  # Returns:
  #  The vector of quantile values.
  if (!exists(as.character(quote(x)))) stop("Parameter 'x' does not exist.")
  if (!exists(as.character(quote(w)))) w = rep(1,nrow(x))
  type <- match.arg(type)

  orderInit <- 1:length(x)
  orderInit <- orderInit[order(x)]
  xx <- x[order(x)]
  ww <- cumsum(w[order(x)])/sum(w)
  
  J <- sapply(probs, indexQj, x = xx, wcum = ww)
  J_1 <- sapply(probs, indexQj_1, x = xx, wcum = ww)
  
  Xj_1 <- xx[J_1]
  Xj <- xx[J]
  
  if (type == 1) {
    gamma <- (round(ww[J_1] - probs*sum(w)) == 0)
  }
  return((1-gamma)*Xj_1 + gamma*Xj)
} 

indexQj <- function(x, wcum, p) {
  j <- 1:length(x)
  xx <- x[which(wcum >= p)]
  jj <- j[which(wcum >= p)]
  jj <- jj[order(xx)]
  return(jj[1])
}

indexQj_1 <- function(x, wcum, p) {
  j <- 1:length(x)
  xx <- x[which(wcum < p)]
  jj <- j[which(wcum < p)]
  jj <- jj[order(xx, decreasing = TRUE)]
  return(jj[1])
}