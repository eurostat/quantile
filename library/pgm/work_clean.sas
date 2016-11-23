/** 
## work_clean {#sas_work_clean}
Clean the working directory.

	%work_clean(ds, ...);

### Arguments
`ds` : (_option_) datasets in the `WORK`ing directory to clean; parameters are passed as `parmbuff`,
	_i.e._ comma-separated arguments; If `ds` is not set (or simply not passed), all datasets present
	in the `WORK` directory are 'cleaned'.
	
### Notes
1. The instruction to "clean" (delete) two datasets `ds1` and `ds2` from your  `WORK`ing directory is:

       %work_clean(ds1, ds2);
while the instruction to clean all the `WORK`ing directory is:

    %work_clean;	
2. Use `kill` or `delete` depending whether a dataset is passed or not (again, in the latter case, 
the whole `WORK`ing directory is deleted).
*/ /** \cond */

%macro work_clean/parmbuff /* List of input datasets to delete from WORK library (OPT) */
				;
	%local ds 	/* dataset name read from the list of parameters */
		num; 	/* local increment counter */

	%let num=1;
	%let ds=%scan(&syspbuff,&num);

	%if %macro_isblank(ds) %then %do;
		PROC DATASETS lib=WORK kill nolist;
		quit;
  	%end;
	%else %do;
   		%do %while(&ds ne);
			PROC DATASETS lib=WORK nolist; 
				delete &ds;  
			quit;
   			%let num=%eval(&num+1);
      		%let ds=%scan(&syspbuff,&num);
   		%end;
	%end;
%mend work_clean;

%macro _example_work_clean;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Create and delete a dummy dataset in the working directory;
	%_dstest2;
	/*%if %ds_check(&dsn, lib=WORK)=0 	%then */
	%put Dataset _dstest2 has been created;
	%work_clean(_dstest2);
	%if %ds_check(_dstest2, lib=WORK) %then %put OK: TEST PASSED - Dataset deleted: errcode 1;
	%else 									%put ERROR: TEST FAILED - Dataset deleted: errcode 0;

	%put;
	%put (ii) Create some files in the working directory and delete some of them;
	%_dstest2;
	%_dstest5;
	%_dstest32;
	%_dstest33;
	%_dstest34;
	%put Dataset _dstest2, _dstest5, _dstest32, _dstest33, _dstest34 have been created;
	%work_clean(_dstest2, _dstest5);
	%if not (%ds_check(_dstest2) and %ds_check(_dstest5)) or %ds_check(_dstest32) or %ds_check(_dstest33) or %ds_check(_dstest34) %then 
		%put ERROR: TEST FAILED - All concerned datasets deleted, other preserved;
	%else 						
		%put OK: TEST PASSED - Wrong delete operation;

	%put;
	%put (iii) Delete all working directory;
	%work_clean;
	%if not (%ds_check(_dstest2) and %ds_check(_dstest5) and %ds_check(_dstest32) and %ds_check(_dstest33) and %ds_check(_dstest34)) %then 
		%put ERROR: TEST FAILED - All datasets deleted;
	%else 						
		%put OK: TEST PASSED - Wrong delete operation;

%mend _example_work_clean;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_work_clean; 
*/

/** \endcond */
