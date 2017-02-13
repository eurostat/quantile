/** 
## io_quantile {#sas_io_quantile}
Compute empirical quantiles of a file with sample data corresponding to given probabilities. 
	
	%io_quantile(ifn, ofn, idir=, odir=, probs=, _quantiles_=, 
				 type=7, method=DIRECT, ifmt=csv, ofmt=csv);

### Arguments
* `ifn` : input filename; 2-columns or 1-column data file (_e.g._, in csv format) where input data samples
	are stored; the last column of the file will be used for quantile estimation (since the first, when
	it exists, will be regarded as a list of indexes);
* `probs`, `type`, `method` : list of probabilities, type and method flags used for the definition
	of the quantile algorithm and its actual estimation; see macro [%quantile](@ref sas_io_quantile);
* `ifmt` : (_option_) type of the input file; default: `ifmt=csv`.

### Returns
* `ofn` : name of the output file  and variable where quantile estimates are saved; quantiles are 
	stored in a variable named `QUANT`;
* `ofmt` : (_option_) type of the output file; default: `ofmt=csv`;
* `_quantiles_` : (_option_) name of the output numeric list where quantiles can be stored in 
	increasing `probs` order.

### Description
Return estimates of underlying distribution quantiles based on one or two order statistics from 
the supplied elements in `var` at probabilities in `probs`, following quantile estimation algorithm
defined by `type` (see macro [%quantile](@ref sas_io_quantile)). 

### See also
[%quantile](@ref sas_io_quantile),
[UNIVARIATE](https://support.sas.com/documentation/cdl/en/procstat/63104/HTML/default/viewer.htm#univariate_toc.htm),
[quantile (R)](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html),
[mquantiles (scipy)](https://docs.scipy.org/doc/scipy-0.18.1/reference/generated/scipy.stats.mstats.mquantiles.html),
[gsl_stats_quantile* (C)](https://www.gnu.org/software/gsl/manual/html_node/Median-and-Percentiles.html).
*/ /** \cond */

/*
### About
This code is intended as a supporting material for the following publication:
* Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

### Notice
Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)
*/

%global _FORCE_STANDALONE_;
%let _FORCE_STANDALONE_=1;

