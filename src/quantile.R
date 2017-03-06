#' quantile
#' 
#' Compute empirical quantiles of sample data (e.g. survey data) corresponding to selected 
#  probabilities. 
#' Include the 9 methods described by Hyndman and Fan (1996) + the one by Cunnane (1978) + 
#  the one by Filiben (1975).
#'
#' @param x : a numeric vector or a value (character or integer) providing with the sample
# 		data; when `data` is not null, `x` provides with the name (`char`) or the position
# 		(int) of the variable of interest in the table;
#' @param data : (_option_) input table, defined as a dataframe, whose column defined by `x`
#		is used as sample data for the estimation; if passed, then `x` should be defined as
#		a character or an integer; default: `data=NULL` and input sample data should be passed
# 		as numeric vector in `x`;
#' @param probs : (_option_) numeric vector giving the probabilities with values in [0,1];
#		default: `probs=seq(0, 1, 0.25)` like in original `stats::quantile` function;
#' @param na.rm, names : (_option_) logical flags; if `na.rm=TRUE`, any NA and NaN's are 
# 		removed from `x` before the quantiles are computed; if `names=TRUE`, the result has 
# 		a names attribute; these two flags follow exactly the original implementation of
# 		`stats::quantile`; default: `na.rm= FALSE` and `names= FALSE`;
#' @param type : (_option_) an integer in [1,11] used to select one of the 9 algorithms 
# 		detailed in Hyndman and Fan (1996), alternatively the one inspired from Cunnane (1978) 
#		or the one in Filiben (1975), as in the Python scipy library; see the references for 
# 		more details;
#' @param method : (_option_) choice of the implementation of the quantile estimation method; 
# 		this can be either:
#'		+ `"INHERIT"` so that the function uses the original `stats::quantile` function already 
# 		implemented in R; this is incompatible with `type>9`,
#' 		+ `"DIRECT"` for a canonical implementation based on the direct transcription of the various
# 		quantile estimation algorithms;
#'	 	default: `method="DIRECT"`.
#'
#' @return a vector containing the quantile values.
#' @export
#' 
#' @references This code is intended as a supporting material for the following publication:
#    Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
#    in Proc. New Techniques and Technologies for Statistics.
#   
#   Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
#   Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)
quantile <- function(x, data = NULL, probs=seq(0, 1, 0.25), na.rm=FALSE, type=7, method="DIRECT", names= FALSE) {
  if (!type %in% 1:11) 
  	stop("Wrong parameter TYPE: must be an integer between 1 and 11")
  if (!all(probs>=0.& probs<=1.))
  	stop("Wrong quantile probabilities: must take value in range [0,1]")
  if (!method %in% c("DIRECT","INHERIT"))
  	stop("Wrong method selection: must be either \"DIRECT\" or \"INHERIT\"")
  else if (type>=10 & method=="INHERIT")
  	message("warning: parameter METHOD ignored with TYPE>9 - \"DIRECT\" method available only")
  	
  # deal with the case a data frame was passed, then x is understood as the column reference
  # (name or position)
  if (!is.null(data))
  	tryCatch({
    	X <- data[,x]
  	},
  	error = function(e){
  		message ("Input X not recognised as a column of data frame DATA")
  		message(e)	
  		return (NA)
  	})
  else
  	X <- x

  # that's indeed copied/pasted from original stats::quantile since we also use the na.rm
  # parameter  
  if (na.rm)
  		X <- X[!is.na(x)]
  else if (any(is.na(x)))
  		stop("Missing values and NaN's not allowed when parameter NA.RM is FALSE")	
  	
  N <-length(X)
  np <- length(probs)
  
  if(N==0 || np==0)
  	return (rep(NA_real_, np))
  
  # run the algorithm
  if (type %in% 1:9 & method=='INHERIT') {
  	    return(stats::quantile(X, probs = probs, type = type))
  	    
  } else if (type>=10 | method=='DIRECT') {
    
  	m <- switch(type,
  		0,							# type=1
  		0,							# type=2
  		-0.5,						# type=3
  		0,							# type=4
  		0.5,						# type=5
  		probs,						# type=6
  		1-probs,					# type=7
  		(probs+1)/3.,				# type=8
  		(2*probs+3)/8.,			# type=9
  		.4 + .2 * probs,			# type=10
  		.3175 + .365 * probs	# type=11
  		)
  		
    orderInit <- order(X)
    xx <- X[orderInit]

	if (TRUE) {
		# note the order of the assignments here: J is adjusted only after J_1 has been set
		J <- floor(N*probs + m) 
	 	J_1 <- J-1
	 	J <- ifelse(J>=N, N-1, J)
	 	J_1 <- ifelse(J_1<=0, 0, J_1)
	} else {
    	pp <- (1:N)/N
  		indexQj <- function(p, x, wcum) {
  			j <- 1:length(x)
  			xx <- x[which(wcum >= p)]
  			jj <- j[which(wcum >= p)]
  			jj <- jj[order(xx)]
  			return(jj[1])
		}
    	J <- sapply(probs + m/n, indexQj, x = xx, wcum = pp)
		indexQj_1 <- function(p, x, wcum) {
  			j <- 1:length(x)
  			xx <- x[which(wcum < p)]
  			jj <- j[which(wcum < p)]
  			jj <- jj[order(xx, decreasing = TRUE)]
  			return(jj[1])
		}
    	J_1 <- sapply(probs + m/n, indexQj_1, x = xx, wcum = pp)
    }
    
	# retrieve the pair of (ordered) samples used for the quantile estimation    
	# note the presence of "+1" since indexes in R start at 1
    Xj_1 <- xx[J_1 +1]
    Xj <- xx[J +1]

	# compute g parameter
    g <- probs*N + m - J    
    
    # set gamma depending on the type chosen
    gamma <- rep(0., np) # dummy initialisation
    if (type == 1) {
    	gamma[g>0] = 1.
    	# gamma[g<=0] = 0.
    } else if (type==2) {
    	gamma[g>0] = 1.
    	gamma[g<=0] = 0.5
    } else if (type==3) {
    	# gamma[g==0 & j%%2==0] = 0.
    	gamma[g!=0 | j%%2==1] = 0.5
    } else 
    gamma <- g
    
    qs <- (1-gamma)*Xj_1 + gamma*Xj
    
    # again, we follow here the convention of original stats::quantile function as
    # regards the naming of quantiles
    if (names && np > 0L) {
    	dig <- max(2L, getOption("digits"))
		names(qs) <- paste( 
							if (np<100) formatC(100*probs,format="fg", width=1, digits=dig)
							else format(100*probs, trim=TRUE, digits=dig), "%", sep=""
							)
	}
	
	return(qs)
    }
} 

