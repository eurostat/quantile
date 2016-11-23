#STARTDOC
### R {#r_assignPercentile}
#[//]: # (Divide a given sample, possibly weighted, into a certain number of slices of equal size, with units ranked according to a variable of interest.)
#
#    > assignPercentile(x, w, s)
#
#### Arguments
#* `data`: (_option_) the name of the dataframe
#* `x`: the variable of interest (e.g. income or wealth). It has to be a numeric vector.
#* `w`: (_option_) the weights (in case of a survey for instance). It has to be a numeric vector. Default is 1.
#* `s`: the number of slices.
#* `name_s`: (_option_) the name of the output variable in the data frame `data`. Default is `var`_s. 
#It has to be a character string.
#
#### Returns
#* If `x` is a vector, a vector of same lenght containing for each unit `i` the number associated to the slice.
#* If `x` is a variable of the data frame `data`, the data frame including a variable named `name_s´ containing 
#for each unit `i` the number associated to the slice.
#
#### Examples
#
#
#
#ENDDOC

assignPercentile <- function(data = NULL, x, w = NULL, s, name_s = NULL) {
  
  if (is.null(data)) {
    if (!exists(as.character(quote(x)))) stop("Vector 'x' is missing.")
    if (!is.null(w) & length(w) != length(x)) stop("Vectors 'x' and 'w' are not the same length.")
  } else {
    if (!exists(as.character(quote(x)))) stop("Variable 'x' is missing.")
    if (!is.character(x)) stop("Variable 'x' should be a character string.")
    # To be simplified
    if (!x %in% names(data)) stop("Variable ",sQuote(x)," is not in the data.")
    if (!is.null(w) & !w %in% names(data)) stop("Variable ",sQuote(w)," is not in the data.")
    name.x <- x
    x <- data[,x]
    if (!is.null(w)) w <- data[,w]
    
    if (is.null(name_s)) name_s <- paste0(name.x,"_s")
    if (!is.character(name_s)) stop("Parameter name_s has to be character.")
  }
  
  if (is.null(w)) w <- rep(1,length(x))
  # case weights with missing values: critical error
  if (sum(is.na(w)) > 0) stop("There are missing values in the weights.")
  # case weights with negative values: critical error
  if (sum(w<0) > 0) stop("There are negative values in the weights.")
  
  n <- length(x)
  nn <- 1:n
  nn <- nn[order(x)]
  
  # 1st method:
  ww <- ceiling((cumsum(w[order(x, na.last = NA)])/sum(w[!is.na(x)]))*s)
  y <-  c(ww,rep(NA,sum(is.na(x))))[order(nn)]
  
  if (is.null(data)) return(y) else {
    data[,name_s] <- y
    return(data)
  }
}

# Test 1
if (exists("yy")) rm("yy")
# no data - one random vector
xx <- rnorm(n = 1000)
yy <- assignPercentile(x = xx, s = 10)
if (exists("yy")) print("Test 1 successful.", quote = FALSE)
# Test 2
# no data - one random vector + one weight
ww <- rexp(n  = 1001)
rm("yy")
yy <- assignPercentile(x = xx, w = ww, s = 10)
if (!exists("yy")) print("Test 2 successful.", quote = FALSE)
# Test 3
# no data - one random vector + one weight
ww <- rexp(n  = 1000)
rm("yy")
yy <- assignPercentile(x = xx, w = ww, s = 10)
if (exists("yy")) print("Test 3 successful.", quote = FALSE)
# Test 4
tab <- data.frame(inc = xx, weight = ww)
tab <- assignPercentile(data = tab, x = "inc", w = "weight", s = 10)