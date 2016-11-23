/** 
## str_varlist {#sas_str_varlist}
* Output a formatted/zipped list of dataset and variables:

      %let %str_varlist(var, ds=, rep=%quote(, ), sep=%quote( ));

* Split a list of strings into a pair of dataset/variable strings, possibly trimming those 
that do not define actual variables in a dataset:

	%str_varlist(var, _varlst_=, _dslst_=, rep=%quote(, ), sep=%quote( ), lib=WORK, check=no);

### Arguments
* `var` : a list of strings/elements of the form `var` or `dsn.var` where the `dsn` represents
	some dataset and `var`, some variable;
* `ds=` : (_option_) Input reference dataset 								
* `_dslst_` : (_option_) Output list of datasets  						
* `_varlst_` : (_option_) Output list of variables			  				
* `sep, rep` : (_option_)  Replacement string 									
* `check=no` : (_option_) Boolean flag (`yes/no`) set to check the  variables' existence 	
* `lib` : (_option_) name of the input library; by default: `WORK` is used.

### Returns
`_varlst_` : name of the macro variable used to store the elements from `var` that actually
	define existing variables/fields in `dsn`. 

### Example
Let us consider the following simple examples:

	%let var=a b y z c;
	%let ds=tab;
	%let lvar=%str_varlist(&var, ds=&ds);

returns `list=tab.a, tab.b, tab.y, tab.z, tab.c`, while

	%_dstest5;
	%let var=_dstest5.a,_dstest5.b,_dstest5.y,_dstest5.z,_dstest5.c;
	%let ds=;
	%let var=;
	%str_varlist(%quote(&var), _varlst_=var, _dslst_=ds, check=yes, rep=%quote( ), sep=%quote(,));

sets `var=a b c` and `ds=_dstest5 _dstest5 _dstest5`.

Run macro `%%_example_str_varlist` for more examples.

### Note
In short, given some variables `var` and `ds`, the first-case (most common) scenario ran through
the command `str_varlist(&var, ds=&ds)` actually runs:

	%let varlst=&ds..%list_quote(&var, mark=_EMPTY_, sep=&sep, rep=&rep%quote(&ds..));
which is also equivalent to:

	%let varlst=%list_append(%list_ones(%length(&var, sep=&sep), item=&ds), &var, zip=%quote(.), rep=%quote(, ));

### See also
[%str_dslist](@ref sas_str_dslist), [%var_check](@ref sas_var_check), [%ds_contents](@ref sas_ds_contents), 
[%ds_check](@ref sas_ds_check), [%list_append](@ref sas_list_append).
*/ /** \cond */

