/**
## file_delete {#sas_file_delete}
Delete a (external) file given by its name if it exists.

	%let rc=%file_delete(fn);

### Arguments
`fn` : full path and name of external file (!not a fileref!).
  
### Returns
`rc` : the error code of the operation, _i.e._:
		+ 0 if the file `fn` was correctly deleted,
    	+ system error code otherwise.

### Example
Run macro `%%_example_file_delete` for examples.

### See also
[%file_check](@ref sas_file_check), [%file_copy](@ref sas_file_copy).
*/ /** \cond */

%macro file_delete(fn	/* Input filename 	(REQ) */
				);

	%local _rc 	/* temporary file identifier */
		_filrf;	/* file reference */
		rc;		/* output file identifier */
	%let _filrf=_tmpf; /* shall be <8 char long */

	/* assign fileref*/
	%let _rc=%sysfunc(filename(_filrf,&fn));
	%let rc=%sysfunc(fdelete(&_filrf));

	/* deassign the fileref */
	%let _rc=%sysfunc(filename(_filrf));

	&rc
%mend file_delete;

%macro _example_file_delete;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/*%let rc=%file_delete(&eusilc/test/dummy.txt);
	%put rc=&rc;*/
	%put !!! &sysmacroname: Not yet implemented !!!;

	%put;
%mend _example_file_delete;

/** \endcond */

