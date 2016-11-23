/** 
## file_import {#sas_file_import}
Import (convert) a file from any format accepted by `PROC IMPORT` into a SAS dataset.

	%file_import(ifn, idir=, fmt=csv, _ods_=, olib=, getnames=yes);

### Arguments
* `ifn` : file name to import;
* `fmt` : (_option_) format for import, _i.e._ extension of the input file; it can be any format 
	(_e.g._, csv) accepted by the DBMS key in `PROC import`;
* `idir` : (_option_) input directory where the file is stored; default: the current location
	of the file
* `olib` : (_option_) output  library where the dataset will be stored; by default, `olib=WORK` 
    is selected as output library;
* `getnames` : boolean flag (`yes/no`) set to import the variable names; default: `getnames=yes`.
 
### Returns
`_ods_` : (_option_) name (string) of the macro variable storing the name of the output dataset.
 
### Notes
1. There is no format/existence checking, hence if the output selected type is the same as 
the type of the input dataset, or if the output dataset already exists, a new dataset will be 
produced anyway. If the `REPLACE` option is not specified, the `PROC IMPORT` procedure does 
not overwrite an existing data set.
2. In debug mode (_e.g._, `G_PING_DEBUG=1`), the import process is aborted; still it can checked
that the output dataset will be created with the correct name and location using the option 
`_ods_`. Consider using this option for checking before actually importing. 

### Example
Run macro `%%_example_file_import` for examples.

### Note
Variable names should be alphanumeric strings, not numeric values (otherwise converted).

### See also
[%ds_export](@ref sas_ds_export), [%file_check](@ref sas_file_check),
[IMPORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000308090.htm).
*/ /** \cond */
	
%macro file_import(ifn			/* Input filename 					(REQ) */
				, idir=			/* Full path of input directory 	(OPT) */
				, fmt=csv		/* Format of import 				(OPT) */
				, _ods_=		/* Name of the output dataset 		(OPT) */
				, olib=			/* Output  library 					(OPT) */
				, getnames=yes	/* Boolean flag set to get names 	(OPT) */
				);
 	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local DEBUG; /* boolean flag used for debug mode */
	%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else							%let DEBUG=0;
	
	%if %macro_isblank(olib) %then 	%let olib=WORK;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _file 	/* full path of the input file */
		_dir 		/* name of the input file directory */
		_base 		/* basename of the input file */
		_ext		/* extension of the input file */
		_fn			/* filename of the input file without its directory path if any */
		isbl_idir 	/* test of existence of input directory parameter */
		isbl_dir; 	/* test of existence of directory in input filename */
	%let _file=&ifn;

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
			%let idir=&G_PING_ROOTPATH/%egp_path(path=drive);
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
		
	%if %error_handle(ErrorInputParameter, 
			%dir_check(&idir) NE 0, mac=&_mac,		
			txt=%quote(!!! Input directory %upcase(&idir) does not exist !!!)) %then
		%goto exit;

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

	%if %error_handle(ErrorInputFile, 
		%file_check(&_file) EQ 1, mac=&_mac,	
		txt=%quote(!!! File %upcase(&_file) does not exist !!!)) %then
	%goto exit;

	%if &DEBUG=1 %then 
		%goto quit;

	PROC IMPORT DATAFILE="&_file" OUT=&olib..&_base REPLACE
		DBMS=&fmt;
		GETNAMES=&getnames;
	quit;

	%quit:
	%if not %macro_isblank(_ods_) %then %do;
		data _null_;
			call symput("&_ods_","&olib..&_base");
		run;
	%end;

	%exit:
%mend file_import;

%macro _example_file_import;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/* we currently launch this example in the highest level (1) of debug only */
	%if %symexist(G_PING_DEBUG) %then 	%let olddebug=&G_PING_DEBUG;
	%else %do;
		%global G_PING_DEBUG;
		%let olddebug=0;
	%end;
	%let G_PING_DEBUG=1;

	%let ds=;
	
	%let idir=&G_PING_LIBDATA; 
	%let ifn=INDICATOR_CODES_RDB2;
	%let type=csv;
	%put;
	%put (i) Convert csv file (&ifn) from &idir folder into WORK library;
	%file_import(&ifn, idir=&idir, fmt=&type, _ods_=ds, getnames=yes);
	%if "&ds"="WORK.&ifn" %then %put OK: TEST PASSED - Expected &ds shall be created;
	%else 										%put ERROR: TEST FAILED - Wrong &ds would be created;

	%put;
	%let LIBCFG=&G_PING_LIBCFG;
	%put (ii) Convert csv file (&ifn) from &idir folder into &LIBCFG library;
	%file_import(&ifn, idir=&idir, fmt=&type, _ods_=ds, getnames=yes, olib=&LIBCFG);
	%if "&ds"="LIBCFG.&ifn" %then %put OK: TEST PASSED - Expected &ds shall be created;
	%else 										%put ERROR: TEST FAILED - Wrong &ds would be created;

	%let ifn=COUNTRY_INDICATORS;
	%put;
	%put (iii) Load and import a csv file (&ifn) into WORK library;
	%file_import(&ifn, idir=&idir, fmt=&type, _ods_=ds, getnames=yes);
	%if "&ds"="WORK.&ifn" %then %put OK: TEST PASSED - Expected &ds shall be created;
	%else 										%put ERROR: TEST FAILED - Wrong &ds would be created;

	/* reset the debug as it was (if it ever was set) */
	%let G_PING_DEBUG=&olddebug;

	%put;

%mend _example_file_import;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_file_import; 
*/

/** \endcond */
