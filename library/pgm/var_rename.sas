/**
## var_rename {#sas_var_rename}
Perform a 'bulk-renaming' of the variables of a given table. 

    %var_rename(idsn, var=, ex_var=, odsn=, suff=_new, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : input reference dataset, whose variables shall be renamed;
* `var` : (_option_) list of variables that should be renamed; this parameter is incompatible
	with the parameter `ex_var` below; default: `var` is empty, and all variables present in
	the input dataset `idsn` will be renamed (unless `ex_var` is not empty);
* `ex_var` : (_option_) list of variables that should not be renamed; this parameter is 
	incompatible with the parameter `var` below;typically the identifying variables which will 
	be used to perform the matching shall not be renamed; default: `ex_var` is empty;
* `suff` : (_option_) generic suffix to be added to the names of the variables; default: 
	`suff=_new`, _i.e._ a variable `a` in `idsn` will be renamed as `a_new`;
* `odsn` : (_option_) name of the output dataset; default: `odsn=idsn` so that the input
	dataset is in practice updated;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.

### Returns
`odsn` : output dataset (stored in the `olib` library), containing the exact same data than `idsn`,
	where all variables defined by `var` and/or excluding those defined by `ex_var` are renamed as 
	a concatenation of their former name and `suff`.

### Examples
Let us consider test dataset #5 in WORKing directory:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

then both calls to the macro below:

	%var_rename(_dstest5, var=a c d, odsn=out1, suff=2);
	%var_rename(_dstest5, ex_var=b e f, odsn=out2, suff=2);
	
will return the exact same dataset `out1=out2` (in WORKing directory) below:
 f | e | d2 | c2 | b | a2
---|---|----|----|---|---
 . | 1 | 2  | 3  | . | 5

Run macro `%%_example_var_rename` for more examples.

### Note
1. When merging two similar tables, it may be useful to be able to add a suffix over the names of 
the variables in order to avoid unexpected deletion of data. One may, for instance, need to merge 
two similar tables from different years: it is then necessary to rename all variables containing 
information that varies across time. The macro `var_rename` can be used for this purpose.
2. When none of the input parameters `var` and `ex_var` is passed, all variables present in the 
input dataset `idsn` are renamed.
3. The macro implementation was contributed to by P.BBES.Lamarche (<mailto:pierre.lamarche@ec.europa.eu>).

### See also
[%ds_contents](@ref sas_ds_contents), [%var_check](@ref sas_var_check), [%var_info](@ref sas_var_info), 
[%ds_order](@ref sas_ds_order).
*/
/** \cond */ 

%macro var_rename(idsn, var=, ex_var=, odsn=, suff=, ilib=, olib=);

	/* perform some basic compatibility checking between input parameters */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 0 and %macro_isblank(ex_var) EQ 0,		
			txt=!!! Incompatible parameters VAR and EX_VAR !!!) %then
		%goto exit;

	/* %if %error_handle(WarningOutputDataset, 
			%macro_isblank(odsn) EQ 1 and %macro_isblank(olib) EQ 0,		
			txt=! Ignored output library %upcase(&olib) since ODSN not set !) %then
		%goto warning;
	%warning: nothing in fact: just proceed... */

	/* set default input/output libraries if not passed */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	%if %macro_isblank(olib) %then 	%let olib=&ilib;

	%if %macro_isblank(suff) %then %let suff=_new;

	/* check that the input dataset actually exists */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* by default, set the ouput dataset name to the input one
	 * note then that both datasets will be identical iff ilib=olib also stands */
	%if %macro_isblank(odsn) %then 	%let odsn=&idsn;

	%if %macro_isblank(var) %then %do;
		/* retrieve the list of variables of the table */
		%ds_contents(&idsn, _varlst_=var, lib=&ilib);
	%end;

	%if %macro_isblank(ex_var) EQ 0 %then %do;
		/* drop those variables which should not be renamed */ 
		%let var=%list_difference(&var, &ex_var);
	%end;
	
	/* PROC SQL;
		SELECT name into: list_var separated by " " from dictionary.columns 
		WHERE libname = "%upcase(&ilib)" 
				and memname = "%upcase(&idsn)" 
				and name in (%upcase(&var));
	quit;
	*/

	%local _k _var SEP;
	%let SEP=%str( );

	/* at this stage we can further check that all given variables are indeed present 
	 * in the dataset 
	 * that is the way we would do it 
	%let tmpvar=; 
	%do _k=1 %to %list_length(&var, sep=&SEP);
		%let _var=%scan(&var, &_k, &SEP);
		%if %error_handle(WarningInputParameter, 
				%var_check(&idsn, &_var, lib=&ilib) EQ 1,		
				txt=! Variable %upcase(&_var) does not exist in dataset &idsn !, 
				verb=warn) %then 
			%goto warning;
		%else %do;
			%let tmpvar=&tmpvar.&SEP&_var;
		%end;
		%warning:
	%end;
	%let var=&tmpvar; 
	*/

	%if %macro_isblank(var) %then /* nothing to do */
		%goto exit;

	DATA &olib..&odsn ;
		SET &ilib..&idsn ;
		RENAME 
		%do _k = 1 %to %list_length(&var, sep=&SEP);
			/* note the use of list_length instead of %sysfunc(countw(&var)) since we recoded
			 * it and we want to demonstrate that this has bot been a pointless effort... */
			%scan(&var,&_k) = %scan(&var, &_k)&suff
		%end ;
		;
	run;

	%exit:
