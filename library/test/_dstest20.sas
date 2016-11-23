/** 
## _DSTEST20 {#sas_dstest20}
Test dataset #20.

	%_dstest20;
	%_dstest20(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest20`:
 breakdown | variable | start | end | fmt1_dummy | fmt2_dummy | fmt3_dummy | fmt4_dummy
-----------|----------|-------|-----|------------|------------|------------|------------
  label1   |   DUMMY  |   1   |  5	|      1	 |      0	  |      1	   |      0
  label2   |   DUMMY  |   1   |  3	|      1	 |      1	  |      0	   |      0  
  label2   |   DUMMY  |   5   |  5	|      1	 |      1 	  |      0	   |      0
  label2   |   DUMMY  |   8   |  10	|      1	 |      1 	  |      0	   |      0
  label2   |   DUMMY  |   12  |  12	|      1	 |      1 	  |      0	   |      0
  label3   |   DUMMY  |   1   |  10	|      0	 |      1 	  |      1	   |      0
  label3   |   DUMMY  |   20  |HIGH |      0	 |      1	  |      1	   |      0
  label4   |   DUMMY  |   10  |  20	|      0	 |      0	  |      0	   |      1
  label5   |   DUMMY  |   10  |  12	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   15  |  17	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   19  |  20	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   30  |HIGH	|      0	 |      1	  |      1	   |      0

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table).

### Example
To create dataset #20 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest20;
	%ds_print(_dstest20);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest20(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			breakdown="label1"; variable="DUMMY"; start=1;  end="5   ";  fmt1_dummy=1; fmt2_dummy=0; fmt3_dummy=1; fmt4_dummy=0; output;
			breakdown="label2"; variable="DUMMY"; start=1;  end="3";  fmt1_dummy=1; fmt2_dummy=1; fmt3_dummy=0; fmt4_dummy=0; output;
			breakdown="label2"; variable="DUMMY"; start=5;  end="5";  fmt1_dummy=1; fmt2_dummy=1; fmt3_dummy=0; fmt4_dummy=0; output;
			breakdown="label2"; variable="DUMMY"; start=8;  end="10"; fmt1_dummy=1; fmt2_dummy=1; fmt3_dummy=0; fmt4_dummy=0; output;
			breakdown="label2"; variable="DUMMY"; start=12; end="12"; fmt1_dummy=1; fmt2_dummy=1; fmt3_dummy=0; fmt4_dummy=0; output;
			breakdown="label3"; variable="DUMMY"; start=1;  end="10"; fmt1_dummy=0; fmt2_dummy=1; fmt3_dummy=1; fmt4_dummy=0; output;
			breakdown="label3"; variable="DUMMY"; start=20; end="HIGH"; fmt1_dummy=0; fmt2_dummy=1; fmt3_dummy=1; fmt4_dummy=0; output;
			breakdown="label4"; variable="DUMMY"; start=10; end="20"; fmt1_dummy=0; fmt2_dummy=0; fmt3_dummy=0; fmt4_dummy=1; output;
			breakdown="label5"; variable="DUMMY"; start=10; end="12"; fmt1_dummy=0; fmt2_dummy=1; fmt3_dummy=1; fmt4_dummy=0; output;
			breakdown="label5"; variable="DUMMY"; start=15; end="17"; fmt1_dummy=0; fmt2_dummy=1; fmt3_dummy=1; fmt4_dummy=0; output;
			breakdown="label5"; variable="DUMMY"; start=19; end="20"; fmt1_dummy=0; fmt2_dummy=1; fmt3_dummy=1; fmt4_dummy=0; output;
			breakdown="label5"; variable="DUMMY"; start=30; end="HIGH"; fmt1_dummy=0; fmt2_dummy=1; fmt3_dummy=1; fmt4_dummy=0; output;
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

%mend _dstest20;

%macro _example_dstest20;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest20(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest20;
	%ds_print(_dstest20);

	%work_clean(_dstest20);
%mend _example_dstest20;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest20; 
*/

/** \endcond */
