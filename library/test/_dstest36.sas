/** 
## _DSTEST36 {#sas_dstest36}
Test dataset #36.

	%_dstest36;
	%_dstest36(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest36`:
 geo | time | value
-----|------|------
EU27 | 2006 |  1
EU25 | 2004 |  2
EA13 | 2001 |  3
EU27 | 2007 |  4
EU15 | 2004 |  5
EA12 | 2007 |  6
EA12 | 2002 |  7
GR	 | 2005 |  8
EL	 | 2003 |  9
GR02 | 2003 |  10
EU15 | 2015 |  11
NMS12| 2015 |  12

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest36`.

### Example
To create dataset #36 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest36;
	%ds_print(_dstest36);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest36(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			array refvals{12} $ _TEMPORARY_ ("1",    "2",    "3",    "4",    "5",    "6",    "7",    "8",    "9",    "10",   "11",   "12" );
			array geos{12} $5 _TEMPORARY_   ('EU27', 'EU25', 'EA13', 'EU27', 'EU15', 'EA12', 'EA12', 'GR',   'EL',   'GR02', 'EU15', 'NMS12' );
			array years{12} _TEMPORARY_     (2006,   2004,   2001,   2007,   2004,   2007,   2002,   2005,   2003,   2003,   2015,   2015 );
			drop n;
			do n = 1 to 12;
				geo = geos{n};
				time = years{n};
				value = refvals{n};
				output;
			end;
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

%mend _dstest36;

%macro _example_dstest36;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest36(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest36;
	%ds_print(_dstest36);

	%work_clean(_dstest36);
%mend _example_dstest36;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest36; 
*/

/** \endcond */
