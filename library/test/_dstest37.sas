/** 
## _DSTEST37 {#sas_dstest37}
Test dataset #37.

	%_dstest37;
	%_dstest37(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest37`:
geo | time | EQ_INC20 | RB050a
----|------|----------|-------
 BE | 2009 |    10    |   10 
 MK | 2010 |    50    |   10
 EE | 2011 |    60    |   10
 FI | 2012 |    20    |   20
 UK | 2013 |    10    |   20
 IT | 2015 |    40    |   20

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) set for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest37`.

### Example
To create dataset #37 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest37;
	%ds_print(_dstest37);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest37(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			geo='BE'; time=2009; EQ_INC20=10; RB050a=10; output ;
			geo='MK'; time=2011; EQ_INC20=60; RB050a=10; output ;
			geo='EE'; time=2011; EQ_INC20=60; RB050a=10; output ;
			geo='FI'; time=2012; EQ_INC20=20; RB050a=20; output ;
			geo='UK'; time=2013; EQ_INC20=10; RB050a=20; output ;
			geo='IT'; time=2015; EQ_INC20=40; RB050a=20; output ;
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

%mend _dstest37;

%macro _example_dstest37;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest37(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest37;
	%ds_print(_dstest37);

	%work_clean(_dstest37);
%mend _example_dstest37;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest37; 
*/

/** \endcond */
