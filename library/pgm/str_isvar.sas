/**
## str_isvar {#sas_str_isvar}
Define if a (list of) string(s) actually define variables in a given dataset.

	%str_isvar(dsn, var, _ans_=, _var_=, lib=WORK, sep=%str( ));

### Arguments
* `dsn` : a reference dataset;
* `var` : list of string elements to be from the dataset when they exist;
* `lib` : (_option_) name of the input library; by default: `WORK` is used;
* `sep` : (_option_) character/string separator in input `var` list; default: `%%str( )`, _i.e._ 
	`sep` is blank.

### Returns
* `_ans_` : (_option_) name of the macro variable storing the list of same length as `var` where the
	i-th item provides the answer of the test above for the i-th item in `var`, _i.e._:
		+ `1` if it is the name of a variable in `var`,
		+ `0` if not;
	either this option or the next one (`_var_`) must be set so as to run the macro;
* `_var_` : (_option_) name of the macro variable storing the updated list from which all elements 
	that do not macth existing variables/fields in `dsn` have been removed. 

### Example
Let us consider the table `_dstest5`:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
then:

	%let var=a b y z c;
	%let ans=;
	%let list=;
	%str_isvar(_dstest5, &var, _ans_=ans, _var_=list);

returns `ans=1 1 0 0 1` and `list=a b c`, the only string elements of `var` which define variables 
in `_dstest5`.

Run macro `%%_example_str_isvar` for more examples.

### Note
1. In short, this macro "intersects" the list `var` with the list of variables in `dsn`, _i.e._ 
running:

    %let allvars=;
    %ds_contents(&dsn, _varlst_=allvars, lib=&lib);
    %let &_var_=%list_intersection(&var,  &allvars);
2. The order of the variables in the output list matches that in the input list `var`.
3. When none of the string elements in `var` matches a variable in `dsn`, an empty list is set. 

### See also
[%str_dsvar](@ref sas_str_dsvar), [%str_isds](@ref sas_str_isds), [%str_isgeo](@ref sas_str_isgeo), 
[%var_check](@ref sas_var_check), [%ds_contents](@ref sas_ds_contents), [%ds_check](@ref sas_ds_check).
*/ /** \cond */

%macro str_isvar(dsn		/* Input reference dataset 										(REQ) */
				, var		/* List of variables to select from the input dataset 			(REQ) */
				, _ans_=	/* Name of the macro variable storing the output of the test 	(REQ) */
				, _var_= 	/* Output list of updated variables  							(REQ) */
				, lib=		/* Name of the input library 									(OPT) */
				, sep=		/* String separator 											(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	/* check that the output macro variable is set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=!!! Input parameter VAR not set !!!)
			or %error_handle(ErrorInputParameter, 
				%macro_isblank(_var_) EQ 1 and %macro_isblank(_ans_) EQ 1, mac=&_mac,		
				txt=!!! One of the output parameters _VAR_ or _ANS_ needs to be set !!!) %then
		%goto exit;

	/* some default values */
 	%if %macro_isblank(sep) %then %let sep=%str( );  /* list separator */
    %if %macro_isblank(lib) %then %let lib=WORK;

	/* some checks */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then
		%goto exit;

	%local _METHOD_ /* arbitrary calculation choice */
		_ans		/* answer to the test */
		_var;		/* updated list of existing variable returned in output */
	/* set the default output */
	%let _METHOD_=INTERSECT; /* LOOP */
	%let _var=;
	%let _ans=;
	
	%if &_METHOD_=INTERSECT and %macro_isblank(_ans_) %then %do;
		%local _allvar;	/* list of all existing variables in the input dataset */
		%let _allvar=;
	%put in &_mac: check ds_contents &dsn &lib;
		/* retrieve the list of variables present in the dataset */
		%ds_contents(&dsn, _varlst_=_allvar, lib=&lib);
	%put in &_mac: contents=&_allvar;
		%if &sep^=%str( ) %then 	%let _allvar=%list_quote(&_allvar, rep=&sep, mark=_EMPTY_);

	%put in &_mac: test &var vs &_allvar;
		/* intersect this list with the input list: done! */
		%let _var=%list_intersection(&var, &_allvar, sep=&sep, casense=NO);
		/* note the importance of the order: by putting var first, we ensure that the order
		* in the output list respects the order in var */

		/*%if %error_handle(WarningInputParameter, 
				%list_compare(&_allvars, &_varlst) NE 0, mac=&_mac,		
				txt=! Non existing variables have been discarded !, 
				verb=warn) %then 
			%goto warning; 
		%warning: */
	%end;
	%else %do;
		%local _i	/* loop increment */
			_v;		/* temporary scanned variable */
		%do _i=1 %to %list_length(&var);
			%let _v=%scan(&var, &_i, &sep);
			%if %var_check(&dsn, &_v, lib=&lib) EQ 0 %then %do;
				%let _ans=&_ans 1;
				%if %macro_isblank(_var) %then 	%let _var=&_v;
				%else 							%let _var=&_var.&sep.&_v;
			%end;
			%else
				%let _ans=&_ans 0;
		%end;
	%end;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_var) EQ 1, mac=&_mac,		
			txt=!!! No string in %upcase(&var) matches a variable in dataset %upcase(&dsn) !!!) %then  
		%goto exit; 

	/* set the output */
  	data _null_;
  		%if not %macro_isblank(_var_) %then %do;
			call symput("&_var_","&_var");
		%end;
  		%if not %macro_isblank(_ans_) %then %do;
			call symput("&_ans_","&_ans");
		%end;
	run;

	%exit:
%mend str_isvar;

%macro _example_str_isvar;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local list olist ans oans;

	%_dstest5;

	%let var=w x y z;
	%put;
	%put (i) Check the variables %upcase(&var) in test dataset #5;
	%str_isvar(_dstest5, &var, _var_=list);
	%if %macro_isblank(list) %then 	%put OK: TEST PASSED - _dstest5 returns: no variable;
	%else 							%put ERROR: TEST FAILED - Wrong result returned: &list;

	%let var=a b y z c;
	%put;
	%put (ii) Check (and update) the variables %upcase(&var) in test dataset #5;
	%str_isvar(_dstest5, &var, _var_=list);
	%let olist=a b c;
	%if &list=&olist %then 	%put OK: TEST PASSED - _dstest5 returns: &olist;
	%else 					%put ERROR: TEST FAILED - Wrong result returned: &list;

	%let var=a b y z c;
	%put;
	%put (iii) Ibid, returning the answer to the test;
	%str_isvar(_dstest5, &var, _ans_=ans);
	%let oans=1 1 0 0 1;
	%if &ans=&oans %then 	%put OK: TEST PASSED - _dstest5 returns answer: &oans;
	%else 					%put ERROR: TEST FAILED - Wrong result returned: &list;

	%_dstest31;

	%let var=value A unit;
	%put;
	%put (iv) Check the variables %upcase(&var) in test dataset #31;
	%str_isvar(_dstest31, &var, _var_=list, _ans_=ans);
	%let olist=value unit;
	%let oans=1 0 1;
	%if &list=&olist and &ans=&oans  %then 	%put OK: TEST PASSED - _dstest31 returns: &olist;
	%else 									%put ERROR: TEST FAILED - Wrong result returned: &list;

	%work_clean(_dstest5, _dstest31);
%mend _example_str_isvar;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_str_isvar;
*/

/** \endcond */

