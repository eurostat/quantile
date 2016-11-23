/** 
## ds_check {#sas_ds_check}
* Check the existence of a dataset in a given library. 

      %let ans=%ds_check(dsn, lib=WORK);
* Trim a list of string elements to keep only those that actually define existing datasets in a given library.

      %ds_check(dsn, _dslst_=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
* `ans` : (_option_) the error code of the test, _i.e._:
		+ `-1` when the library does not exist,
		+ `0` if the dataset exists,
    	+ `1` (error: "dsn does not exist") otherwise.
	
	should not be used contemporaneously with the option `_dslst_` below;
* `_dslst_` : (_option_) name of the macro variable used to store the elements from `var` that actually
	define existing variables/fields in `dsn`; incompatible with returned result `ans` above. 

### Examples
Let us consider a non-empty dataset:
	
	%_dstest0;
	%let ans=%ds_check(_dstest0, lib=WORK);

returns `ans=0`. Let us then generate some datasets in `WORK`ing directory:

	%_dstest1;
	%_dstest2;
	%_dstest5;

we can then also use the macro to retrieve those elements in a given list that actually correspond 
to existing  datasets in `WORK`:

	%let ds=;
	%let ids= _dstest1 dummy1 _dstest2 dummy2 _dstest5;
	%ds_check(&ids, _dslst_=ds, lib=WORK);

returns `ods=_dstest1 _dstest2 _dstest5`.

Run macro `%%_example_ds_check` for examples.

### Notes
1. As mentioned above, two types of outputs are possible: either the answer `ans` to the test when
a result shall be returned (and `_dslst_` is not passed), or an updated list of acceptable datasets
(when `_dslst_` is passed). The former case is useful when testing a single dataset existence in a 
library, the latter for triming a list of actual datasets. Contemporaneous use is impossible.
2. In short, the error code returned (when `_dslst_` is not passed) is the evaluation of:

	   1 - %sysfunc(exist(&lib..&dsn, data));
3. The order of the variables in the output list matches that in the input list `dsn`.
4. When none of the string elements in `dsn` matches a dataset in `lib`, an empty list is set. 

### References
1. SAS support: ["Determine if a data set exists"](http://support.sas.com/kb/24/670.html).
2. Johnson, J. (2010): ["OBJECT_EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check),
[%ds_contents](@ref sas_ds_contents), 
[EXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210903.htm).
*/ /** \cond */

%macro ds_check(dsn 		/* Input dataset 					(REQ) */
				, _dslst_= 	/* Output list of updated datasets  (REQ) */
				, lib=		/* Output library 					(OPT) */
				, verb= 	/* Legacy parameter - Ignored 		(OBS) */
				); 
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac); /* avoid conflict with returned value (see __ans below) */

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local __ans;	/* output answer */		

    %if %macro_isblank(lib) %then %let lib=WORK;

	%if /*%error_handle(ErrorInputParameter, 
			%macro_isblank(dsn) NE 0, mac=&_mac,		
			txt=!!! Input parameter DSN not set !!!)
			or */ %error_handle(ErrorInputLibrary, 
				%lib_check(&lib) NE 0, mac=&_mac,		
				txt=!!! Input library %upcase(&lib) not found !!!) %then %do;
		%let __ans=-1;
		%goto quit;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i		/* loop increment */
		SEP			/* arbirtrary list separator */
		_ds 		/* scanned input dataset */
		__dslst; 	/* list of existing datasets returned output */
	%let SEP=%str( );
	%let __dslst=;

	%do _i=1 %to %list_length(&dsn);
		%let _ds=%scan(&dsn, &_i, &SEP);
		%if %sysfunc(exist(&lib..&_ds, data)) or %sysfunc(exist(&lib..&_ds,view)) %then %do;
			%if %macro_isblank(__ans) %then 	%let __ans=0;
			%else								%let __ans=&__ans.&SEP.0;
			%if %macro_isblank(__dslst) %then 	%let __dslst=&_ds;
			%else								%let __dslst=&__dslst.&SEP.&_ds;
		%end;
		%else %do;
			%if %macro_isblank(__ans) %then 	%let __ans=1;
			%else								%let __ans=&__ans.&SEP.1;
		%end;
	%end;

	/* either update the list of datasets ... */
	%if not %macro_isblank(_dslst_) %then %do;
		%if not %error_handle(WarningOututParameter, 
				%macro_isblank(__dslst) EQ 1, mac=&_mac,		
				txt=%quote(! No string in %upcase(&dsn) matches a dataset in %upcase(&lib) !), 
				verb=warn) 
		%then %do;
			data _null_;
				call symput("&_dslst_","&__dslst");
			run;
		%end;
		/* %let &_dslst_=&_ds; */
		%goto exit;
	%end;
	
	%quit:
	/* ... or return the answer */
	&__ans

	%exit:
