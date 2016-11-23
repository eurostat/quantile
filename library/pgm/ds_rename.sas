/** 
## ds_rename {#sas_ds_rename}
Rename one or more datasets in the same SAS library.

	%ds_rename(olddsn, newdsn, lib=WORK);

### Arguments
* `olddsn` : (list of) old name(s) of reference dataset(s);
* `newdsn` : (list of) new name(s); must be of the same length as `olddsn`;
* `lib` : (_option_) name of the library where the dataset(s) is (are) stored; default: `lib=WORK`.
	
### Note
In short, this macro runs:

	PROC DATASETS;
		%do i=1 %to %list_length(&olddsn);
			CHANGE %scan(&olddsn,&i)=%scan(&newdsn,&i);
		%end;
	quit;

### See also
[CHANGE](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000247645.htm).
*/ /** \cond */

%macro ds_rename(olddsn		/* (List of) old name(s) of datasets 					(REQ) */
				, newdsn	/* (List of) new name(s) of datasets 					(REQ) */
				, lib=		/* Name of the library where the datasets are stored 	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(lib)	%then 	%let lib=WORK;

	%local i 	/* local increment counter */
		num; 	/* length of input lists */

	%let num=%list_length(&olddsn);
	%if %error_handle(ErrorInputParameter, 
			&num NE %list_length(&newdsn), mac=&_mac,		
			txt=!!! Input parameters OLDDSN and NEWDSN must be of same length !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	PROC DATASETS lib=&lib nolist;
		%do i=1 %to %list_length(&olddsn);
			%let _odsn=%scan(&olddsn,&i);
			%let _ndsn=%scan(&newdsn,&i);
			%if %error_handle(WarningInputParameter, 
					%ds_check(&_ndsn, lib=&lib) EQ 0, mac=&_mac,		
					txt=%bquote(!!! Dataset %upcase(&_ndsn) already exists in &lib - Skip renaming of %upcase(&_odsn) !!!),
					verb=warn) %then
				%goto next;
			CHANGE &_odsn=&_ndsn;
			%next:
		%end;
	quit;

	%exit:
%mend ds_rename;

%macro _example_ds_rename;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Create test dataset #1 and rename it;
	%_dstest1;
	%ds_rename(_dstest1, _dummy1);
	%if %ds_check(_dummy1) EQ 0 and %ds_check(_dstest1) EQ 1 %then 	
		%put OK: TEST PASSED - Dataset renamed: _dummy1;
	%else 									
		%put ERROR: TEST FAILED - Dataset not renamed;

	%put;
	%put (ii) Create three datasets: test datasets #1, #2 and #3, and try to rename them;
	%_dstest1;
	%_dstest2;
	%_dstest5;
	%ds_rename(_dstest1 _dstest2 _dstest5, _dummy1 _dummy2 _dummy5);
	%if %ds_check(_dstest1) EQ 0 and %ds_check(_dummy1) EQ 0 and %ds_check(_dummy2) EQ 0 and %ds_check(_dummy5) EQ 0 %then 	
		%put OK: TEST PASSED - Datasets dstest2 and _dstest5 renamed: _dummy2 and _dummy5, _dstest1 unchanged;
	%else 									
		%put ERROR: TEST FAILED - Datasets not properly renamed;

	%put;

	%work_clean(_dummy1, _dummy2, _dummy5, _dstest1);
%mend _example_ds_rename;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_rename; 
*/

/** \endcond */
