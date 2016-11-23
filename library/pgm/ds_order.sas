/** 
## ds_order {#sas_ds_order}
(Re)order the variables (columns) of a given dataset.

	%ds_order(idsn, odsn=, varnum=alpha, varlst=, varlike=, ilib=WORK, olib=WORK, liblike=WORK);

### Arguments
* `idsn` : a dataset reference;
* `varnum` : (_option_) list of variables positions (numeric indexes) to consider so as to reorder 
	the columns/fields of `idsn`; note that `varnum=alpha` is also accepted, so that, in that case,
	the variables in `idsn` are reordered alphabetically; incompatible with options `varlst` and 
	`varlike` below; default: `varnum=alpha`, and the variables in the dataset `idsn` are reordered
	alphabetically when none of the parameteres `varnum`, `varlst` and `varlike` (see below) is 
	passed;
* `varlst` : (_option_) list of variables names to consider so as to reorder the columns/fields of 
	`idsn`; incompatible with options `varnum` above and `varlike` below; default: `varlst=`, _i.e._
	it is not set;
* `varlike` : (_option_) table whose variables order will be applied to the dataset reference; 
	incompatible with options `varlst` above and `varlike` above; default: `varlike=`, _i.e._
	it is not set;
* `odsn` : (_option_) name of the output dataset (in `WORK` library); when not set, the input
	dataset `dsn` is replaced with the newly sorted version; default: not set;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used,
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `ilib` will be used in 
	case `odsn` is set;
* `liblike` : (_option_) name of the library where `varlike` is stored; by default: empty, _i.e._ 
	`ilib` will be used in case `varlike` is set.
 
### Returns
In either `odsn` or `idsn` (updated when the former is not passed), the original dataset with reordered 
variables.

### Examples
Let us first  consider test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

then the variables in the dataset can be easily reordered alphabetically, _e.g._ using 
undifferently any of the instructions below:

	%ds_order(_dstest5, odsn=dsn);
	%ds_order(_dstest5, odsn=dsn, varnum=alpha);

so as to store in the output dataset `dsn` the following table:
 a | b | c | d | e | f 
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5 

Let us also consider test dataset #6:
 a | b | c | d | e | f | g | h 
---|---|---|---|---|---|---|--- 
 . | 1 | 2 | 3 | . | 5 | 6 | .

the following instructions enable us to explicitely reorder the variables in the table (note that
the variables not mentioned in `varlst` are retrieved from the remaining positions):

	%let varlst=b a h e c;
	%ds_order(_dstest6, odsn=dsn, varlst=&varlst);

so that the output dataset `dsn` contains the table:
 b | a | h | e | c | d | f | h 
---|---|---|---|---|---|---|--- 
 1 | . | . | . | 2 | 3 | 5 | .

Instead, the instructions below allow us to order the variables according to their initial positions in
the table:

	%let varnum=4 7 3 2;
	%ds_order(_dstest6, odsn=dsn, varnum=&varnum);

so that the output dataset `dsn` contains the table:
 d | g | c | b | a | e | f | h 
---|---|---|---|---|---|---|--- 
 3 | 6 | 2 | 1 | . | . | 5 | .

	
It is also possible to order the variables in test dataset #6 according to the position of the same variables
(_i.e._ same name) in test dataset #5:

	%ds_order(_dstest6, odsn=dsn, varlike=_dstest5);

which returns in the output dataset `dsn` the following table:
 f | e | d | c | b | a | g | h 
---|---|---|---|---|---|---|---
 5 | . | 3 | 2 | 1 | . | 6 | .

Run macro `%%_example_ds_order` for more examples.

### Notes
1. In short, when `varlst` is set (instead of `varnum` or `varlike`), the macro runs the following `DATA` step:

        DATA &olib..&odsn;
			FORMAT &varlst; 
			SET &ilib..&idsn; 
        run;

2. Even when the input dataset `idsn` is already ordered as desired, the `DATA` step will still be ran 
as long as the output dataset `odsn` differs from `idsn`, so that a duplicated dataset is created.

### References
1. Go, I.C. (2002): ["Reordering variables in a SAS data set"](http://analytics.ncsu.edu/sesug/2002/PS12.pdf).
2. Clapson, A. (2014): ["Ordering columns in a SAS dataset: Should you really RETAIN that?"](http://support.sas.com/resources/papers/proceedings14/1751-2014.pdf).
3. ["Re-ordering variables"](http://www.sascommunity.org/wiki/Re-ordering_variables).

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check), [%var_info](@ref sas_var_info), 
[%var_rename](@ref sas_var_rename).
*/ /** \cond */