%macro io_quantile(ifn			/* Full path of input filename 					(REQ) */
				, ofn=			/* Full path of output filename 				(REQ) */
				, probs=		/* List of probabilities 						(OPT) */
				, type=			/* Type of interpolation considered 			(OPT) */
				, method=		/* Flag used to select the estimation method 	(OPT) */
				, _quantiles_=	/* Name of the output variable 					(OPT) */
				, ifmt=			/* Format of input file 						(OPT) */
				, ofmt=			/* Format of output file 						(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %symexist(G_PING_ROOTPATH) EQ 1 %then %do; 
		%macro_put(&_mac);
	%end;
	%else %if %symexist(G_PING_ROOTPATH) EQ 0 or &_FORCE_STANDALONE_ EQ 1 %then %do; 
		%macro error_handle(m, cond, mac=, txt=, verb=);
			%if &cond %then %do;									%put &m - &mac: &txt; 	1
			%end;
			%else %do;																		0
			%end;
		%mend;
		%macro macro_isblank(v);
			%let __v = %superq(&v);
			%let ___v = %sysfunc(compbl(%quote(&__v))); 
			%put v=&v;
			%put __v=&__v;
			%put ___v=&___v;
			%if %sysevalf(%superq(__v)=, boolean) or %nrbquote(&___v) EQ 	%then %do;		1
			%end;
			%else %do;																		0
			%end;
		%mend;
		%macro par_check(p, type=, set=); 
			%if "%datatyp(&p)" EQ "&type" %sysfunc(find(&set, &p)) GT 0 	%then %do;		1
			%end;
			%else %do;																		0
			%end;
		%mend;
		%macro file_check(f); 
		  	%if %sysfunc(fileexist(&f))=1 %then %do;										0 
			%end;
		  	%else %do;  																	1
			%end;
		%mend;
		%macro work_clean/parmbuff;
			%let i=1;
   			%do %while(%scan(&syspbuff,&i) ne);			
				PROC DATASETS lib=WORK nolist; DELETE %scan(&syspbuff,&i); quit;
	   			%let i=%eval(&i+1);
			%end;
		%mend;
		%macro ds_nvars(d, lib=);
			%local dsid nvars rc;
			%let nvars=0;
			%let dsid=%sysfunc(open(&lib..&d));
			%if dsid NE 0 %then %do; 
				%let nvars=%sysfunc(attrn(&dsid,NVARS));
				%let rc=%sysfunc(close(&dsid));
			%end;
			&nvars	
		%mend;
	%end;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local MAXROWS
		FMTS;
	%let FMTS = CSV TAB DLM EXCEL DBF ACCESS;
	%let MAXROWS = 2147483647;

	%local _file 	/* full path of the input file */
		_dir 		/* name of the input file directory */
		_base 		/* basename of the input file */
		_ext		/* extension of the input file */
		_fn			/* filename of the input file without its directory path if any */
		isbl_idir 	/* test of existence of input directory parameter */
		isbl_dir; 	/* test of existence of directory in input filename */
	%let _file=&ifn;

	/* IFN: check parameter */
	%if %error_handle(ErrorInputFile, 
			%file_check(&ifn) EQ 1, mac=&_mac,	
			txt=%quote(!!! File %upcase(&ifn) does not exist !!!)) %then
		%goto exit;

	/* OFN: set the full output file path */
	%if %error_handle(WarningOutputFile, 
			%file_check(&ofn) EQ 0, mac=&_mac,	
			txt=%quote(! File %upcase(&ofn) already exists !), verb=warn) %then
		%goto warning;
	%warning:

	/* IFMT: set default/update parameter */
	%if %macro_isblank(ifmt)  %then 		%let ifmt=CSV; 
	%else									%let ifmt=%upcase(&ifmt);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&ifmt, type=CHAR, set=&FMTS) NE 0, mac=&_mac,	
			txt=!!! Parameter IFMT is an identifier in &FMTS !!!) %then
		%goto exit; 

	/* OFMT: ibid, set default/update parameter */
	%if %macro_isblank(ofmt)  %then 		%let ofmt=&ifmt; 
	%else									%let ofmt=%upcase(&ofmt);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&ofmt, type=CHAR, set=&FMTS) NE 0, mac=&_mac,	
			txt=!!! Parameter OFMT is an identifier in &FMTS !!!) %then
		%goto exit; 

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local dsn
		var
		names;
	%let idsn=iTMP&_mac;
	%let odsn=qTMP&_mac;
	%let names=QUANT;

	/* import */
	PROC IMPORT DATAFILE="&ifn" OUT=WORK.&idsn REPLACE 
		DBMS=&ifmt;
		GETNAMES=no;
	quit;

	/* note that there may be an issue occurs when the file has been created on a Windows
	* PC and SAS is running on Unix/Linux. 
	* One difference between both operating systems is the newline char. While Windows uses 
	* Carriage Return and Line Feed, the *nix-systems use only one of the chars. The problem 
	* can be solved by using dos2unix in the shell of the unix-box to transform the newline 
	* chars. */

	/* compute */
	%let nvars = %ds_nvars(&idsn, lib=WORK);
	%put nvars=&nvars;
	%quantile(VAR&nvars, probs=&probs, method=&method, type=&type, idsn=&idsn, ilib=WORK, 
			names=&names, odsn=&odsn, olib=WORK);

	/* export */
	PROC EXPORT DATA=&odsn OUTFILE="&ofn" REPLACE
		DBMS=&ofmt;
	quit;

	%if not %macro_isblank(_quantiles_) %then %do;
		PROC SQL noprint;	
			SELECT &names into :&_quantiles_ SEPARATED BY ' '
			FROM WORK.&odsn;
		quit;
	%end;

	%work_clean(&idsn); 

	%exit:
%mend io_quantile;

%macro _example_io_quantile;

	%let dir=/ec/prod/server/sas/0eusilc/test/samples;

	%let ifn=&dir./sample5.csv;
	%let ofn=&dir./sample5_quantile.csv;
	%let quantiles=;
	%let type=1;
	%let probs=0.001 0.005 0.01 0.02 0.05 0.10 0.50;
	%io_quantile(&ifn, ofn=&ofn, probs=&probs, type=&type, method=DIRECT, 
			_quantiles_=quantiles);
	%put quantiles=&quantiles;

%mend _example_io_quantile;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_io_quantile; 
*/

/** \endcond */

