/** 
## _DSTEST10 {#sas_dstest10}
Test dataset #10.

	%_dstest10;
	%_dstest10(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest10`:
geo | EA18 | EA19 | EEA18| EEA28| EU27 | EU28 | EFTA
----|------|------|------|------|------|------|------
AT	| 1999 | 1999 | 1994 | 1994 | 1995 | 1995 | 1960
AT	| 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 1995
BE	| 1999 | 1999 | 1994 | 1994 | 1957 | 1957 |  .
BE	| 2500 | 2500 | 2500 | 2500 | 2500 | 2500 |  .
BG	|  .   |  .	  |  .   |  .   | 2007 | 2007 |  .
BG	|  .   |  .	  |  .   |  .   | 2500 | 2500 |  .
CH	|  .   |  .	  |  .   |  .   |  .   |  .   | 1960
CH	|  .   |  .	  |  .   |  .   |  .   |  .   | 2500
CY	| 2008 | 2008 |  .   | 2005 | 2004 | 2004 |  .
CY	| 2500 | 2500 |  .   | 2500 | 2500 | 2500 |  .
CZ	|  .   |  .   |  .   | 2005 | 2004 | 2004 |  .
CZ	|  .   |  .	  |  .   | 2500 | 2500 | 2500 |  .
DE	| 1999 | 1999 | 1994 | 1994 | 1957 | 1957 |  .
DE	| 2500 | 2500 | 2500 | 2500 | 2500 | 2500 |  .

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest10`.

### Example
To create dataset #10 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest10;
	%ds_print(_dstest10);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest10(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			geo='AT'; EA18=1999; EA19=1999; EEA18=1994; EEA28=1994; EU27=1995; EU28=1995; EFTA=1960; output;
			geo='AT'; EA18=2500; EA19=2500; EEA18=2500; EEA28=2500; EU27=2500; EU28=2500; EFTA=1995; output;
			geo='BE'; EA18=1999; EA19=1999; EEA18=1994; EEA28=1994; EU27=1957; EU28=1957; EFTA=.;  	 output;
			geo='BE'; EA18=2500; EA19=2500; EEA18=2500; EEA28=2500; EU27=2500; EU28=2500; EFTA=.; 	 output;
			geo='BG'; EA18=.; 	 EA19=.; 	EEA18=.; 	EEA28=.; 	EU27=2007; EU28=2007; EFTA=.; 	 output;
			geo='BG'; EA18=.; 	 EA19=.; 	EEA18=.; 	EEA28=.; 	EU27=2500; EU28=2500; EFTA=.; 	 output;
			geo='CH'; EA18=.; 	 EA19=.; 	EEA18=.; 	EEA28=.; 	EU27=.;    EU28=.; 	  EFTA=1960; output;
			geo='CH'; EA18=.; 	 EA19=.; 	EEA18=.; 	EEA28=.; 	EU27=.;    EU28=.;    EFTA=2500; output;
			geo='CY'; EA18=2008; EA19=2008; EEA18=.; 	EEA28=2005; EU27=2004; EU28=2004; EFTA=.; 	 output;
			geo='CY'; EA18=2500; EA19=2500; EEA18=.; 	EEA28=2500; EU27=2500; EU28=2500; EFTA=.; 	 output;
			geo='CZ'; EA18=.; 	 EA19=.; 	EEA18=.; 	EEA28=2005; EU27=2004; EU28=2004; EFTA=.; 	 output;
			geo='CZ'; EA18=.; 	 EA19=.; 	EEA18=.; 	EEA28=2500; EU27=2500; EU28=2500; EFTA=.; 	 output;
			geo='DE'; EA18=1999; EA19=1999; EEA18=1994; EEA28=1994; EU27=1957; EU28=1957; EFTA=.;	 output;
			geo='DE'; EA18=2500; EA19=2500; EEA18=2500; EEA28=2500; EU27=2500; EU28=2500; EFTA=.; 	 output;		
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

%mend _dstest10;

%macro _example_dstest10;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest10(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest28;
	%ds_print(_dstest10);

	%work_clean(_dstest10);
%mend _example_dstest10;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest10; 
*/

/** \endcond */
