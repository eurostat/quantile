/** 
## _dstestlib {#sas_dstestlib}
Test the prior existence of test dataset in `WORK` or test data directory.
	
	%_dstestlib(dsn, _lib_=);

### Argument
`dsn` : name of the test dataset; it is in general of the form: `"_dstestXX"` where
	`XX` defines the number of the test; in practice, `dsn` is passed to this macro
	from the calling macro using `&sysmacroname`.
  
### Returns
`_lib_` : in the macro variable whose name is passed to `_lib_`, the library (location) 
	of the dataset `dsn` whenever it already exists; it is either `WORK` or the default
	test data library (_e.g._, `&G_PING_TESTDB`).

### Note
This macro is not used 'as is', but it is generically called by all datatest macros of the
form `"_dstestXX". 

### See also 
[%ds_check](@ref sas_ds_check).
*/ /** \cond */

%macro _dstestlib(/*input*/	 dsn, 
				  /*output*/ _lib_=);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_lib_) EQ 1,	mac=&_mac,	
			txt=!!! Output macro variable _lib_ not set !!!) %then
		%goto exit;

	%local TESTDB
		_ans 
		_lib;
	%let _lib=;
	
	%if %symexist(G_PING_TESTDB) %then 			%let DEF_TESTDB=&G_PING_TESTDB;
	%else %if %symexist(G_PING_SETUPPATH) %then 	%let DEF_TESTDB=&G_PING_SETUPPATH/test/data/;						
	%else 									%let DEF_TESTDB=/ec/prod/server/sas/0eusilc; 
	libname TESTDB "&DEF_TESTDB"; 

	%if not %ds_check(&dsn, lib=WORK) %then 			%let _lib=WORK;
	%else %if not %ds_check(&dsn, lib=TESTDB) %then 	%let _lib=TESTDB;

	data _null_;
		call symput("&_lib_", "&_lib");
	run;
	
	%exit:
%mend _dstestlib;

%macro _example_dstestlib;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;

	%put !!! not implemented yet !!!;

%mend _example_dstestlib;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstestlib; 
*/

/** \endcond */