%macro str_varlist(var		/* String representing a list of dataset/variable pairs (REQ) */
				, ds=		/* Input reference dataset 								(REQ) */
				, _dslst_=	/* Output list of datasets  							(REQ) */
				, _varlst_= /* Output list of variables			  					(REQ) */
				, sep=		/* String separator 									(OPT) */
				, rep=		/* Replacement string 									(OPT) */
				, check=no	/* Boolean flag set to check the  variables' existence 	(OPT) */
				, lib=		/* Name of the input library 							(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	/* check that the output macro variable is set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=!!! Input parameter VAR not set !!!) %then
		%goto exit;
	
	%if %macro_isblank(sep) %then 	%let sep=%quote( );  /* list separator */
	%if %macro_isblank(rep) %then 	%let rep=%quote(, );  /* list separator */
	%else %if &rep=_EMPTY_ 	%then 	%let rep=%quote( ); /* mark */

	%local _var;	/* output */
	%let _var=;

	/* we deal already with the most common use case for efficiency reason... */
	%if not %macro_isblank(ds) %then %do;
		%let _var=&ds..%list_quote(&var, mark=_EMPTY_, sep=&sep, rep=&rep%quote(&ds..));
		%goto quit;
	%end;
	/* now let's proceed with the least common use cases... */

	/* check that the output macro variable is set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(ds) EQ 1 and %macro_isblank(_dslst_) EQ 1 and %macro_isblank(_varlst_) EQ 1, mac=&_mac,		
			txt=%quote(!!! Either input DS needs to be passed, or outputs _DSLST_ and _VARLST_ need to be set !!!)) %then
		%goto exit;
	%else %if %error_handle(WarningInputParameter, 
			%upcase(&check) EQ YES and not %macro_isblank(ds), mac=&_mac,		
			txt=! Option CHECK=YES ignored when parameter DS is passed !, verb=warn)
			or
			%error_handle(WarningInputParameter, 
				%upcase(&check) EQ NO and not %macro_isblank(lib), mac=&_mac,		
				txt=! Option LIB is ignored when CHECK=NO !, verb=warn) %then
		%goto warning;
	%warning:

	%if %macro_isblank(ds) %then %do;
		%local _i		/* loop increment */
			_v			/* temporary scanned */
			_pos		/* position of . in input scanned element */
			_dsn 		/* temporary retrieved dataset */
			_var		/* temporary retrieved variable */
			_ans
			__varlst	/* output updated list of variables */
			__dslst;	/* corresponding output list of datasets */
		%let __varlst=;
		%let __dslst=;
		%do _i=1 %to %list_length(&var, sep=&sep);
			%let _var=%scan(&var, &_i, &sep);
			%let _pos=%index(&_var, .);
			%if &_pos^=0 %then %do;
				%let _dsn=%substr(&_var, 1, %eval(&_pos - 1));
				%let _var=%substr(&_var, %eval(&_pos+1));
			%end;

			%if %upcase(&check)=YES %then %do;
				%if %macro_isblank(lib) %then %let lib=WORK;
				%let _ans=%var_check(&_dsn, &_var, lib=&lib);
				%if &_ans^=0 %then 	%goto next;
			%end;
	
			%if %macro_isblank(__varlst) %then	%let __varlst=&_var;
			%else 								%let __varlst=&__varlst.&rep.&_var; 
			%if %macro_isblank(__dslst) %then	%let __dslst=&_dsn;
			%else 								%let __dslst=&__dslst.&rep.&_dsn; 

			%next:
		%end;

		data _null_;
			%if not %macro_isblank(_dslst_) %then %do;
				call symput("&_dslst_","&__dslst");
			%end;
			%if not %macro_isblank(_varlst_) %then %do;
				call symput("&_varlst_","&__varlst");
			%end;
		run;
		%goto exit;
	%end;

	%quit:
	&_var

	%exit:
%mend str_varlist;

%macro _example_str_varlist;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn list olist dslst odslst;

	%let var=a b c;
	%let dsn=_dstest5;
	%put;
	%put (i) We compare the first-case use of str_varlist with the zip option of list_append;
	%let list=%str_varlist(&var, ds=&dsn);
	%let olist=%list_append(%list_ones(%length(&var), item=&dsn), &var, zip=%quote(.), rep=%quote(, ));
	%if %quote(&list) EQ %quote(&olist) and %quote(&dslst) EQ %quote(&odslst) %then 	
		%put OK: TEST PASSED - Tests return same output: var=&olist;
	%else 										
		%put ERROR: TEST FAILED - Tests return different outputs: var=&list; 

	%let var=a b y z c;
	%put;
	%put (ii) Retrieve the formatted list from the variables %upcase(&var) in test dataset #5;
	%let list=%str_varlist(&var, ds=_dstest5, rep=_EMPTY_);
	%let olist=_dstest5.a _dstest5.b _dstest5.y _dstest5.z _dstest5.c;
	%if %quote(&list) = %quote(&olist) %then 	%put OK: TEST PASSED - Test returns: &olist;
	%else 										%put ERROR: TEST FAILED - Wrong result returned: &list; 

	%put;
	%put (iii) We now retrieve datasets/variables from the previous output: &olist;
	%str_varlist(&olist, _dslst_=dslst, _varlst_=list, rep=_EMPTY_);
	%let odslst=%list_ones(5,item=_dstest5);
	%if %quote(&list) EQ %quote(&var) and %quote(&dslst) EQ %quote(&odslst) %then 	
		%put OK: TEST PASSED - Test returns: var=&var and ds=&odslst;
	%else 										
		%put ERROR: TEST FAILED - Wrong result returned: var=&list and ds=&dslst; 

	%_dstest5; /* actually create it... */

	%let var=_dstest5.a _dstest5.b _dstest5.c;
	%put;
	%put (iv) Ibid, but we also check the existence this time (using check=YES);
	%str_varlist(&var, _dslst_=dslst, _varlst_=list, check=YES);
	%let olist=a, b, c;
	%let odslst=%list_ones(3,item=_dstest5, sep=%quote(, ));
	%if %quote(&list) EQ %quote(&olist) and %quote(&dslst) EQ %quote(&odslst) %then 	
		%put OK: TEST PASSED - Test returns: var=&olist and ds=&odslst;
	%else 										
		%put ERROR: TEST FAILED - Wrong result returned: var=&list and ds=&dslst; 

	%_dstest5;
	%let var=_dstest5.a, _dstest5.b, _dstest5.y, _dstest5.z, _dstest5.c;
	%let sep=%quote(, );
	%let rep=%quote( );
	%put;
	%put (v) We also test the list=&var (hence sep=&sep), and a separator: rep=&rep;
	%str_varlist(%quote(&var), _varlst_=list, _dslst_=dslst, check=yes, rep=%quote( ), sep=%quote(,));
	%if %quote(&list) EQ %quote(&olist) and %quote(&dslst) EQ %quote(&odslst) %then 	
		%put OK: TEST PASSED - Test returns: var=&olist and ds=&odslst;
	%else 										
		%put ERROR: TEST FAILED - Wrong result returned: var=&list and ds=&dslst; 

	%put;

	%work_clean(_dstest5);
%mend _example_str_varlist;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_str_varlist;
*/

/** \endcond */
