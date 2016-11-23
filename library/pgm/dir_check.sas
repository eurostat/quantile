/** 
## dir_check {#sas_dir_check}
Check the existence of a directory.

	%let ans=%dir_check(dir);

### Arguments
* `dir` : a full path directory.

### Returns
`ans` : error code of the test of existence, _i.e._:
		+ `0` when the directory exists (and can be opened), or
    	+ `1` (error) when the directory does not exist, or
    	+ `-1` (error) when the directory exists but cannot be opened.

### Example
Just try on your "root" path, so that:

	%let ans=&dir_check(&G_PING_ROOTPATH);

will return `ans=0`.

Run macro `%%_example_dir_check` for more examples.

### See also
[%ds_check](@ref sas_ds_check), [%lib_check](@ref sas_lib_check), [%file_check](@ref sas_file_check),
[FEXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210817.htm),
[FILENAME](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210819.htm),
[DOPEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000209538.htm).
*/ /** \cond */

%macro dir_check(dir	/* Name of input directory whose existence is checked 	(REQ) */
				, verb= /* Legacy parameter - Ignored 							(OBS) */
				) ;

	%local __ans /* output answer */
		_rc 	/* file identifier */
		_fref 	/* file reference */
		_did;	/* opener reference */

    %let _fref=_TMPFILE;
	/* assign the file ref */
	%let _rc = %sysfunc(filename(_fref, &dir)) ;

	%if not %sysfunc(fexist(&_fref)) %then %do;
		/* %sysexec md   &dir ;  to create folder if doesn't exist 
		* %put %sysfunc(sysmsg()) The directory has been created. ;*/
		%let __ans=1; 
		%*if &verb=yes %then %put Directory %upcase(&dir) does not exist;
		%goto exit;
	%end;

	%let _did=%sysfunc(dopen(&_fref));
	/* directory opened successfully */
   	%if &_did ne 0 %then %do;
      	%let __ans=0;
 		%*if &verb=yes %then %put Directory %upcase(&dir) opens;
     	%let _rc=%sysfunc(dclose(&_did));
   	%end;
	%else %do;
      	%let __ans=-1;
  		%*if &verb=yes %then %put Directory %upcase(&dir) does not open;
  	%end;

	/* deassign the file ref */
   	%let _rc=%sysfunc(filename(_fref));

	%exit:
	&__ans

%mend dir_check ;

%macro _example_dir_check;	
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let dir=&G_PING_ROOTPATH;
	%put;
	%put (i) Test EU-SILC production path;
	%if %dir_check(&dir) = 0 %then 		%put OK: TEST PASSED - Existing dataset: errcode 0;
	%else								%put ERROR: TEST FAILED - Existing dataset: errcode 1;

	%let dir=&G_PING_ROOTPATH/Certainly_does_not_exist_directory/;
	%put;
	%put (ii) What about this path: %upcase(&dir);
	%if %dir_check(&dir) = 1 %then 		%put OK: TEST PASSED - Dummy dataset: errcode 1;
	%else 								%put ERROR: TEST FAILED - Dummy dataset: errcode 0;

	%put;
%mend _example_dir_check;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dir_check; 
*/

/** \endcond */
