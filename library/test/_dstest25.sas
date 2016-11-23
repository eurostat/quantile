/** 
## _DSTEST25 {#sas_dstest25}
Test dataset #25.

	%_dstest25;
	%_dstest25(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest25`:
geo | value | time | unrel | unit 
----|-------|------|-------|------
 BE |   1   | 2014 |   1   |  EUR   
 BE |   2   | 2013 |   2   |  EUR
 BE |   3   | 2012 |   0   |  EUR
 AT |   1   | 2013 |   1   |  EUR
 AT |   2   | 2012 |   0   |  EUR
 AT |   3   | 2011 |   2   |  EUR
 AT |   4   | 2010 |   0   |  EUR
 BG |   1   | 2013 |   0   |  EUR
 BG |   2   | 2012 |   2   |  EUR
 LU |   1   | 2014 |   0   |  EUR
 LU |   2   | 2013 |   0   |  EUR
 LU |   3   | 2012 |   1   |  EUR
 FR |   1   | 2014 |   2   |  EUR
 FR |   2   | 2013 |   0   |  EUR
 FR |   3   | 2012 |   1   |  EUR
 IT |   1   | 2013 |   2   |  EUR
 IT |   2   | 2012 |   1   |  EUR

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest25`. 

### Example
To create dataset #25 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest25;
	%ds_print(_dstest25);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest25(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			geo='BE'; value=1; time=2014; unrel=1; unit='EUR'; output; /* this one */
			geo='BE'; value=2; time=2013; unrel=2; unit='EUR'; output;
			geo='BE'; value=3; time=2012; unrel=0; unit='EUR'; output;
			geo='AT'; value=1; time=2013; unrel=1; unit='EUR'; output; /* this one */
			geo='AT'; value=2; time=2012; unrel=0; unit='EUR'; output;
			geo='AT'; value=3; time=2011; unrel=2; unit='EUR'; output;
			geo='AT'; value=4; time=2010; unrel=0; unit='EUR'; output;
			geo='BG'; value=1; time=2013; unrel=0; unit='EUR'; output;
			geo='BG'; value=2; time=2012; unrel=2; unit='EUR'; output; /* this one */
			geo='LU'; value=1; time=2014; unrel=0; unit='EUR'; output; /* this one */
			geo='LU'; value=2; time=2013; unrel=0; unit='EUR'; output;
			geo='LU'; value=3; time=2012; unrel=1; unit='EUR'; output;
			geo='FR'; value=1; time=2014; unrel=2; unit='EUR'; output;
			geo='FR'; value=2; time=2013; unrel=0; unit='KOPECK'; output; /* not this one: wrong unit */
			geo='FR'; value=3; time=2012; unrel=1; unit='EUR'; output;
			geo='IT'; value=1; time=2013; unrel=2; unit='EUR'; output; /* this one */
			geo='IT'; value=2; time=2012; unrel=1; unit='EUR'; output;
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

%mend _dstest25;

%macro _example_dstest25;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest25(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest28;
	%ds_print(_dstest25);

	%work_clean(_dstest25);
%mend _example_dstest25;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest25; 
*/

/** \endcond */
