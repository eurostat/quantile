/** 
## _DSTEST1001 {#sas_dstest1001}
Test dataset #1001.

	%_dstest1001;
	%_dstest1001(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest1001`:
i	|strata|
----|------|
1	|  1   |
2	|  1   |
3	|  1   |
4	|  1   |
...	| ...  |
100	|  1   |
101 |  2   |
102 |  2   |
...	| ...  |
200	|  2   |
201 |  3   |
202 |  3   |
...	| ...  |
900	|  9   |
901	|  10  |
902	|  10  |
...	| ...  |
999	|  10  |
1000|  10  |

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest1000`.

### Example
To create dataset #1001 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest1001;
	%ds_print(_dstest1001);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest1001(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			do i = 1 to 1000 ;
				strata = ceil(i/100) ;
				output ;
			end ;
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

%mend _dstest1001;

%macro _example_dstest1001;
	%if %symexist(EUSILC) EQ 0 %then %do; 
		%include "/ec/prod/server/sas/0eusilc/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest1001(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest1001;
	%ds_print(_dstest1001);

	%work_clean(_dstest1001);
%mend _example_dstest1001;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
*/
%_example_dstest1001; 

/** \endcond */
