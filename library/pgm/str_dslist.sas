/** 
## str_dslist {#sas_str_dslist}

NOOOOOOOOOOOOOOOOOO - look at [%ds_check](@ref sas_ds_check)

Trim a list of strings to keep only those that actually define existing datasets in a given
library.

	%str_dslist(dsn, _dslst_=, lib=WORK);

### Arguments
* `dsn` : (list of) reference dataset(s);
* `lib` : (_option_) name of the input library; by default: `WORK` is used.

### Returns
`_dslst_` : name of the macro variable used to store the elements from `var` that actually
	define existing variables/fields in `dsn`. 

### Example
Let us generate some default datasets in `WORK`ing directory:

	%_dstest1;
	%_dstest2;
	%_dstest5;

we can then retrieve those elements in a given list that actually correspond to existing  
datasets in `WORK`:

	%let ds=;
	%let ids= _dstest1 dummy1 _dstest2 dummy2 _dstest5;
	%str_dslist(&ids, _dslst_=ds, lib=WORK);

returns `ods=_dstest1 _dstest2 _dstest5`.

Run macro `%%_example_str_listds` for more examples.

### Note
1. The order of the variables in the output list matches that in the input list `dsn`.
2. When none of the string elements in `dsn` matches a dataset in `lib`, an empty list is set. 

### See also
[%str_varlist](@ref sas_str_varlist), [%ds_check](@ref sas_ds_check).
*/ /** \cond */

%macro str_dslist(dsn		/* (list of) input reference dataset(s)	(REQ) */
				, _dslst_= 	/* Output list of updated datasets  	(REQ) */
				, lib=		/* Name of the input library 			(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	/* check that the output macro variable is set */
	%if %error_handle(ErrorInputParameter, 
				%macro_isblank(_dslst_) EQ 1, mac=&_mac,		
				txt=!!! Output parameter _DSLST_ not set !!!) %then
		%goto exit;

    %if %macro_isblank(lib) %then %let lib=WORK;

	%if %error_handle(ErrorInputLibrary, 
			%lib_check(&lib) NE 0, mac=&_mac,		
			txt=!!! Input library %upcase(&lib) not found !!!) %then
		%goto exit;

	%local _i	/* loop increment */
		SEP		/* arbirtrary list separator */
		_numds	/* list of existing datasets returned in output */
		_ds 	/* scanned input */
		_dslst; /* returned output */
	%let _dslst=;
	%let _numds=%list_length(&dsn);
	%let SEP=%str( );

	%do _i=1 %to &_numds;
		%let _ds=%scan(&dsn, &_i, &SEP);
		/* %if %error_handle(WarningInputParameter, 
				%var_check(&dsn, &_var, lib=&lib) EQ 1, mac=&_mac,		
				txt=! Variable %upcase(&_var) does not exist in dataset %upcase(&dsn) !, 
				verb=warn) %then %goto next; */
		%if %ds_check(&_ds, lib=&lib) EQ 0 %then %do;
			%if %macro_isblank(_dslst) %then
				%let _dslst=&_ds;
			%else
				%let _dslst=&_dslst.&SEP&_ds;
		%end;
	%end;

	%if %error_handle(WarningInputParameter, 
			%macro_isblank(_dslst) EQ 1, mac=&_mac,		
			txt=!!! No string in %upcase(&dsn) matches an existing dataset !!!) %then  
		%goto exit; 

	data _null_;
		call symput("&_dslst_","&_dslst");
	run;

	%exit:
%mend str_dslist;



%macro str_dsvar(var, ds=, _dslst_=, _var_= );
	%local _mac;
	%let _mac=&sysmacroname;
	%local _pos
		_ds 
		_var;

	%if %error_handle(ErrorInputParameter, 
				%macro_isblank(ds) EQ 1 and %macro_isblank(_dslst_) EQ 1 and %macro_isblank(_var_) EQ 1, mac=&_mac,		
				txt=!!! Output parameter _DSLST_ not set !!!) %then
		%goto exit;

	%if not %macro_isblank(ds) %then %do;
		%let _var=&ds..%list_quote(&var, mark=_EMPTY_, sep=%str( ), rep=%str(, &ds..));
		%goto quit;
	%end;
	%else %do;
		%let _pos=%index(&var, .);
		%let _ds=%substr(&var, 1, %eval(&_pos - 1));
		%let _var=%substr(&var, %eval(&_pos+1));
		
		data _null_;
			%if not %macro_isblank(_dslst_) %then %do;
				call symput("&_dslst_","&_ds");
			%end;
			%if not %macro_isblank(_var_) %then %do;
				call symput("&_var_","&_var");
			%end;
		run;
		%goto exit;
	%end;

	%quit:
	&_var

	%exit:
%mend;
%let ovar=;
%let ds=DSN;
%let vars=a b c d;
%put var=%str_dsvar(&vars, ds=&ds);
%let var=DSN.a;
%str_dsvar(&var, _dslst_=ds, _var_=var);
%put var=&var ds=&ds;

%macro str_libds(ds, lib=, _lib_=, _dslst_=);
	&lib..%list_quote(&ds, mark=_EMPTY_, sep=%str( ), rep=%str(, &lib..))
%mend;
%let ds=DSN;
%let vars=a b c d;
%put %str_dsvar(&ds, &vars);



%macro _example_str_dslist;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ids ds ods;
	%let ds=;

	/* create temporary datasets */
	%_dstest1;
	%_dstest2;
	%_dstest5;

	%let lib=WORK;
	%let ids=dummy1 dummy2;
	%put;
	%put (i) Dummy test in WORKing library;
	%str_dslist(&ids, _ds_=ds, lib=&lib);
	%if %macro_isblank(ds) %then 	%put OK: TEST PASSED - Dummy test returns: no output;
	%else 							%put ERROR: TEST FAILED - Wrong dummy result returned: %upcase(&ds);

	%let ids= _dstest1 dummy1 _dstest2 dummy2 _dstest5;
	%put;
	%put (ii) Check datasets %upcase(&ids) in WORKing library;
	%let ods=_dstest1 _dstest2 _dstest5;
	%str_dslist(&ids, _ds_=ds, lib=&lib);
	%if %quote(&ds) EQ %quote(&ods) %then 	%put OK: TEST PASSED - Test returns: %upcase(&ods);
	%else 									%put ERROR: TEST FAILED - Wrong result returned: %upcase(&ds);

	%work_clean(_dstest1, _dstest2, _dstest5);
%mend _example_str_dslist;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_str_dslist;
*/

/** \endcond */

