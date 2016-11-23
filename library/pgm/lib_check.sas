/** 
## lib_check {#sas_lib_check}
Check the existence of a library.

	%let ans=%lib_check(lib);

### Argument
`lib` : library reference.

### Returns
`ans` : the error code of the test, _i.e._:
		+ `0` if the library reference exists,
    	+ `> 0` (error: "lib does not exist") if the library reference does not exist,
		+ `< 0` (error) if the library reference exists, but the pathname is in question. 

The latter case can happen when a `LIBNAME` statement is provided a non-existent pathname or the physical path 
has been removed, the library reference will exist, but it will not actually point to anything.

### Note
In short, the error code returned is the evaluation of:

	%sysfunc(libref(&lib));

### Reference
Johnson, J. (2010): ["OBJECT_EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%dir_check](@ref sas_dir_check), [%file_check](@ref sas_file_check).
*/ /** \cond */ 

%macro lib_check(lib 	/* Input library whose existence is checked (REQ) */
				, verb= /* Legacy parameter - Ignored 	(OBS) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(EmptyInputVariable, 
			%macro_isblank(lib) EQ 1, mac=&_mac,
			txt=!!! No library argument passed !!!) %then 
		%goto exit;

	%sysfunc(libref(&lib))
		
	%exit:
%mend lib_check;

%macro _example_lib_check;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/* run and test your macro with these parameters */
	%put;
	%put (i) Invoke the macro, pass WORK reference to test...;
	%if %lib_check(WORK) %then 		%put ERROR: TEST FAILED - WORK not recognised: errcode >0;
	%else 							%put OK: TEST PASSED - WORK recognised: errcode 0;

	%put;
	%put (ii) Invoke the macro, pass fake DUMMLIB reference to test...;
	%if %lib_check(DUMMLIB) %then 	%put OK: TEST PASSED - fake DUMMLIB not recognised: errcode >0;
	%else 							%put ERROR: TEST FAILED - fake DUMMLIB recognised: errcode 0;

	%put;
%mend _example_lib_check;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_lib_check; 
*/

/** \endcond */
