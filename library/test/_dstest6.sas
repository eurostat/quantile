/** 
## _DSTEST6 {#sas_dstest6}
Test dataset #6.

	%_dstest6;
	%_dstest6(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest6`:
 a | b | c | d | e | f | g | h |
---|---|---|---|---|---|---|--- 
 . | 1 | 2 | 3 | . | 5 | 6 | .

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest6` storing 
	the following table: 

### Example
To create dataset #6 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest6;
	%ds_print(_dstest6);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest6(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
		a=.; b=1; c=2; d=3; e=.; f=5; g=6; h=.; output;
		run;
	%end;
	%else %do;
		%if &verb=yes %then %put dataset &_dsn already exists in library &_ilib;
	%end;

	%if %macro_isblank(lib) %then 	%let lib=WORK;

	%if "&lib"^="&_ilib" %then %do;
		/* %ds_merge(&_dsn, &_dsn, lib=&_ilib, olib=&lib); */
		DATA &lib..&_dsn;
			set &_ilib..&_dsn;
		run; 
		%if &_ilib=WORK %then %do; /* but lib is not WORK */
			%work_clean(&_dsn);
		%end;
	%end;

	%if not %macro_isblank(_ds_) %then 	%do;
		data _null_;
			call symput("&_ds_", "&lib..&_dsn");
		run; 
	%end;		

%mend _dstest6;

%macro _example_dstest6;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest6(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest6;
	%ds_print(_dstest6);

	%work_clean(_dstest6);
%mend _example_dstest6;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest6; 
*/

/** \endcond */
