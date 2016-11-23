/**  
## var_check {#sas_var_check}
* Check that a field/variable (defined as a string) actually exists in a given dataset. 

       %let ans=%var_check(dsn, var, lib=WORK);
* Trim a list of string elements to keep only those that actually define variables in a given dataset.

       %var_check(dsn, var, _varlst_=, lib=WORK);

### Arguments
* `dsn` : an input reference dataset;
* `var` : either a (list of) variable name(s), or the (list of) position(s) of variable(s) whose
	existence in input dataset `dsn` is tested; when `var` is passed as a list of integers, it is 
	only verified that these values are in the range `[1,#{variables in dsn}]` where `#{variables in dsn}`
	is the number of dimensions in `dsn`; the list of variables of corresponding variables is then
	returned through `_varlst_` (see below);
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `ans` : (_option_) the error code of the test, _i.e._:
		+ `0` when the variable `var` exists in the dataset,
		+ `1` (error: "var does not exist") otherwise;
	
	should not be used contemporaneously with the option `_varlst_` below; this is further unusable
	when `var` is passed as a list of integers;
* `_varlst_` : (_option_) name of the macro variable used to store the string elements from `var` 
	that do actually	define existing variables/fields in `dsn`; incompatible with returned result 
	`ans` above. 

### Examples
Let us consider the table `_dstest5`:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
then:

	%let var=a b y z c;
	%let list=;
	%let ans=%var_check(_dstest5, &var);

returns `ans=0 0 1 1 0`, the outputs of the existence test of string elements of `var` in 
`_dstest5`, while:

	%var_check(_dstest5, &var, _varlst_=list);

returns `list=a b c`, the only string elements of `var` which define variables in `_dstest5`. Finally,
it is possible to pass integer `var` to the macro so as to retrieve the names of the variables in
corresponding positions, _e.g._:

	%let var=3 1 4 2;
	%let list=;
	%var_check(_dstest35, &var, _varlst_=list);

returns `list=EQ_INC20 geo RB050a time`.

Run macro `%%_example_var_check` for more examples.

### Notes
1. As mentioned above, two types of outputs are possible: either the answer `ans` to the test when
a result shall be returned (and `_varlst_` is not passed), or an updated list of acceptable variables
(when `_varlst_` is passed). The former case is useful when testing a single variable existence in a 
dataset, the latter for triming a list of actual variables. Contemporaneous use is impossible.
2. In short, the macro performs either of the two following operations:
	+ the "intersection" between the list `var` with the list of variables in `dsn`, _i.e._ when 
	`_varlst_` is set:

        %let allvars=;
        %ds_contents(&dsn, _varlst_=allvars, lib=&lib);
        %let &_varlst_=%list_intersection(&var,  &allvars, casense=NO);
	+ the test of existence of the variables `var` otherwise, _i.e._ when a single variable `var` is 
	passed:

	    %let err=%sysfunc(varnum(%sysfunc(open(&lib..&dsn)),&var));
	    %if &err>0 %then 	%let ans=0;
	    %else 			 	%let ans=1;
3. The order of the variables in the output list `&_varlst_` /answer `ans` matches that in the input 
list `var`.
4. When none of the string elements in `var` matches a variable in `dsn`, an empty list `&_varlst_`/
answer `ans` is set. 

### References
1. SAS community: ["Tips: Check if a variable exists in a dataset"](http://www.sascommunity.org/wiki/Tips:Check_if_a_variable_exists_in_a_dataset).
2. Johnson, J. (2010): ["OBJECT EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%lib_check](@ref sas_lib_check), [%ds_contents](@ref sas_ds_contents), 
[%dir_check](@ref sas_dir_check), [%file_check](@ref sas_file_check),
[VARNUM](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148439.htm).
*/ /** \cond */

