/** 
## ds_sort {#sas_ds_sort}
Sort the observations in a given dataset.

	%ds_sort(idsn, odsn=, asc=, desc=, dupout=, sortseq=, options=, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : a dataset reference;
* `odsn` : (_option_) name of the output dataset (in `WORK` library); when not set, the input
	dataset `idsn` is replaced with the newly sorted version; default: not set;
* `asc` : (_option_) list of variables to consider so as to sort `idsn` in ascending order; default:
	not set;
* `desc` : (_option_) list of variables to consider so as to sort `idsn` in ascending order; default:
	not set; note however that `asc` and `desc` cannot be both empty;
* `dupout` : (_option_) name of the `DUPOUT` file, _i.e._ all deleted observations, if any, will
	be put in this dataset (in `WORK` library); default: not used;
* `sortseq` : (_option_) option used by the `PROC SORT` procedure so as to change the sorting order
	of character variables; default: not used;
* `options` : (_option_) any additional options accepted by the `PROC SORT` procedure;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` is used.
  
### Returns
In either `odsn` or `idsn` (updated when the former is not passed), the original dataset sorted by
(ascending) `asc` variables and descending `desc` variables.

### Examples
Let us consider the test dataset #35:
geo | time | EQ_INC20 | RB050a
----|------|----------|-------
 BE | 2009 |    10    |   10 
 BE | 2010 |    50    |   10
 BE | 2011 |    60    |   10
 BE | 2012 |    20    |   20
 BE | 2013 |    10    |   20
 BE | 2014 |    30    |   20
 BE | 2015 |    40    |   20
 IT | 2009 |    10    |   10
 IT | 2010 |    50    |   10
 IT | 2011 |    50    |   10
 IT | 2012 |    30    |   20
 IT | 2013 |    30    |   20
 IT | 2014 |    20    |   20
 IT | 2015 |    50    |   20

and run the macro:
	
	%_dstest35;
	%ds_sort(_dstest35, asc=time, desc=eq_inc20 rb050a);

which updates _dstest35 with the following table:
geo | time | EQ_INC20 | RB050a
----|------|----------|-------
 BE	| 2009 | 	10	  |  10
 IT	| 2009 | 	10	  |  10
 BE	| 2010 | 	50	  |  10 
 IT	| 2010 | 	50	  |  10
 BE	| 2011 | 	60	  |  10
 IT	| 2011 | 	50	  |  10
 IT	| 2012 | 	30	  |  20
 BE	| 2012 | 	20	  |  20
 IT	| 2013 | 	30	  |  20
 BE	| 2013 | 	10	  |  20
 BE	| 2014 | 	30	  |  20
 IT	| 2014 | 	20	  |  20
 IT	| 2015 | 	50	  |  20
 BE	| 2015 | 	40	  |  20 

Run macro `%%_example_ds_sort` for more examples.

### Notes
1. In short, the macro runs the following `PROC SORT` procedure:

	   PROC SORT DATA=&ilib..&idsn 
		   OUT=&olib..&odsn
		   DUPOUT=&dupout
		   &options;
		   BY &asc DESCENDING &desc;
	   run;
2. In debug mode (_e.g._, `G_PING_DEBUG=1`), the macro is used to return a string:

		%let proc=%ds_sort( ... );

where `proc` is the procedure that launches the operation (see above), and while the actual operation 
is actually not ran. Further note that in the case the variable G_PING_DEBUG` is not defined in your 
environment, debug mode is ignored (_i.e._, by default the operation is ran).

### References
1. Bassett, B.K. (2006): ["The SORT procedure: Beyond the basics"](http://www2.sas.com/proceedings/sugi31/030-31.pdf).
2. Fickbohm, D. (2007): ["The SORT procedure: Beyond the basics"](http://www.lexjansen.com/wuss/2007/ApplicationsDevelopment/APP_Fickbaum_SortPrcedure.pdf).
3. Cherny, M. (2015): ["Getting the most out of PROC SORT: A review of its advanced options"](http://www.pharmasug.org/proceedings/2015/QT/PharmaSUG-2015-QT14.pdf).

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check),
[SORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000057941.htm).
*/ /** \cond */

