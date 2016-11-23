/** 
## file_name {#sas_file_name}
Return the basename, extension or library (directory) of a given dataset.

	%let name=%file_name(path, res=file);

### Arguments
* `path` : full path of a file (_e.g._, a SAS file);
* `res` : (_option_) string representing the result to output; it is either `ext` for
	the extension of the dataset (_e.g._, `sas7bdat`), or `dir` for the directory/library
	where the dataset is stored, or `base` (default when res is not passed) for the 
	basename of the dataset to be returned, or `file` for the complete filename without
	its path (_i.e._, both basename and extension concatenated together when the extension
	is present, the basename only otherwise); default: `res=file`, _i.e._ the filename is
	returned.
  
### Returns
`name` : desired output string depending on input `res` value. 

### Examples
Let us consider the file where this macro is defined, then the operation:

	%let fn=&G_PING_LIBAUTO/file_name.sas;
	%let name=%file_name(&fn, res=base);

returns `name=file_name` for instance, while:

	%let name=%file_name(&fn, res=dir);

returns `name=&G_PING_LIBAUTO`, and:

	%let name=%file_name(&fn, res=file);

returns `name=file_name.sas`.

Run macro `%%_example_file_name` for more examples.

### Note
* There is no test of the actual existence of any file associated to the considered path. 
* The directory returned (_i.e._ when `res=dir`) is always a path without the final '/'; in the case
a simple basename is passed, an empty directory path is returned.

### See also
[%file_check](@ref sas_file_check).
*/ /** \cond */

%macro file_name(path		/* Full path of a file 						(REQ) */
				, res=file	/* Flag used to specify the output returned	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&res), type=CHAR, set=EXT DIR BASE FILE) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong input RES parameter - Must be EXT, DIR or BASE !!!)) %then 
		%goto exit; /*%let res=;*/

	%local _fn 	/* temporary filename */
		_bn		/* temporary baseename */
		_ext	/* temporary extension */
		_dir 	/* temporary directory name */
		_ldir;	/* length of the directory name */

	%let _fn=%sysfunc(scan(&path,-1,'/')); 
	%let _bn=%sysfunc(scan(&_fn, 1, '.')); /* directly: %sysfunc(scan(&path,-2)); */
	%let _ext=%sysfunc(scan(&_fn, 2, '.' )); /* directly: %sysfunc(scan(&path,-1)); */

	%let _ldir=%length(&path) - %length(&_bn) - %length(&_ext);
	/* minus 1 for the '.'  in between basename and extension */ 
	%if not %macro_isblank(_ext) %then %let _ldir=%eval(&_ldir - 1);
	/*	* minus 1 for the last '/' at the end of the directory name */
	%if &_ldir>0 %then 	%let _dir = %qsubstr(&path, 1, %eval(&_ldir - 1));
	%else				%let _dir=;

	 /* return the updated value of res 
	  	!!! note: not ';' character to close the line!!! */
	%if &res=ext %then %do;		
		&_ext
	%end;
	%else %if &res=dir %then %do;	
		&_dir
	%end;
	%else %if &res=base %then %do;		
		&_bn
	%end;
	%else %if &res=file %then %do; 
		%if %macro_isblank(_ext) %then %do;		
			&_bn
		%end;
		%else %do;
			&_bn..&_ext
		%end;
	%end;

	%exit:
%mend file_name;


%macro _example_file_name;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local fn;

	%let res=DUMMY;
	%let fn=file_name.sas;
	%put;
	%put (i) Test of file "&fn" with dummy parameter res=&res;
	%if %macro_isblank(%file_name(%quote(&fn), res=&res)) %then 	%put OK: TEST PASSED - No output returned;
	%else 															%put ERROR: TEST FAILED - Wrong output returned;

	%put;
	%put (ii) Retrieve the basename (res=&res) of file "&fn";
	%if %macro_isblank(%file_name(%quote(&fn), res=&res)) %then 	%put OK: TEST PASSED - Empty directory returned;
	%else 															%put ERROR: TEST FAILED - Wrong directory returned;

	%let fn=&G_PING_LIBAUTO/&fn;

	%let res=base;
	%put;
	%put (iii) Retrieve the basename (res=&res) of file "&fn";
	%let out=file_name;
	%if %file_name(%quote(&fn), res=&res)=%quote(&out) %then 	%put OK: TEST PASSED - Basename returned: &out;
	%else 														%put ERROR: TEST FAILED - Wrong basename returned;

	%let res=ext;
	%put;
	%put (iv) Retrieve the extension (res=&res) of file "&fn";
	%let out=sas;
	%if %file_name(%quote(&fn), res=&res)=%quote(&out) %then 	%put OK: TEST PASSED - Extension returned: &out;
	%else 														%put ERROR: TEST FAILED - Wrong extension returned;

	%let res=file;
	%put;
	%put (v) Retrieve the filename (res=&res) of file "&fn";
	%let out=file_name.sas;
	%if %file_name(%quote(&fn), res=&res)=%quote(&out) %then 	%put OK: TEST PASSED - Extension returned: &out;
	%else 														%put ERROR: TEST FAILED - Wrong extension returned;

	%let res=dir;
	%put;
	%put (vi) Retrieve the full path (directory, res=&res) of file "&fn";
	%let out=&G_PING_LIBAUTO;
	%if %file_name(%quote(&fn), res=&res)=%quote(&out) %then 	%put OK: TEST PASSED - Directory returned: &out;
	%else 														%put ERROR: TEST FAILED - Wrong directory returned;

	%put;

%mend _example_file_name;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_file_name; 
*/

/** \endcond */
