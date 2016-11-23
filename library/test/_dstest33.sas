/** 
## _DSTEST33 {#sas_dstest33}
Test dataset #33.

	%_dstest33;
	%_dstest33(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest33`:
geo | value
----|------
 BE |  1
 AT |  .
 BG |  2
 LU |  3
 FR |  .
 IT |  4

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest33`.

### Example
To create dataset #33 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest33;
	%ds_print(_dstest33);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest33(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			geo='BE'; value=1; output;
			geo='AT'; value=.; output;
			geo='BG'; value=2; output;
			geo='LU'; value=3; output;
			geo='FR'; value=.; output;
			geo='IT'; value=4; output;
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

%mend _dstest33;

%macro _example_dstest33;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest33(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest33;
	%ds_print(_dstest33);

	%work_clean(_dstest33);
%mend _example_dstest33;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest33; 
*/

/** \endcond */
