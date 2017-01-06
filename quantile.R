quantile <- function(x, type = 1:10, probs = 0.5) {
  # Compute the quantile for weighted data (e.g. survey data). Includes the 9 methods
  # described by Hyndman and Fan (1996).
  #
  # Args:
  #  x: numeric vector giving the values taken by the variable of interest.
  #  type: an integer between 1 and 9 selecting one of the nine quantile algorithms detailed
  #in Hyndman and Fan (1996).
  #  probs: numeric vector of probabilities with values between 0 and 1.
  #
  # Returns:
  #  The vector of quantile values.
  type <- match.arg(type)
  
  if (type %in% 1:9) {
    stats::quantile(x = x, type = type, probs = probs)
  } else {
    n <- length(x)
    m <- 0.4 + 0.2*probs
    orderInit <- order(x)
    xx <- x[order(x)]
    pp <- (1:n)/n

    J <- sapply(probs + m/n, indexQj, x = xx, wcum = pp)
    J_1 <- sapply(probs + m/n, indexQj_1, x = xx, wcum = pp)
    
    Xj_1 <- xx[J_1]
    Xj <- xx[J]
    
    gamma <- probs*n + m - J
    return((1-gamma)*Xj_1 + gamma*Xj)
    }
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