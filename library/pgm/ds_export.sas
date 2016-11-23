/** 
## ds_export {#sas_ds_export}
Export (convert) a dataset to any format accepted by `PROC EXPORT`.

	%ds_export(ds, odir=, _ofn_=, fmt=csv, ilib=, delim=);

### Arguments
* `ds` : a dataset (_e.g._, a SAS file);
* `odir` : (_option_) output directory/library to store the converted dataset; by default,
	it is set to:
			+ the location of your project if you are using SAS EG (see [%egp_path](@ref sas_egp_path)),
			+ the path of `%sysget(SAS_EXECFILEPATH)` if you are running on a Windows server,
			+ the location of the library passed through `ilib` (_i.e._, `%sysfunc(pathname(&ilib))`) 
			otherwise;
* `fmt` : (_option_) format for export; it can be any format (_e.g._, `csv`) accepted by
	the DBMS key in `PROC EXPORT`; default: `fmt=csv`;
* `ilib` : (_option_) input library where the dataset is stored; by default, `WORK` is 
	selected as input library;
* `delim` : (_option_) delimiter; can be any argument accepted by the `DELIMITER` key in 
	`PROC EXPORT`; default: none is used.
 
### Returns
`_ofn_` : name (string) of the macro variable storing the output exported file name.

### Notes
1. In short, this macro runs:

	   PROC EXPORT DATA=&ilib..&idsn OUTFILE="&odir./&idsn..&fmt" REPLACE
		   DBMS=&fmt
		   DELIMITER=&delim;
	   quit;

2. There is no format/existence checking, hence if the output selected type `fmt` is the same
as the type of the input dataset, or if the output dataset already exists, a new dataset 
will be produced anyway. Please consider using the setting `G_PING_DEBUG=1` for checking beforehand
actually exporting.
3. In debug mode (_e.g._, `G_PING_DEBUG=1`), the import export is aborted; still it can checked
that the output file will be created with the correct name and location using the option 
`_ofn_`. Consider using this option for checking before actually exporting. 

### Example
Run macro `%%_example_ds_export` for examples.

### See also
[%ds_check](@ref sas_ds_check), [%file_import](@ref sas_file_import),
[EXPORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/a000393174.htm).
*/ /** \cond */

%macro ds_export(idsn		/* Input reference dataset 							(REQ) */
				, odir=		/* Full path of output directory 					(OPT) */
				, _ofn_=	/* Name of the variable storing the output filename (OPT) */
				, fmt=csv	/* Format of import 								(OPT) */
				, ilib=		/* Input  library 									(OPT) */
				, delim=	/* Any argument of DELIMITER key in PROC EXPORT 	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
	
	%local DEBUG; /* boolean flag used for debug mode */
	%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else								%let DEBUG=0;

	%local _file; /* full path of the output file */
	%let _file=;

	/* default setting and checking ilib */
	%if %macro_isblank(ilib) %then 		%let ilib=WORK;
	%if %error_handle(ErrorInputParameter, 
			%lib_check(&ilib) NE 0, mac=&_mac,		
			txt=%quote(!!! Input library %upcase(&ilib) does not exist !!!)) %then
		%goto exit;

	/* default setting and checking odir */
	%if %macro_isblank(odir) %then %do; 
		%if %symexist(_SASSERVERNAME) %then /* working with SAS EG */
			%let odir=&G_PING_ROOTPATH/%_egp_path(path=drive);
		%else %if &sysscp = WIN %then %do; 	/* working on Windows server */
			%let odir=%sysget(SAS_EXECFILEPATH);
			%if not %macro_isblank(odir) %then
				%let odir=%qsubstr(&odir, 1, %length(&odir)-%length(%sysget(SAS_EXECFILENAME));
		%end;
		%if %macro_isblank(odir) %then
			%let odir=%sysfunc(pathname(&ilib));
	%end;
	%if %error_handle(ErrorInputParameter, 
			%dir_check(&odir) NE 0, mac=&_mac,		
			txt=%quote(!!! Output directory %upcase(&odir) does not exist !!!)) %then
		%goto exit;

	/* set the full output file path */
	%let _file=&odir./&idsn..&fmt;

	%if &DEBUG=1 %then 
		%goto quit;
	
	/* waring if it exists already... process anyway */
	%if %error_handle(WarningOutputFile, 
			%file_check(&_file) EQ 0, mac=&_mac,		
			txt=%quote(! Output file %upcase(&_file) already exist - Will be overwritten !), verb=warn) %then
		%goto warning;
	%warning:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	PROC EXPORT DATA=&ilib..&idsn OUTFILE="&_file" REPLACE
		DBMS=&fmt
		%if not %macro_isblank(delim) %then %do;
			 DELIMITER=&delim
		%end;
		;
	quit;

	%quit:
	%if not %macro_isblank(_ofn_) %then %do;
		data _null_;
			call symput("&_ofn_","&_file");
		run;
	%end;

	%exit:
%mend ds_export;

%macro _example_ds_export;
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

	%local curdir ilib fmt oname;
	%let fname=;
	%if %symexist(_SASSERVERNAME) %then /* e.g.: you are running on SAS EG */
		%let curdir=&G_PING_ROOTPATH/%_egp_path(path=drive);
	%else
		%let odir=&G_PING_LIBDATA;

	%_dstest36;
	%*ds_print(_dstest36);

	%let ilib=WORK;
	%let fmt=csv;
	%let odir=%sysfunc(pathname(&ilib));
	%put;
	%put (i) Convert _dstest36 dataset into &fmt format and save it to WORK directory;
	%let resname=&odir/_dstest36.&fmt;
	%ds_export(_dstest36, ilib=&ilib, odir=&odir, _ofn_=fname, fmt=&fmt);
	%if "&fname"="&resname" %then 	%put OK: TEST PASSED - Expected &fname shall be created;
	%else 							%put ERROR: TEST FAILED - Wrong &fname would be created;

	%let ilib=&G_PING_LIBCFG;
	%_dstest36(lib=&ilib);

	%put;
	%put (ii) Convert test dataset into &fmt format and save it to default directory;
	%let resname=&curdir/_dstest36.&fmt;
	%ds_export(_dstest36, ilib=&ilib, _ofn_=fname, fmt=&fmt);
	%if "&fname"="&resname" %then 	%put OK: TEST PASSED - Expected file &fname shall be created;
	%else 							%put ERROR: TEST FAILED - Wrong file &fname would be created;
	
	%let odir=&G_PING_LIBCONFIG;
	%let fmt=xls;
	%put;
	%put (iii) Convert test dataset into &fmt format and save it to &odir directory;
	%let resname=&G_PING_LIBCONFIG/_dstest36.&fmt;
	%ds_export(_dstest36, ilib=&ilib, odir=&odir, _ofn_=fname, fmt=&fmt);
	%if "&fname"="&resname" %then 	%put OK: TEST PASSED - Expected file &fname shall be created;
	%else 							%put ERROR: TEST FAILED - Wrong file &fname would be created;

	/* reset the debug as it was (if it ever was set) */
	%let G_PING_DEBUG=&olddebug;

	%put;

	%work_clean(_dstest36);
	PROC DATASETS lib=&ilib nolist; delete _dstest36; quit; 
%mend _example_ds_export;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_export; 
*/

/** \endcond */
