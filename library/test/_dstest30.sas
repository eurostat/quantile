/** 
## _DSTEST30 {#sas_dstest30}
Test dataset #30.

	%_dstest30;
	%_dstest30(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest30`:
geo | value 
----|-------
 BE |  0    
 AT |  0.1  
 BG |  0.2  
 '' |  0.3 
 FR |  0.4  
 IT |  0.5 

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest30`.
	
### Examples
To create dataset #30 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest30;
	%ds_print(_dstest30);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest30(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			geo='AT'; value=0; output;
			geo='BE'; value=0.1; output;
			geo='BG'; value=0.2; output;
			geo='';   value=0.3; output;
			geo='FR'; value=0.4; output;
			geo='IT'; value=0.5; output;
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
		%if &_ilib=WORK %then %do;
			%work_clean(&_dsn);
		%end;
	%end;

	%if not %macro_isblank(_ds_) %then 	%do;
		data _null_;
			call symput("&_ds_", "&lib..&_dsn");
		run; 
	%end;		

%mend _dstest30;

%macro _example_dstest30;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest30(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest30;
	%ds_print(_dstest30);

	%work_clean(_dstest30);
%mend _example_dstest30;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest30; 
*/

/** \endcond */
