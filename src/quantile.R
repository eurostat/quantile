quantile <- function(x, type = 1:11, probs = 0.5) {
  # Compute the quantile for weighted data (e.g. survey data). Includes the 9 methods
  # described by Hyndman and Fan (1996) + the one by Cunnane (1978) + the one by Filiben (1975).
  #
  # Args:
  #  x: numeric vector giving the values taken by the variable of interest.
  #  type: an integer between 1 and 11 selecting one of the nine quantile algorithms detailed
  #in Hyndman and Fan (1996), alternatively the one inspired from Cunnane (1978) or the one
  #in Filiben (1975), as in the Python scipy library. See the references for more details.
  #  probs: numeric vector of probabilities with values between 0 and 1.
  #
  # Returns:
  #  The vector of quantile values.
  if (!type %in% 1:11) stop("Parameter type must be an integer between 1 and 11.")
  
  if (type %in% 1:9) {
    stats::quantile(x = x, type = type, probs = probs)
  } else {
    if (type == 10) 
      m <- 0.4 + 02*probs else m <- 0.3175 + 0.365*probs
    n <- length(x)
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