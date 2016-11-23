/**
## file_check {#sas_file_check}
Check the existence of a file given by its name. If required, also possibly check the format.

	%let ans=%file_check(fn, ext=);

### Arguments
* `fn` : full path and name of external file (!not a fileref!);
* `ext` : (_option_) string representing the extension of desired format (_e.g._, `csv`); 
  	     if not set, the format of the file is not verified.
  
### Returns
`ans` : error code associated to test, _i.e._:
	+ `0` if the file exists (with the right format when `ext` is not empty), or
    + `1` if the file does not exist, or
    + `-1` if the file exists but the format is not the one specified by `ext`.

### Example
Let us consider the file where this macro is defined, and check it actually exists:
	
	%let fn=&G_PING_LIBAUTO/file_check.sas;
	%let ans=%file_check(&fn, ext=SAS);

returns `ans=0`, while:

	%let ans=%file_check(&fn, ext=TXT);
	
returns `ans=-1`.

Run macro `%%_example_file_check` for more examples.

### Note
In short, the error code returned when `ext` is not set is the evaluation of:

	1 - %sysfunc(fileexist(&fn))

### Reference
1. ["Check for existence of a file"](http://support.sas.com/kb/24/577.html).
2. Johnson, J. (2010): ["OBJECT_EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%dir_check](@ref sas_dir_check), [%lib_check](@ref sas_lib_check), [%file_copy](@ref sas_file_copy), 
[%file_delete](@ref sas_file_delete), [%file_name](@ref sas_file_name), [%file_ls](@ref sas_file_ls),
[FILEEXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210912.htm).
*/ /** \cond */

%macro file_check(fn	/* Input filename 									(REQ) */
				, ext= 	/* Name of the extension/format of the input file 	(OPT) */
				, verb= /* Legacy parameter - Ignored 						(OBS) */
				);
	%local _ans /* output answer */
		_len 	/* length of the filename string */
		_iext;	/* position of the extension in the filename string */

  	%if %sysfunc(fileexist(&fn))=1 %then
	 	%let _ans=0; 
  	%else 
   	 	%let _ans=1; 

  	%if &_ans=0 and not %macro_isblank(ext) %then %do;
		%let _len = %sysfunc(length(&fn));
		%let _iext=%sysfunc(find(&fn, ., -&_len));  /* starting from the right */
		%if &_iext>0 %then %do; 
			%let ext=%sysfunc(substr(&fn, &_iext+1, &_len-&_iext));	
		  	%if %upcase(&ext) ne %upcase(&ext) %then
				/* wrong input file: extension found */
		  	   	%let _ans=-1;
		%end;
		%else 		  
			/* input file has no extension */	
			%let _ans=-1;
  	%end;
	
	/* return the answer */
	&_ans
%mend file_check;

%macro _example_file_check;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put Examples of use:;
	%local dfile;

	%put;
	%put (i) Check the existence of...this file in the dataset, no format checking;
	%let dfile = &G_PING_LIBAUTO/file_check.sas;
	%if %file_check(&dfile) %then 	%put ERROR: TEST FAILED - Existing file: errcode -1/1;
	%else 							%put OK: TEST PASSED - Existing file: errcode 0;

	%put;
	%put (ii) Check that same file, specifying CSV format;
	%if %file_check(&dfile, ext=csv)=-1 %then 	%put OK: TEST PASSED - Wrong format: errcode -1;
	%else 											%put ERROR: TEST FAILED - Wrong format: errcode 0/1;

	%put;
	%put (iii) Ibid, specifying SAS format;
	%if %file_check(&dfile, ext=SAS)=0 %then %put OK: TEST PASSED - Correct format: errcode 0;
	%else 										%put ERROR: TEST FAILED - Correct format: errcode -1/1;

	%put;

%mend _example_file_check;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_file_check; 
*/

/** \endcond */
