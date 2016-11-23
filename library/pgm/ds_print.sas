/** 
## ds_print {#sas_ds_print}
Simple print instruction for the (partial, total or "structural") display of a given dataset
using the `PROC PRINT` statement.

	%ds_print(dsn, lib=WORK, title=, head=, options=);

### Arguments
* `dsn` : a dataset reference;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `head` : (_option_) option set to the number of header observations (_i.e._, starting from 
	the first one) to display (useful for large datasets); default: `head` is not set and the 
	whole dataset is printed;
* `title` : (_option_) title of the printed table; default: `title=&dsn`, _i.e._ the name
	of the table is used;
* `options` : (_option_) list of options as normally accepted by `PROC PRINT`; use the `%quote` 
	macro to pass this parameter.
  
### Example
Print a test dataset in the `WORK` directory so that a blank line is inserted after every 2 
observations:

	%_dstest32;
	%ds_print(_dstest32, options=%quote(BLANKLINE=2));

Run macro `%%_example_ds_print` for more examples.

### Note
In the case the dataset exists but is empty (no observation), its structure will still be printed, 
i.e., the list of variables, their types and lengths will be displayed.
*/ /** \cond */

%macro ds_print(dsn			/* Input reference dataset 					(REQ) */
				, lib=		/* Name of the input library 				(OPT) */
				, head=		/* Number of observations to display		(OPT) */
				, title= 	/* Title of the graph						(OPT) */	
				, options=	/* Additional option(s) used by PROC PRINT 	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%if %macro_isblank(title) %then %let title=&dsn;
	%if %macro_isblank(head) %then	%let head=0;
 
	%if %error_handle(ErrorInputParameter, 
			%ds_check(&dsn, lib=&lib) NE 0, mac=&_mac, 
			txt=!!! Dataset %upcase(&dsn) not found !!!) 
			or
			%error_handle(ErrorInputParameter, 
				%par_check(&head, type=INTEGER, range=-1) NE 0, mac=&_mac, 
				txt=!!! Wrong size for header observations HEAD !!!) %then 
		%goto exit; 

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	%local ans _dsn;
	%let _dsn=_TMP&_mac;

	/* deal with the case of an empty table: we still want to print its structure */
	%ds_isempty(&dsn, _ans_=ans, lib=&lib);
	%if %error_handle(ErrorInputParameter, 
			&ans EQ 1, mac=&_mac, 
			txt=! Dataset %upcase(&dsn) is empty - Only structure is displayed !, verb=warn) %then 
		%goto print_structure;

	/* here is the (full or partial) display of the dataset */
	%print_contents:

	%if &head>0 %then %do;
		DATA &_dsn;
			SET &lib..&dsn;
			if _n_ <= &head;
		run;
	%end;
	%else 
		%let _dsn=&lib..&dsn;

	/* here is the main display (most of the case) */
	PROC PRINT DATA=&_dsn
		%if not %macro_isblank(options) %then %do;
			%unquote(&options)
		%end;	
		;
		TITLE &title;
	run;

	%if &head>0 %then %do;
		%work_clean(&_dsn);
	%end;

	%goto exit;

	/* here is the specific display for empty dataset */
	%print_structure:

	%local _tmp
		vars
		typs
		lens;
	%let _tmp=TMP_&_mac;

	%ds_contents(&dsn, _varlst_=vars, _lenlst_=lens, _typlst_=typs, lib=&lib);
	%if %macro_isblank(vars) %then
			%goto exit;
	DATA &_tmp;
		i=1;
		do while (scan("&vars",i) ne "");
			_variable_=scan("&vars",i);
			_type_=scan("&typs",i);
			_length_=scan("&lens",i);
			output;
			i + 1;
		end;
		drop i;
   	run;
	PROC PRINT DATA=&_tmp;
		TITLE %quote(EMPTY - &title);
	run;
	%work_clean(&_tmp);
	%goto exit; /* dummy useless */

	%exit:
%mend ds_print;

%macro _example_ds_print;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn;
	%let dsn=TMP%upcase(&sysmacroname);

	%put;
	%put (i) Try to print an empty dataset in WORK directory: _dstest0 (nothing printed);
	%_dstest0;
	%ds_print(_dstest0);

	%put;
	%put (ii) Create and display a dataset with no observation;
	PROC SQL noprint;
		CREATE TABLE &dsn(
			a num,
			b char(15),
			c num,
			d char(20)
			);
 	quit;
	%ds_print(&dsn);

	%put;
	%put (iii) Print a simple non-empty dataset in WORK directory: _dstest2;
	%_dstest2;
	%ds_print(_dstest2);

	%put;
	%put (iv) Print a simple dataset in WORK directory: _dstest32, inserting a blankline after every 2 observations;  
	%_dstest32;
	%ds_print(_dstest32, options=%quote(BLANKLINE=2));

	%put;

	/* clean your shit... */
	%work_clean(&dsn,_dstest0,_dstest2,_dstest32);
%mend _example_ds_print;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_print; 
*/

/** \endcond */
