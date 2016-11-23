/** 
## _DSTEST38 {#sas_dstest38}
Test dataset #38.

	%_dstest38;
	%_dstest38(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest38`:
geo | EQ_INC20 | RB050a
----|----------|----------| 
 BE | 10       |   10 
 MK | 50       |   10
 MK | 60       |   10
 MK | 20       |   20
 UK | 10       |   20
 IT | 40       |   20

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) set for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest38`.

### Examples
To create dataset #38 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest38;
	%ds_print(_dstest38);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest38(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			geo='BE';  EQ_INC20=10; RB050a=10; output ;
			geo='MK';  EQ_INC20=50; RB050a=10; output ;
			geo='MK';  EQ_INC20=60; RB050a=10; output ;
			geo='MK';  EQ_INC20=20; RB050a=20; output ;
			geo='UK';  EQ_INC20=10; RB050a=20; output ;
			geo='IT';  EQ_INC20=40; RB050a=20; output ;
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

	%if not %macro_isblank(_ds_) %then %do;
		data _null_;
			call symput("&_ds_", "&lib..&_dsn");
		run; 
	%end;		

%mend _dstest38;

%macro _example_dstest38;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest38(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest38;
	%ds_print(_dstest38);

	%work_clean(_dstest38);
%mend _example_dstest38;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest38; 
*/

/** \endcond */
