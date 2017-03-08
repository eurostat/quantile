#' io_quantile
#' 
#' Compute empirical quantiles, corresponding to selected probabilities, of sample data 
#  stored in a csv file. 
#' Include the 9 methods described by Hyndman and Fan (1996) + the one by Cunnane (1978) + 
#  the one by Filiben (1975).
#'
#' @param infile : input filename; 2-columns or 1-column data file (_e.g._, in csv format) 
# 		where input data samples are stored; the last column of the file will be used for 
#		quantile estimation (since the first, when it exists, will be regarded as a list of 
# 		indexes);
#' @param header : (_option_) logical flag, as used by the `read.csv` function; default:
#		`header=TRUE`;
#' @param probs, na.rm, names, type, method : (_option_) same as those used in `quantile` function.
#'
#' @return q : a vector containing the quantile values.
#' @export ofile : output filename (in csv format) where estimated quantiles stored; default:
#		`ofile=NULL` and no export is performed.
#' 
#' @references This code is intended as a supporting material for the following publication:
#    Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
#    in Proc. New Techniques and Technologies for Statistics.
#   
#   Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
#   Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)

# load resource if needed
if(exists("quantile", mode = "function"))
    source("quantile.R")
    
io_quantile <- function(ifile, probs = seq(0, 1, 0.25), type = 7, ofile=NULL, names=FALSE, method="DIRECT", 	header=TRUE) {
  if (!is.character(ifile)) 
  	stop("Wrong input parameter IFILE type.")
  else if(!file.exists(ifile)) 
  	stop("Input file path IFILE not recognised.")
  else if (!is.null(ofile) & !is.character(ofile)) 
  	stop("Wrong output parameter OFILE type.")

  tryCatch({
    	x <- read.csv(ifile, header=header)   		
  	},
  	warning = function(w){
  		message () # dummy warning
  		return(NULL)
  	},
  	error = function(e){
  		message ("Input data not loaded")
  		message(e)	
  		return(NA)
  	})
  	
  # we accept 1- and 2-column dataset
  data <- x
  x <- colnames(x)[length(colnames(x))]
  q <- quantile(x, data = data, probs = probs, method = method, type = type, names = names)
  
  if(!is.null(ofile)) {
  	if(!file.exists(ofile)) 
  		message("Output file path OFILE will be overwritten.")
  	
  	tryCatch({
    	write.csv(q, ofile, header=header)   		
  	},
  	warning = function(w){
  		message () # dummy warning
  		return(NULL)
  	},
  	error = function(e){
  		message ("Input data not loaded")
  		message(e)	
  		return(NA)
  	})
  }
  
  return(q)
 }

