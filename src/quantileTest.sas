/** 
## quantile {#sas_quantile}
Produce sample quantiles corresponding to the given probabilities. 
	
	%quantile(var, probs=, type=7, method=DIRECT, names=, _quantiles_=, 
				idsn=, odsn=, ilib=WORK, olib=WORK, na_rm = YES);

### See also
[UNIVARIATE](https://support.sas.com/documentation/cdl/en/procstat/63104/HTML/default/viewer.htm#univariate_toc.htm),
[quantile (R)](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html),
[mquantiles (scipy)](https://docs.scipy.org/doc/scipy-0.18.1/reference/generated/scipy.stats.mstats.mquantiles.html).
*/ /** \cond */


%macro quantileTest(ifn			/* List of probabilities 								(OPT) */
				, probs=		/* List of probabilities 								(OPT) */
				, type=			/* Type of interpolation considered 					(OPT) */
				, method=		/* Flag used to select the estimation method 			(OPT) */
				, names=		/* Output name of variable/dataset 						(OPT) */
				, _quantiles_=	/* Name of the output variable 							(OPT) */
				, idir=			/* Full path of input directory 						(OPT) */
				, olib=			/* Output  library 										(OPT) */
				, fmt=			/* Format of import 									(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %symexist(G_PING_ROOTPATH) EQ 1 %then %do; 
		%macro_put(&_mac);
	%end;
	%else %if %symexist(G_PING_ROOTPATH) EQ 0 or &_FORCE_STANDALONE_ EQ 1 %then %do; 
		/* "dummyfied" macros */
		%macro error_handle/parmbuff;	0 /* always OK, nothing will ever be checked */
		%mend;
		%macro ds_check/parmbuff; 		0 /* always OK */
		%mend;
		%macro var_check/parmbuff; 		0 /* always OK */
		%mend;
		%macro dir_check/parmbuff; 		0 /* always OK */
		%mend;
		%macro par_check/parmbuff; 		0 /* always OK */
		%mend;
		%macro file_check/parmbuff; 	0 /* always OK */
		%mend;
		/* simplified macros */
		%macro macro_isblank(v);	
			%if &v= %then %do;		1
			%end;
			%else %do;				0
			%end;
		%mend;
		%macro work_clean(d);
			PROC DATASETS lib=WORK nolist; DELETE &d; quit;
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
	
	/* OLIB */
	%if %macro_isblank(olib) %then 	%let olib=WORK;

	/* FMT: set default/update parameter */
	%if %macro_isblank(fmt)  %then 			%let fmt=CSV; 
	%else									%let fmt=%upcase(&fmt);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&fmt, type=CHAR, set=&FMTS) NE 0, mac=&_mac,	
			txt=!!! Parameter FMT is an identifier in &FMTS !!!) %then
		%goto exit; 

	/* IDIR/FILE: set default/update parameter */
	%let _base=%file_name(&ifn, res=base); /* we possibly have _base = _file */
	%let _dir=%file_name(&ifn, res=dir);
	%let _ext=%file_name(&ifn, res=ext);
	%let _fn=%file_name(&ifn, res=file);

	%let isbl_idir=%macro_isblank(idir);
	%let isbl_dir=%macro_isblank(_dir);

	%if &isbl_idir=0 and &isbl_dir=0 %then %do;
		%if %error_handle(ErrorInputParameter, 
			%quote(&_dir) NE %quote(&idir), mac=&_mac,	
			txt=!!! Incompatible parameters IDIR and IFN - Check paths !!!) %then
		%goto exit;
		/* else: do nothing, change nothing - _file as is */
	%end;
	%else %if &isbl_idir=1 and &isbl_dir=1 %then %do;
		/* look in current directory */
		%if %symexist(_SASSERVERNAME) %then /* working with SAS EG */
			%let thisprog = &_CLIENTPROJECTNAME; /* note: this include the quotes '' */
			%let lenprog = %sysfunc(length(&thisprog));
			%let thispath = &_CLIENTPROJECTPATH; /* ibid: quotes are included */
			%let lenpath = %sysfunc(length(&thispath));
			%let output=%sysfunc(substr(&thispath, 2, &lenpath-&lenprog-1));
			%let lenpath = %sysfunc(length(&output));
			%let i=%sysfunc(find(&output, \));  /*starting from the left */
			%let idir=%sysfunc(substr(&output,&i+1,&lenpath-&i));
		%else %if &sysscp = WIN %then %do; 	/* working on Windows server */
			%let idir=%sysget(SAS_EXECFILEPATH);
			%if not %macro_isblank(idir) %then
				%let idir=%qsubstr(&idir, 1, %length(&idir)-%length(%sysget(SAS_EXECFILENAME));
		%end;
	%end;
	%else %if &isbl_idir=1 /* and &isbl_dir=0 */ %then %do;
		%let idir=&_dir;
	%end;
	%else %if &isbl_idir=0 /* and &isbl_dir=1 */ %then %do;
		/* do nothing */ ;
	%end;
		
	/* IDIR: check/set default/update parameter */
	%if %error_handle(ErrorInputParameter, 
			%dir_check(&idir) NE 0, mac=&_mac,		
			txt=%quote(!!! Input directory %upcase(&idir) does not exist !!!)) %then
		%goto exit;

	/* FMT: check parameter */
	%if not %macro_isblank(fmt) %then %do;
		%let fmt=%lowcase(&fmt);
		%if %error_handle(ErrorInputParameter, 
			not %macro_isblank(_ext) and %quote(&_ext) NE %quote(&fmt), mac=&_mac,	
			txt=!!! Incompatible parameter FMT with extension %upcase(&_ext) !!!) %then
		%goto exit;
		/* else: do nothing, change nothing */
	%end;

	/* reset the full input file path */
	%if not %macro_isblank(fmt) and %macro_isblank(_ext) %then 	%let _file=&idir./&_base..&fmt;
	%else 														%let _file=&idir./&_fn;

	/* IFN: check parameter */
	%if %error_handle(ErrorInputFile, 
		%file_check(&_file) EQ 1, mac=&_mac,	
		txt=%quote(!!! File %upcase(&_file) does not exist !!!)) %then
	%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local dsn
		quantiles;
	%let dsn=TMp&_mac;

	PROC IMPORT DATAFILE="&file" OUT=WORK.&_base REPLACE 
		DBMS=&fmt;
		GETNAMES=no;
		/* MIXED = yes; /* works only on Windows system (http://support.sas.com/kb/32/619.html) */
	quit;
	
	/* note that there may be an issue occurs when the file has been created on a Windows
	* PC and SAS is running on Unix/Linux. 
	* One difference between both operating systems is the newline char. While Windows uses 
	* Carriage Return and Line Feed, the *nix-systems use only one of the chars. The problem 
	* can be solved by using dos2unix in the shell of the unix-box to transform the newline 
	* chars. */

	%let quantiles=;
	%quantile(VAR2, probs=&probs, _quantiles_=quantiles, type=&type, idsn=&dsn, ilib=WORK, method=&method);

	%work_clean(&dsn); 

	%exit:
	&quantiles
%mend quantileTest;


/** \endcond */