%mend ds_check;

%macro _example_ds_check;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	libname rdb "&G_PING_C_RDB"; 
	libname rdb2 "&G_PING_C_RDB2"; 

	%local ids ds ods;

	%put;
	%put (i) Invoke the macro, pass a non-existent data set name to test...;
	%put A%ds_check(not_there, lib=sasuser)A;
	%if %ds_check(not_there, lib=sasuser) %then %put OK: TEST PASSED - Unknown dataset unidentified: errcode 1;
	%else 										%put ERROR: TEST FAILED - Unknown dataset identified: errcode 0;

	%put;
	%put (ii) Test an empty table (missing observation) in WORK: _dstest0...;
	%_dstest0;
	%if %ds_check(_dstest0, lib=WORK) %then %put ERROR: TEST FAILED - Test dataset unidentified: errcode 1;
	%else 									%put OK: TEST PASSED - Test dataset identified dataset: errcode 0;

	%put;
	%put (iii) Test a table in WORK with one observation only: _dstest2...;  
	%_dstest2;
	%if %ds_check(_dstest2, lib=WORK) %then %put ERROR: TEST FAILED - Test dataset unidentified: errcode 1;
	%else 									%put OK: TEST PASSED - Test dataset identified dataset: errcode 0;

	/* create temporary datasets */
	%_dstest1;
	%_dstest5;

	%let ds=;
	%let lib=WORK;
	%let ids=dummy1 dummy2;
	%put;
	%put (iv) Dummy test of list of datasets %upcase(&ids) in WORKing library;
	%ds_check(&ids, _dslst_=ds, lib=&lib);
	%if %macro_isblank(ds) %then 	%put OK: TEST PASSED - Dummy test returns: no output;
	%else 							%put ERROR: TEST FAILED - Wrong dummy result returned: %upcase(&ds);

	%let ids= _dstest1 dummy1 _dstest2 dummy2 _dstest5;
	%put;
	%put (v) Update the list of datasets %upcase(&ids) in WORKing library;
	%let ods=_dstest1 _dstest2 _dstest5;
	%ds_check(&ids, _dslst_=ds, lib=&lib);
	%if %quote(&ds) EQ %quote(&ods) %then 	%put OK: TEST PASSED - Test returns: %upcase(&ods);
	%else 									%put ERROR: TEST FAILED - Wrong result returned: %upcase(&ds);

	%if %symexist(EUSILC) %then %do;
		%put;
		%put (vi) What about one of our database, for instance DI01 in rdb...?;
		%if %ds_check(DI01, lib=rdb) %then 		%put ERROR: TEST FAILED - Existing dataset DI01: errcode 1;
		%else 									%put OK: TEST PASSED - Existing dataset DI01: errcode 0;

		%put;
		%put (vii) However, for DI264 in rdb...;
		%if %ds_check(DI01, lib=rdb2) %then 	%put OK: TEST PASSED - Unknown library rdb2 for DI01: errcode 1;
		%else 									%put ERROR: TEST FAILED - Unknown library rdb2 for DI01: errcode 0;
	%end;

	%put;

	%work_clean(_dstest0, _dstest1, _dstest2, _dstest5);
%mend _example_ds_check;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_check; 
*/

/** \endcond */
