/** 
## str_dsname {#sas_str_dsname}
Find the first unused dataset (named with a generic name), adding a prefix and a numeric suffix 
as large as necessary to make it unique.

	%let name=%str_dsname(name, prefix=_, lib=WORK);
  
### Arguments
* `name` : string to be used as a core name for the dataset;
* `prefix` : (_option_) leading string/character to be used; default: `prefix=_`;
* `lib` : (_option_) name of the library where the desired dataset shall be found; by default: 
	empty, _i.e._ `WORK` is used.

### Returns
`name` : unique name of the desired dataset. 

### Examples
Consider the situation where some dataset `_dsn`, `_dsn1` and `_dsn2` already exist in the `WORK`ing 
library, then:

	%let name=%str_dsname(dsn, prefix=_);

returns `name=_dsn3`.

Run macro `%%_example_str_dsname` for examples.

### Note
This macro is derived from the [`%%MultiTransposeNewDatasetName` macro](http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html) 
of L. Joseph.

### See also
[%ds_check](@ref sas_ds_check), [%ds_create](@ref sas_ds_create), [%str_dslist](@ref sas_str_dslist),
[EXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210903.htm),
[%MultiTranspose][http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html].
*/ /** \cond */

%macro str_dsname(name		/* Name to be used */
				, prefix=
				, lib=
				);
	%local _mac;
	%let   _mac=&sysmacroname;

	%local dsname;	/* output name */
	%let dsname=;

	/* check input parameters */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&name, type=CHAR) NE 0, mac=&_mac,		
			txt=!!! Wrong type for parameter NAME !!!) %then
		%goto exit;

	%if not %macro_isblank(prefix) %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&prefix, type=CHAR) NE 0, mac=&_mac,		
				txt=!!! Wrong type for parameter PREFIX !!!) %then
			%goto exit;
	%end;

	%if %macro_isblank(lib) %then 		%let lib=WORK;
	%if %error_handle(ErrorInputLibrary, 
			%lib_check(&lib) NE 0, mac=&_mac,		
			txt=%bquote(!!! Input library %upcase(&lib) not found !!!)) %then 
		%goto exit;

	/* core of the macro */
	%local i 	/* loop increment */
		pname;	/* generic temporary tested name */

	%let pname=%sysfunc(compress(&prefix.&name));
	%let dsname=&pname;

	%let i=1;
	%do %while(%sysfunc(exist(&lib..&dsname, data))/*%ds_check(&dsname, lib=&lib) EQ 0*/); 
		%let dsname=&pname.&i;
		%let i = %eval(&i+1);
	%end;

	%exit:
	&dsname
%mend str_dsname;

%macro _example_str_dsname;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local dsn name;
	%let dsn=TMP&sysmacroname;
	/* just to be sure */ %work_clean(_&dsn, _&dsn.1, _&dsn.2);

	%put;
	%put (i) Test whether the name can be used since it is "free" in WORK;
	%let name=%str_dsname(&dsn);
	%if &name = &dsn %then 		%put OK: TEST PASSED - Unused input name: &dsn;
	%else 						%put ERROR: TEST FAILED - Wrong result returned: &name; 

	%put;
	%put (ii) Ibid after _&dsn have been created;
	DATA _&dsn;	a=1; output; run;
	%let name=%str_dsname(&dsn, prefix=_);
	%if &name = _&dsn.1 %then 	%put OK: TEST PASSED - First unused input name: _&dsn.1;
	%else 						%put ERROR: TEST FAILED - Wrong result returned: &name; 
	
	%put;
	%put (iii) Ibid after _&dsn.1 and _&dsn.2 have also been created;
	DATA _&dsn.1; a=1; output; run;
	DATA _&dsn.2; a=1; output; run;
	%let name=%str_dsname(&dsn, prefix=_);
	%if &name = _&dsn.3 %then 	%put OK: TEST PASSED - First unused input name: _&dsn.3;
	%else 						%put ERROR: TEST FAILED - Wrong result returned: &name; 

	%work_clean(_&dsn, _&dsn.1, _&dsn.2);
%mend _example_str_dsname;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_str_dsname;
*/

/** \endcond */

