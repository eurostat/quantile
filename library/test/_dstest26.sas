/** 
## _DSTEST26 {#sas_dstest26}
Test dataset #26.

	%_dstest26;
	%_dstest26(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest26`:
geo | time 
----|-------
 BE |  2014    
 AT |  2013  
 BG |  2012  
 LU |  2014 
 IT |  2013 

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest26`.

### Example
To create dataset #26 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest26;
	%ds_print(_dstest26);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest26(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			geo='BE'; time=2014; output; 
			geo='AT'; time=2013; output;
			geo='BG'; time=2012; output; 
			geo='LU'; time=2014; output;
			geo='IT'; time=2013; output;
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

%mend _dstest26;

%macro _example_dstest26;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest26(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest28;
	%ds_print(_dstest26);

	%work_clean(_dstest26);
%mend _example_dstest26;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest26; 
*/

/** \endcond */