%mend var_rename;

/* For backward compatibility, we also define the following macro so that its call will be transparent
 * to the user */
%macro suffix_var(table_in, suffix, lib_in=work, lib_out=work, table_out=, id_var=);
	%var_rename(&table_in, ex_var=&id_var, suff=&suffix, odsn=&table_out, ilib=&lib_in, olib=&lib_out);
%mend;

%macro _example_var_rename;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn;
	%let dsn=TMP%upcase(&sysmacroname);

	/* we will use test dataset #5 in the examples below */
	%_dstest5;
	%*ds_print(_dstest5);
	%let var_new = a_new b c_new d e f_new;
	%*ds_print(_dstest5);
	%put;
	%put (i) Dummy example that crashes;
    %var_rename(_dstest5, var=a c, ex_var=b d e f);
	
	%local var var_new ovar;

	%let var = a c f;
	%put;
	%put (ii) Simple example of renaming procedure on test dataset #5 using var=&var;
  	%let ovar = f_new e d c_new b a_new;
  	%var_rename(_dstest5, var=&var, odsn=&dsn, suff=_new);
	%ds_contents(&dsn, _varlst_=var_new);
	%if &ovar = &var_new %then 	%put OK: TEST PASSED - Correct (inclusive) renaming of _dstest5 variables into: &ovar;
	%else 						%put ERROR: TEST FAILED - Wrong (inclusive) renaming of _dstest5 variables into: &var_new;

	%let ex_var = b d e;
	%put;
	%put (iii) Test the same renaming on test dataset #5 using ex_var=&ex_var;
  	%var_rename(_dstest5, ex_var=&ex_var, odsn=&dsn); /* no suffix */
	%ds_contents(&dsn, _varlst_=var_new);
	%if &ovar = &var_new %then 	%put OK: TEST PASSED - Correct (exclusive) renaming of _dstest5 variables into: &ovar;
	%else 						%put ERROR: TEST FAILED - Wrong (exclusive) renaming of _dstest5 variables into: &var_new;

	%let var = a c f;
	%let suff=1;
	%put;
	%put (iv) Update test dataset #5 using var=&var and suff=&suff;
   	%let ovar = f1 e d c1 b a1;
 	%var_rename(_dstest5, ex_var=&ex_var, suff=&suff); 
	%ds_contents(_dstest5, _varlst_=var_new);
	%if &ovar = &var_new %then 	%put OK: TEST PASSED - Correct (exclusive) renaming of _dstest5 variables into: &ovar;
	%else 						%put ERROR: TEST FAILED - Wrong (exclusive) renaming of _dstest5 variables into: &var_new;
	%ds_print(_dstest5);

	/* clean your shit */
	%work_clean(&dsn);
	%work_clean(_dstest5);
%mend _example_var_rename;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_rename; 
*/

/** \endcond */
