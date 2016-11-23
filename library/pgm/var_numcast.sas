/**
## var_numcast {#sas_var_numcast}
Cast a given character variable into a numeric variable where numbers are attributed in sequence
depending on the frequency of the corresponding category in the character variable.

	%var_numcast(idsn, var, odsn=, suff=_new, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : input reference dataset, whose variable shall be cast;
* `var` : name of the character variable that should be cast, _i.e._ all categories
	in `var` will be converted into numbers;
* `suff` : (_option_) suffix to be added to the name of the cast variable; default: 
	`suff=_new`, _i.e._ the variable `a` in `idsn` will be renamed as `a_new`;
* `odsn` : (_option_) name of the output dataset; default: `odsn=idsn` so that the input
	dataset is in practice updated;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.

### Returns
`odsn` : output dataset (stored in the `olib` library), containing the exact same data than `idsn`,
	plus an additional new variable (obtained as a concatenation of the original `var` name and 
	`suff`) where all the categories of the variable defined by `var` are cast into a numeric 
	variable.

### Examples
Let us consider test dataset #31 in WORKing directory:
geo | value | unit
:--:|------:|:---:
 BE |  0    | EUR
 AT |  0.1  | EUR
 BG |  0.2  | NAC
 LU |  0.3  | EUR
 FR |  0.4  | NAC
 IT |  0.5  | EUR

then the call to the macros:

	%_dstest31;
	%var_numcast(_dstest31, unit);
	
will return the updated dataset below:
geo | value | unit |unit_new
:--:|------:|:----:|-------:
 BE |  0    | EUR  |   1
 AT |  0.1  | EUR  |   1
 BG |  0.2  | NAC  |   2
 LU |  0.3  | EUR  |   1
 FR |  0.4  | NAC  |   2
 IT |  0.5  | EUR  |   1

Run macro `%%_example_var_numcast` for more examples.

### Note 
The values in the new variable are attributed in sequential order, from the most to the least frequent 
categories in `var`. 

### Reference
Wright, W.L. (2007): ["Creating a format from raw data or a SAS dataset"](http://www2.sas.com/proceedings/forum2007/068-2007.pdf).

### See also
[%var_info](@ref sas_var_info), [%var_rename](@ref sas_var_rename), [%digits](@ref sas_digits).
*/
/** \cond */ 


%macro var_numcast(idsn
				, var
				, odsn=
				, suff=
				, ilib=
				, olib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* in practice: the output dataset can be created with the same name as the input dataset
	 * but stored in a different library 
	%if %error_handle(WarningOutputDataset, 
			%macro_isblank(odsn) EQ 1 and %macro_isblank(olib) EQ 0,		
			txt=! Output library %upcase(&olib) set, while ODSN not set !) %then
		%goto warning;
	%warning:  nothing in fact: just proceed... */

	/* set default input/output libraries if not passed */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	/* check that the input dataset actually exists */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,	
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter, 
			%var_check(&idsn, &var, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Variable %upcase(&var) does not exist in dataset &idsn !!!) %then 
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _dsn;
	%let _dsn=TMP&_mac;

	/* check whether the input variable is indeed categorical, and not already numeric */
	%local type;
	%var_info(&idsn, &var, _typ_=type, lib=&ilib);
	%if %error_handle(ErrorInputParameter, 
			&type EQ N, mac=&_mac,		
			txt=!!! Variable %upcase(&var) is already NUMERIC !!!) %then 
		%goto exit;

	/* by default, set the ouput dataset name to the input one
	 * note then that both datasets will be identical iff ilib=olib also stands */
	%if %macro_isblank(olib) %then 	%let olib=WORK;
	%if %macro_isblank(odsn) %then 	%let odsn=&idsn;

	/* retrieve all possible categories: create a dataset that holds one observation for each
	 * unique value of the input variable */
	PROC FREQ data=&ilib..&idsn;
		TABLES &var / noprint out = &_dsn;
	run;

	/* retrieve the number of digits needed to encode the new variable: it depends on the number
	 * of observed categories */
	%local count exp;
	%ds_count(&_dsn, _nobs_=count);
	%let exp = %digits(&count);

	/* use the frequency dataset to set up the required variables needed for a format and create
	 * the format */
	DATA &_dsn;
		SET &_dsn;
		RETAIN fmtname '$fmtvar' type 'C';
		RENAME &var = Start;
		LABEL = put(_n_,&exp..);
	run;

	PROC FORMAT CNTLIN=&_dsn;
	run;

	%if %macro_isblank(suff) %then 				%let suff=_new;
	/* %else %if %upcase("&suff")="_EMPTY_" */

	/* apply the newly created format to the original dataset */
	DATA &olib..&odsn
		%if %upcase("&suff")="_EMPTY_" %then %do;
			(RENAME=(&var&suff=&var))
		%end;
		;
		SET &ilib..&idsn;
		&var&suff = input(put(&var, $fmtvar.), &exp..); 
		%if %upcase("&suff")="_EMPTY_" %then %do;
			DROP &var; 
		%end;
	run;

	/* clean the temporary file */
	%work_clean(&_dsn);

	%exit:
%mend var_numcast;


%macro _example_var_numcast;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%_dstest31;
	
	%put;
	%put (i) Try to cast the (numeric) VALUE variable from _dstest31...;
	%var_numcast(_dstest31, value);

	%put;
	%put (ii) Cast the (categorical) UNIT variable from _dstest31...;
	%var_numcast(_dstest31, unit, odsn=tmp, suff=_EMPTY_);
	%ds_print(tmp);

	%put;
	%put (iii) Cast the (categorical) UNIT variable from _dstest31...;
	%var_numcast(_dstest31, unit);
	%ds_print(_dstest31);

	%work_clean(_dstest31, tmp);
%mend _example_var_numcast;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_numcast; 
*/

/** \endcond */