%macro var_check(dsn 	/* Input dataset 						(REQ) */
				, var 	/* Input variable to test 				(REQ) */
				, _varlst_= /* Output list of updated variables (REQ) */
				, lib=	/* Output library 						(OPT) */
				, verb= /* Legacy parameter - Ignored 			(OBS) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _dsid 		/* opener reference */
		__ans;		/* output answer */
	/* set the default outputs */
	%let __ans=;

	/* VAR: check that the output macro variable is set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=!!! Input parameter VAR not set !!!) %then
		%goto quit;

	/* _VARLST_, VAR: check compatibility when VAR is integer */
	%if %error_handle(ErrorInputParameter,
			%macro_isblank(_varlst_) EQ 1 and %list_count(%par_check(&var, type=INTEGER), 0) GT 0, mac=&_mac,
			txt=!!! Incompatible use of macro &_mac with input integer VAR !!!) %then 	
		%goto exit;
	/* when VAR is integer, we need to call the macro %ds_contents (which runs PROCs): this use
	* is actually incompatible with returning an answer */

	/* DSN, LIB: check/set */
	%if %macro_isblank(lib) %then 	%let lib=WORK;
	
	%let _dsid=%sysfunc(open(&lib..&dsn));
	%if %error_handle(WrongInputDataset, 
			&_dsid EQ 0 /*&ds_check(&dsn, lib=&lib) NE 0*/, mac=&_mac, 
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then 	
		%goto clean_exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i		/* loop increment */
		_var		/* scanned variable */
		_rc 		/* file identifier */
		SEP;			/* arbirtrary list separator */
	%let SEP=%quote( );

	%if not %macro_isblank(_varlst_) %then %do;

		%local _newvar	/* scanned variable */
			_nvar		/* number of fields in DSN */
			__varlst;	/* output list of existing variables */
		%let __varlst=;
		%let _newvar=;

		/* retrieve the list of all variables present in the dataset */
		%ds_contents(&dsn, _varlst_=__varlst, lib=&lib);

		%let _nvar=%list_length(&__varlst);
		%do _i=1 %to %list_length(&var);
			%let _var=%scan(&var, &_i, &SEP);
			%if %par_check(&_var, type=INTEGER, range=0) EQ 0 %then %do;
		    	%if %error_handle(ErrorInputParameter, 
		        		&_var GT &_nvar, mac=&_mac,		
		        		txt=! Wrong input varnum parameter VAR: must be <&_nvar !, 
						verb=warn) %then
		        	%goto next;
		    	/* retrieve the name of the variable */
		    	%let _var=%list_index(&__varlst, &_var);
			%end;
			%else %if %error_handle(ErrorInputParameter, 
					%par_check(&_var, type=CHAR) NE 0, mac=&_mac,		
					txt=!!! Wrong input parameter VAR !!!) %then
				%goto clean_exit;
			%let _newvar=&_newvar.&SEP.&_var;
			%next:
		%end;
		/* update/reset */
		%let var=%sysfunc(trim(&_newvar));

		/* intersect this list with the input list...and you are done! */
		%let __varlst=%list_intersection(&var,  &__varlst);
		/* note the importance of the order: by putting VAR first, we ensure that the order
		* in the output list respects the order in VAR */

		%if not %error_handle(WarningOututParameter, 
				%macro_isblank(__varlst) EQ 1, mac=&_mac,		
				txt=%bquote(! No string in %upcase(&var) matches a variable in dataset %upcase(&dsn) !), 
				verb=warn) 
		%then %do;
			%let &_varlst_=&__varlst;
			/*data _null_;
				call symput("&_varlst_","&__varlst");
			run;*/
		%end;
		/* %let &_varlst_=&__varlst; */
		%goto clean_exit;

	%end;
	%else %do;

		%local _res;	/* output test for scanned variable */
		%do _i=1 %to %list_length(&var);
			%let _var=%scan(&var, &_i, &SEP);
			%let _res=%sysfunc(varnum(&_dsid,&_var));
			%if &_res>0 %then %do;
				/* variable var exists in dsn */
				%if %macro_isblank(__ans) %then 	%let __ans=0;
				%else								%let __ans=&__ans.&SEP.0;
				/*%if %macro_isblank(__varlst) %then 	%let __varlst=&_var;
				%else								%let __varlst=&__varlst.&SEP.&_var;*/
			%end;
			%else %do;
				/* variable var does not exist in dsn */
				%if %macro_isblank(__ans) %then 	%let __ans=1;
				%else								%let __ans=&__ans.&SEP.1;
			%end;
		%end;

		/* %if not %macro_isblank(__ans) %then %do;
			 data _null_;
				call symput("&_ans_","&__ans");
			run;
		%end;*/
		%goto quit;

	%end;
		
	%quit:
	/* ... return the answer */
	&__ans

	%clean_exit:
	/* in all cases, free the dataset identifier */
	%let _rc=%sysfunc(close(&_dsid));

	%exit:
%mend var_check;
 
%macro _example_var_check;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local var list olist ans oans;

	/* first type of use: %let ans=%var_check(...) */

	%_dstest1; 	/* create the test dataset #1 in WORK directory */
	%let var=a;
	%put;
	%put (i) Check whether the field %upcase(&var) exists in test dataset _dstest1 (though empty);
	%if %var_check(_dstest1, &var) EQ 0 %then 	%put OK: TEST PASSED - Existing field %upcase(&var): errcode 0;
	%else										%put ERROR: TEST FAILED - Existing field %upcase(&var): errcode 1;
 								
	%_dstest2; 	/* create the test dataset #2 in WORK directory */
	%put;
	%put (ii) Check whether the field %upcase(&var) exists in test dataset _dstest2;
	%if %var_check(_dstest2, &var) EQ 0 %then 	%put OK: TEST PASSED - Existing field %upcase(&var): errcode 0;
	%else 										%put ERROR: TEST FAILED - Existing field %upcase(&var): errcode 1;

	%let var=DUMMY;
	%put;
	%put (iii) Check whether the variable %upcase(&var) exists in that same dataset;
	%if %var_check(_dstest2, &var) NE 0 %then 	%put OK: TEST PASSED - Field %upcase(&var): errcode 1;
	%else 										%put ERROR: TEST FAILED - Field %upcase(&var): errcode 0;

	/* second type of use: %var_check(... _varlst_= ...) */

	%_dstest5;	/* create the test dataset #5 in WORK directory */
	%let var=w x y z;
	%put;
	%put (iv) Check whether the variables %upcase(&var) exist in test dataset #5;
	%var_check(_dstest5, &var, _varlst_=list);
	%if %macro_isblank(list) /* and %quote(&ans) EQ %quote(&oans) */ %then 	
		%put OK: TEST PASSED - _dstest5 returns: no variable /* / answer &oans */;
	%else 							
		%put ERROR: TEST FAILED - Wrong result/answer returned: &list /* / &ans */;

	%_dstest5;	/* create the test dataset #5 in WORK directory */
	%put;
	%put (v) Ibid, returning the boolean answer to the test;
	%let oans=1 1 1 1;
	%let ans=%var_check(_dstest5, &var);
	%if %quote(&ans) EQ %quote(&oans) %then 	
		%put OK: TEST PASSED - _dstest5 returns: &oans;
	%else 							
		%put ERROR: TEST FAILED - Wrong result/answer returned: &ans;

	%let var=a b y z c;
	%put;
	%put (vi) Check the variables %upcase(&var) in test dataset #5;
	%let olist=a b c;
	%var_check(_dstest5, &var, _varlst_=list);
	%if %quote(&list) EQ %quote(&olist) %then 	
		%put OK: TEST PASSED - _dstest5 returns: variables &olist /* / answer &oans */;
	%else 										
		%put ERROR: TEST FAILED - Wrong result/answer returned: &list /* / &ans */;

	%put;
	%put (vii) Ibid, returning the boolean answer to the test;
	%let oans=0 0 1 1 0;
	%let ans=%var_check(_dstest5, &var);
	%if %quote(&ans) EQ %quote(&oans) %then 	
		%put OK: TEST PASSED - _dstest5 returns: variables &oans;
	%else 										
		%put ERROR: TEST FAILED - Wrong result/answer returned: &ans;

	%_dstest31;

	%let var=value A unit;
	%put;
	%put (viii) Check the variables %upcase(&var) in test dataset #31;
	%let olist=value unit;
	%var_check(_dstest31, &var, _varlst_=list);
	%if %quote(&list) EQ %quote(&olist) %then 	
		%put OK: TEST PASSED - _dstest31 returns: variables &olist /* / answer &oans */;
	%else 										
		%put ERROR: TEST FAILED - Wrong result/answer returned: &list /* / &ans */;

	%_dstest35;

	%let var=3 1 4 2;
	%put;
	%put (ix) Check the variables corresponding to %upcase(&var) in test dataset #35;
	%let olist=EQ_INC20 geo RB050a time; 
	%var_check(_dstest35, &var, _varlst_=list);
	%if %quote(&list) EQ %quote(&olist)  %then 	
		%put OK: TEST PASSED - _dstest35 returns: variables &olist /* / answer &oans */;
	%else 										
		%put ERROR: TEST FAILED - Wrong result/answer returned: &list /* / &ans */;

	%put;

	%let var=3 geo 4 time;
	%put;
	%put (x) Ibid, passing a mixed list: %upcase(&var);
	%var_check(_dstest35, &var, _varlst_=list);
	%if %quote(&list) EQ %quote(&olist) %then 	
		%put OK: TEST PASSED - _dstest31 returns: variables &olist /* / answer &oans */;
	%else 										
		%put ERROR: TEST FAILED - Wrong result/answer returned: &list /* / &ans */;

	%put;

	/* clean your shit... */
	%work_clean(_dstest1, _dstest2, _dstest5, _dstest31, _dstest35);
%mend _example_var_check;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_check; 
*/

/** \endcond */