%macro ds_sort(idsn		/* Input reference dataset 									(REQ) */
			, odsn=		/* Output dataset 											(OPT) */
			, asc=		/* (List of) variable(s) to consider for ascending sorting 	(OPT) */
			, desc=		/* (List of) variable(s) to consider for descending sorting (OPT) */
			, dupout=	/* Name of the DUPOUT file used by PROC SORT 				(OPT) */
			, sortseq=	/* Option used by PROC SORT to change the sorting order		(OPT) */
			, options=	/* Additional option(s) used by PROC SORT					(OPT) */
			, ilib=		/* Name of the input library 								(OPT) */
			, olib=		/* Name of the output library 								(OPT) */
			);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local DEBUG; /* boolean flag used for debug mode */
	%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else							%let DEBUG=0;

	%local _i		/* loop increment */
		_asclen 	/* number of variables used for ascending sorting */
		_desclen 	/* number of variables used for descending sorting  */
		_var		/* temporary scanned variable */
		SEP;		/* arbitrary list separator */
	%let _asclen=0;
	%let _desclen=0;
	%let SEP=%str( );

	%if %error_handle(WarningOutputDataset, 
			%macro_isblank(odsn) EQ 1 and %macro_isblank(olib) EQ 0, mac=&_mac,		
			txt=%quote(! Ignored output library %upcase(&olib) since ODSN not set !),
			verb=warn) %then
		%goto warning;
	%warning: /* nothing in fact: just proceed... */

	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	%if %macro_isblank(olib) %then 	%let olib=&ilib;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* check variables used for sorting */
	%if not %macro_isblank(asc) %then %do;
		%let _asclen=%list_length(&asc, sep=&SEP);
		%do _i=1 %to &_asclen;
			%let _var=%scan(&asc, &_i, &SEP);
			%if %error_handle(ErrorInputParameter, 
					%var_check(&idsn, &_var, lib=&ilib) EQ 1, mac=&_mac,		
					txt=%quote(!!! Variable %upcase(&_var) does not exist in dataset %upcase(&idsn) !!!)) %then
				%goto exit;
		%end;
	%end;

	%if not %macro_isblank(desc) %then %do;
		%let _desclen=%list_length(&desc, sep=&SEP);
		%do _i=1 %to &_desclen;
			%let _var=%scan(&desc, &_i, &SEP);
			%if %error_handle(ErrorInputParameter, 
					%var_check(&idsn, &_var, lib=&ilib) EQ 1, mac=&_mac,	
					txt=%quote(!!! Variable %upcase(&_var) does not exist in dataset %upcase(&idsn) !!!)) %then
				%goto exit;
		%end;
	%end;	

	/* check that indeed some variables were passed for sorting */
	%if %error_handle(ErrorInputParameter, 
			%eval(&_asclen + &_desclen) EQ 0, mac=&_mac,		
			txt=!!! No variable selected for sorting !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	
	/* update the variables for descending order */
	%if &_desclen>0 %then %do;
		%local KEYDESC;
		%let KEYDESC=;
		%do _i=1 %to &_desclen;
			%let KEYDESC=&KEYDESC DESCENDING;
		%end;
		%let desc=%list_append(&KEYDESC, &desc, zip=yes, sep=&SEP);
	%end;		

	%if &DEBUG=1 %then 
		%goto print;

	/* actual sort */
	PROC SORT DATA=&ilib..&idsn 
		%if not %macro_isblank(odsn) %then %do;
			OUT=&olib..&odsn
		%end;
		%if not %macro_isblank(dupout) %then %do;
			NODUPKEY DUPOUT=&dupout
		%end;
		%if not %macro_isblank(sortseq) %then %do;
			SORTSEQ &sortseq
		%end;
		%if not %macro_isblank(options) %then %do;
			&options
		%end;
		;
		BY 
		%if &_asclen>0 %then %do;
			&asc
		%end;
		%if &_desclen>0 %then %do;
			&desc
		%end;
		;
	run;
	%goto exit;

	%print:
	/* debug option: we reproduce hereby the code for the SQL procedure that otherwise appears 
	* below; not very elegant, but that's it... */
	%local _proc;
	/* we build the PROC string */			%let _proc=%str(PROC SORT DATA=&ilib..&idsn);
	%if not %macro_isblank(odsn) %then 		%let _proc=&_proc.%str( OUT=&olib..&odsn);
	%if not %macro_isblank(dupout) %then	%let _proc=&_proc.%str( NODUPKEY DUPOUT=&dupout);
	%if not %macro_isblank(sortseq) %then 	%let _proc=&_proc.%str( SORTSEQ &sortseq);
	%if not %macro_isblank(options) %then	%let _proc=&_proc.%str( &options);
											%let _proc=&_proc.%str( ; BY ); 
	%if &_asclen>0 %then 					%let _proc=&_proc.%str( &asc);
	%if &_desclen>0 %then 					%let _proc=&_proc.%str( &desc);
											%let _proc=&_proc.%str(; run;);
	/* we return this string for debug */
	&_proc

	%exit:
%mend ds_sort;

%macro _example_ds_sort;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local olddebug;
	/* set the debug option to the highest level (1) */
	%if %symexist(G_PING_DEBUG) %then 	%let olddebug=&G_PING_DEBUG;
	%else %do;
		%global G_PING_DEBUG;
		%let olddebug=0;
	%end;

	%local dsn asc desc;
	%let dsn=TMP%upcase(&sysmacroname);
		
	%let G_PING_DEBUG=1;

	%let asc=time;
	%let desc=eq_inc20 rb050a;
	%put (i) Retrieve the sort procedure on test table #35;
	%let oproc=%str(PROC SORT DATA=WORK._dstest35 OUT=WORK.TMP_EXAMPLE_DS_SORT ; BY  time  DESCENDING eq_inc20 DESCENDING rb050a; run;);
	%put %str( 	*) parameters used are:;
	%put %str(	        ) asc=&asc;
	%put %str(	        ) desc=&desc;
	%put %str( 	*) desired output is:;
	%put %str(	        ) &oproc;
	%put;
	%_dstest35;
	%let proc=%ds_sort(_dstest35, odsn=&dsn, asc=&asc, desc=&desc);
	%if "&proc" = "&oproc" %then 	%put OK: TEST PASSED - Correct SORT procedure implemented on _dstest35;
	%else 							%put ERROR: TEST FAILED - Wrong SORT procedure implemented on _dstest35;

	%let G_PING_DEBUG=&olddebug;

	%put (ii) Actually sort the table on variables %upcase(&asc) and descending variables %upcase(&desc);
	%ds_sort(_dstest35, odsn=&dsn, asc=&asc, desc=&desc);
	%ds_print(&dsn);

	%let asc=geo;
	%let desc=eq_inc20;
	%put (iii) Sort and update the test table #35 on variables %upcase(&asc) and descending variables %upcase(&desc) while eliminating duplicates;
	%ds_sort(_dstest35, dupout=&dsn, asc=&asc, desc=&desc);
	%ds_print(_dstest35);
	%ds_print(&dsn);

	%put;

	%work_clean(&dsn,_dstest35);
%mend _example_ds_sort;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_sort; 
*/

/** \endcond */