%macro ds_order(idsn
				, odsn= 
				, varlst=
				, varnum=
				, varalpha=
				, varlike=
				, ilib=
				, olib=
				, liblike=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _isvarlst 
		_isvarnum 
		_isvarlike;

	/* check variables used for sorting */
	%let _isvarlst=%macro_isblank(varlst); 
	%let _isvarnum=%macro_isblank(varnum); 
	%let _isvarlike=%macro_isblank(varlike);

	%if %error_handle(ErrorInputParameter, 
			&_isvarlst + &_isvarnum + &_isvarlike LT 2, mac=&_mac,		
			txt=%quote(!!! Input parameters VARLST, VARNUM and VARLIKE are incompatible !!!)) %then
		%goto exit;
	%else %if %eval(&_isvarlst + &_isvarnum + &_isvarlike) EQ 3 %then
		%let varnum=alpha;

	/* check some logical settings */
	%if %error_handle(WarningOutputDataset, 
			%macro_isblank(odsn) EQ 1 and %macro_isblank(olib) EQ 0, mac=&_mac,		
			txt=! Ignored output library %upcase(&olib) since ODSN not set !
			verb=warn) %then
		%goto warning1;
	%warning1: /* nothing in fact: just proceed... */

	/* check the input dataset */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* check the output dataset */
	%if %macro_isblank(olib) %then 	%let olib=&ilib;
	%if %macro_isblank(odsn) %then 	
		%let odsn=&idsn;
	%else %if %error_handle(ErrorInputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&odsn) already exists !,
			verb=warn) %then
		%goto warning2;
	%warning2: /* nothing in fact: just proceed... */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local ivarlst 
		ovarlst 
		_i 
		_inum
		SEP;
	%let SEP=%str( );

	/* retrieve the variables (ordered by varnum) as they are currently stored in the input file */
	%ds_contents(&idsn, _varlst_=ivarlst, varnum=yes, lib=&ilib);
	
	%if &_isvarnum = 0 %then %do;
		/* first, retrieve the desired ordered list */
		%if %list_length(&varnum, sep=&SEP)=1 and %quote(&varnum) = %quote(alpha) %then 
			/* check if varnum is not in fact an instruction for alphabetical reordering */
			%ds_contents(&idsn, _varlst_=ovarlst, varnum=no, lib=&ilib);
		%else 
			/* get the variable names from their position */
			%let ovarlst=%list_index(&ivarlst, &varnum, sep=&SEP);			
			/* note that %list_index will deal with the cases &_inum<1 or &_inum>%list_length(&ivarlst) */ 
	%end;

	%else %do; 
		/* first, retrieve the desired ordered list */
		%if &_isvarlike = 0 %then %do;
			%if %macro_isblank(liblike) %then 	%let liblike=&ilib;
			%if %error_handle(ErrorInputDataset, 
					%ds_check(&varlike, lib=&liblike), mac=&_mac,		
					txt=!!! Reference dataset %upcase(&varlike) not found !!!) %then
				%goto exit;
			%ds_contents(&varlike, _varlst_=ovarlst, varnum=yes, lib=&liblike);
		%end;
		%else %if &_isvarlst=0 %then
			%let ovarlst=&varlst;
		/* next, retrieve the variables common to both datasets, ie those present in both lists */
		%if %error_handle(WarningInputDataset, 
				%list_compare(&ivarlst, &ovarlst) LT 0 /* note that EQ 0 and EQ 1 are accepted */, mac=&_mac,
				txt=!!! Some variables in %upcase(&varlike) does not exist in %upcase(&idsn) - They will be ignored !!!) %then 
			 /* note that the order matters here, since the order of the common items in the intersection
			 * is the same as the one in ovarlst (first list passed to %list_intersection)*/
			%let ovarlst=%list_intersection(&ovarlst, &ivarlst, sep=&SEP);
	%end;

	/* finally, complete the list of variables with all others in the order they appear in the input dataset */
	%let ovarlst=/* 2. update: append first the common variables in the desired order + other variables */
				%list_append(&ovarlst, 
							/* 1. retrieve those which are present only in the input dataset */
							%list_difference(&ivarlst, &ovarlst, sep=&SEP), 
							sep=&SEP);

	%if %macro_isblank(ovarlst) 
		or
		%error_handle(WarningInputDataset, 
				%list_compare(&ivarlst, &ovarlst) NE 0/* they must be the same now */, mac=&_mac,		
				txt=!!! Some variables in %upcase(&ovarlst) differ from those in %upcase(&idsn) !!!) %then 
		%goto exit; /* hum... something went wrong here */

	%if %error_handle(NothingToDo, 
			%quote(&ivarlst) EQ %quote(&ovarlst), mac=&_mac, 
			txt=! Dataset %upcase(&idsn) already ordered according to %upcase(&ovarlst) - Nothing to do !, 
			verb= warn) 
		and
		%quote(&idsn) EQ %quote(&odsn) and %quote(&ilib) EQ %quote(&olib) %then
		%goto exit;

	/* approach 1 */
	DATA &olib..&odsn
		/* %if not %macro_isblank(view) %then %do;
			/ VIEW=&olib..&odsn
		%end; */
		;
		FORMAT /* RETAIN */ &ovarlst; 
		SET &ilib..&idsn; 
	run;

	/* approach 2 
	PROC SQL noprint;
	  	CREATE 
		%if %macro_isblank(view) %then %do;
			TABLE
		%end;
		%else %do;
			VIEW 
		%end; 
		&olib..&odsn AS
	  	SELECT &ovarlst, *
	  	FROM &ilib..&idsn;
	quit;
	*/

	%exit:
%mend ds_order;

%macro _example_ds_order;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn varlst5 varlst6 varlst ovarlst;
	%let dsn=TMP%upcase(&sysmacroname);
		
	%_dstest5;
	%ds_print(_dstest5);
	%ds_contents(_dstest5, _varlst_=varlst5, varnum=yes); /* this is: f e d c b a */
	%_dstest6;
	%ds_print(_dstest6);
	%ds_contents(_dstest6, _varlst_=varlst6, varnum=yes); /* this is: a b c d e f g h */

	%put;
	%put (i) Dummy examples with missing parameters;
	%ds_order(_dstest5, odsn=&dsn);
	%put OK: TEST PASSED - Dummy test failed;

	%put;
	%put (ii) Dummy examples with too many parameters;
	%ds_order(_dstest5, odsn=&dsn, varnum=5 4 3 2 1, varlike=_dstest6);
	%put OK: TEST PASSED - Dummy test failed;

	%put;
	%put (iii) Order the variables in test table #5 according to the order of common variables in test table #6;
	%let ovarlst=a b c d e f;
	%ds_order(_dstest5, odsn=&dsn, varlike=_dstest6);
	%ds_contents(&dsn, _varlst_=varlst, varnum=yes);
	%if %quote(&varlst) = %quote(&ovarlst) %then 	
		%put OK: TEST PASSED - Dataset _dstest5 correctly reordered: %upcase(&ovarlst);
	%else 								
		%put ERROR: TEST FAILED - Dataset _dstest5 wrongly reordered: %upcase(&varlst);
	%ds_print(&dsn);

	%put;
	%put (iv) Reversely, order the variables in test table #6 according to the order of common variables in test table #5;
	%let ovarlst=f e d c b a g h;
	%ds_order(_dstest6, odsn=&dsn, varlike=_dstest5);
	%ds_contents(&dsn, _varlst_=varlst, varnum=yes);
	%if %quote(&varlst) = %quote(&ovarlst) %then 	
		%put OK: TEST PASSED - Dataset _dstest6 correctly reordered: %upcase(&ovarlst);
	%else 								
		%put ERROR: TEST FAILED - Dataset _dstest6 wrongly reordered: %upcase(&varlst);
	%ds_print(&dsn);

	%let varnum=5 10 3 1; /* note that 10 will be ignored */
	%put;
	%put (v) Reversely, order the variables in test table #5 according to the order varnum=&varnum;
	%let ovarlst=b d f e c a ;
	%ds_order(_dstest5, odsn=&dsn, varnum=&varnum);
	%ds_contents(&dsn, _varlst_=varlst, varnum=yes);
	%if %quote(&varlst) = %quote(&ovarlst) %then 	
		%put OK: TEST PASSED - Dataset _dstest5 correctly reordered: %upcase(&ovarlst);
	%else 								
		%put ERROR: TEST FAILED - Dataset _dstest5 wrongly reordered: %upcase(&varlst);
	%ds_print(&dsn);

	%let varlst=g b d e;
	%put;
	%put (vi) Reversely, order the variables in test table #6 in the order varlst=&varlst;
	%let ovarlst=g b d e a c f h; 
	%ds_order(_dstest6, odsn=&dsn, varlst=&varlst);
	%ds_contents(&dsn, _varlst_=varlst, varnum=yes);
	%if %quote(&varlst) = %quote(&ovarlst) %then 	
		%put OK: TEST PASSED - Dataset _dstest6 correctly reordered: %upcase(&ovarlst);
	%else 								
		%put ERROR: TEST FAILED - Dataset _dstest6 wrongly reordered: %upcase(&varlst);
	%ds_print(&dsn);
	%put;
	%put (vii) Reorder alphabetically the variables in test table #5;
	%let ovarlst=a b c d e f; 
	%ds_order(_dstest5, odsn=&dsn, varnum=alpha);
	%ds_contents(&dsn, _varlst_=varlst, varnum=yes);
	%if %quote(&varlst) = %quote(&ovarlst) %then 	
		%put OK: TEST PASSED - Dataset _dstest5 correctly alphabetically ordered: %upcase(&ovarlst);
	%else 								
		%put ERROR: TEST FAILED - Dataset _dstest5 wrongly alphabetically eordered: %upcase(&varlst);
	%ds_print(&dsn);

	%work_clean(&dsn);
	%work_clean(_dstest5);
	%work_clean(_dstest6);
%mend _example_ds_order;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_order; 
*/

/** \endcond */
