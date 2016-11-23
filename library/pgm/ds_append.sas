/** 
## ds_append {#sas_ds_append}
Conditionally append reference datasets to a master dataset using multiple occurences of `PROC APPEND`.

	%ds_append(dsn, idsn, icond=, drop=, cond=, lib=WORK, ilib=WORK);

### Arguments
* `dsn` : input master dataset;
* `idsn` : (list of) input reference dataset(s) to append to the master dataset;
* `drop` : (_option_) list of variable to remove from output dataset; `_ALL_` `_NONE_`
* `icond`: (_option_) condition to apply to the input dataset;
* `cond`: (_option_) condition to apply to the output dataset;
* `lib` : (_option_) name of the library with (all) reference dataset(s); default: `olib=WORK`;
* `ilib` : (_option_) name of the library with master dataset; default: `ilib=WORK`.

### Returns
The table `dsn` is updated using datasets in `idsn`.

### Examples
Let us consider test dataset #32 in `WORK`ing library:
geo	   | value  
:-----:|-------:
BE	   |      0 
AT	   |     0.1
BG     |     0.2
LU     |     0.3
FR     |     0.4
IT     |     0.5
and update it using test dataset #33:
geo	   | value  
:-----:|-------:
BE	   |     1 
AT	   |     .
BG     |     2
LU     |     3
FR     |     .
IT     |     4
For that purpose, we can run for the macro `%%ds_update ` using the `drop`, `icond` and `ocond` 
options as follows:

	%let geo=BE;
	%let cond=(geo = "&geo");
	%let cond=(not(geo = "&geo"));
	%let drop=value;
	%ds_update(_dstest32, _dstest33, drop=&drop, icond=&icond, cond=&ocond);

so as to reset `_dstest32` to the table:
 geo | value  
:---:|-------:
AT	 |     0.1
BG   |     0.2
LU   |     0.3
FR   |     0.4
IT   |     0.5
BE	 |      1 

### Notes
1. The macro `%%ds_append` processes several occurrences of the `PROC APPEND`, _e.g._ in short it runs
something like:

	%do i=1 %to %list_length(&idsn);
		%let _idsn=%scan(&idsn, &_i);
		PROC APPEND
			BASE=&lib..&dsn (WHERE=&cond)
			DATA=&ilib..&_idsn (WHERE=&icond)
			FORCE NOWARN;
		run;
	%end;
	PROC SQL;
		ALTER TABLE &lib..&dsn DROP &drop;	
	quit;
2. If you aim at creating a dataset with `n`-replicates of the same table, _e.g._ running something like:

	   %ds_append(dsn, dsn dsn dsn); * !!! AVOID !!!;
so as to append to `dsn` 3 copies of itself, you should instead consider to copy beforehand the table into 
another dataset to be used as input reference. Otherwise, you will create, owing to the `do` loop above, a 
table with (2^n-1) replicates instead, _i.e._ if you will append to `dsn` (2^3-1)=7 copies of itself in the 
case above. 

### References
1. Zdeb, M.: ["Combining SAS datasets"](http://www.albany.edu/~msz03/epi514/notes/p121_142.pdf).
2. Thompson, S. and Sharma, A. (1999): ["How should I combine my data, is the question"](http://www.lexjansen.com/nesug/nesug99/ss/ss134.pdf).
3. Dickstein, C. and Pass, R. (2004): ["DATA Step vs. PROC SQL: What's a neophyte to do?"](http://www2.sas.com/proceedings/sugi29/269-29.pdf).
4. Philp, S. (2006): ["Programming with the KEEP, RENAME, and DROP dataset options"](http://www2.sas.com/proceedings/sugi31/248-31.pdf).
5. Carr, D.W. (2008): ["When PROC APPEND may make more sense than the DATA STEP"](http://www2.sas.com/proceedings/forum2008/085-2008.pdf).
6. Logothetti, T. (2014): ["The power of PROC APPEND"](http://analytics.ncsu.edu/sesug/2014/BB-18.pdf).

### See also
[APPEND](https://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000070934.htm).
*/ /** \cond */

%macro ds_append(dsn		/* Input master dataset to be updated						(REQ) */
				, idsn		/* Input reference dataset(s)          						(REQ) */
			  	, drop=   	/* Names of variables to remove from master dataset 		(OPT) */
				, cond=  	/* Condition to apply to master dataset   					(OPT) */    
			    , icond=	/* Condition to apply to reference dataset(s) 				(OPT) */  
			    , lib=	 	/* Name of the output library	        					(OPT) */
			    , ilib=		/* Name of the input library 	            				(OPT) */
			    );
	%local _mac;
	%let _mac=&sysmacroname;
	/*%macro_put(&_mac);*/

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _idsn   	 /* temporary dataset */
		nidsn		/* number of input reference dataset(s) */
		_var;		/* list of variables */

	/* DSN/LIB: check/set */
	%if %macro_isblank(lib)	%then 	%let lib=WORK;
	%if %error_handle(ErrorInputDataset, 
		%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
		txt=!!! Master dataset %upcase(&dsn) not found !!!) %then
	%goto exit;

	/* IDSN/ILIB: check/set */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	%ds_check(&idsn, _dslst_=_idsn, lib=&ilib);		

	%if %error_handle(ErrorInputParameter,
			%macro_isblank(_idsn), mac=&_mac,
			txt=!!! No reference dataset found !!!) %then	
		%goto exit;

	/* update the list of input reference dataset(s) */
	%let idsn=&_idsn;
	%let nidsn=%list_length(&idsn);

	/* DROP: format/update */
	%if %macro_isblank(drop) %then 	%let drop=_ALL_;
	%if %upcase("&drop")="_NONE_" %then %do;	
		%let drop=;	/* explicitly reset to blank */
	%end;
	%else %do;
		%ds_contents(&dsn, _varlst_=_var, varnum=yes, lib=&lib);
	%end;
	/* %else %do: nothing */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i	/* local increment counter */
		ans
		SEP		/* separator */
		_ivar	/* intermediary list of input variables */
		_ilvar;	/* list of all (unique) variables present in all input datasets */
	%let _ilvar=;
	%let SEP=%quote( );

	/* build a drop variable for each input dataset */
	%if  not %macro_isblank(drop) %then %do;
		%do _i=1 %to &nidsn;
			%local _drop&_i;
			%let _idsn=%scan(&idsn, &_i);
			%let _ivar=; /* reset */
			%ds_contents(&_idsn, _varlst_=_ivar, varnum=yes, lib=&ilib);
			/* %if %list_compare(&var, &ivar) NE 0 %then %do */
			%if %upcase("&drop")="_ALL_" %then %do;
				/* all variables of idsn wich are not in dsn are dropped */
				%let _drop&_i=%list_difference(&_ivar, &_var); 
			%end;
			%else %do;
				/* all variables passed through idrop wich are present in idsn are dropped */
				%let _drop&_i=%list_intersection(&_ivar, &drop);
			%end;
			/* also update the list of variables present in any of the input reference datasets */
			%let _ilvar=%list_unique(&_ilvar.&SEP.&_ivar);
			/* update the list of variables that will be actually appended to the master dataset */
			%let _ivar=%list_difference(&_ivar, &&_drop&_i); 
			/* further check the type compatibility of the files to append */
			%var_compare(&_idsn, &_ivar, _ans_=ans, dsnc=&dsn, typ=yes, len=no, fmt=no, lib=&lib, libc=&ilib);
			%if %error_handle(ErrorInputParameter,
					%list_count(&ans, 1) GT 0, mac=&_mac,
					txt=%quote(!!! Variables %upcase(&_ivar) have different types in datasets &dsn and &_idsn !!!)) %then 
				%goto exit;
		%end;
	%end;

	/* approach based on PROC APPEND */

	%if not (%macro_isblank(drop) and %macro_isblank(cond)) %then %do;
		DATA &lib..&dsn;
			SET &lib..&dsn;
			WHERE &cond;
		run;
	%end;

	/* loop over the updating datasets */
	%do _i=1 %to &nidsn;
		%let _idsn=%scan(&idsn, &_i);
		%let _iprev=%eval(&_i - 1);
		/* note that with PROC APPEND, the order of the variables in the output dataset depends
		* on the order of the first dataset passed to BASE, _i.e._ the master in this case */
		PROC APPEND
			BASE=&lib..&dsn 	
			%if not (%macro_isblank(drop) /*and %macro_isblank(cond)*/) %then %do;
				(
			%end;
			/* if the COND condition is present, and the first time (_i = 1) we run the APPEND
			* operation, filter the master dataset 
			%if &_i EQ 1 and not %macro_isblank(cond) %then %do;
				WHERE=&cond
			%end;
			*/
			/* if the DROP clause is present, we get rid of the variables that were possibly added
			* to the master dataset through previous APPEND operation with dataset in position (_i - 1)
			* in the list of reference datasets */
			%if &_i GT 1 and %macro_isblank(drop) EQ 0 %then %do;
				%if  not %macro_isblank(_drop&_iprev) %then %do;
				DROP=&&_drop&_iprev 
				%end;
			%end;
			%if not (%macro_isblank(drop) /*and %macro_isblank(cond)*/) %then %do;
				)
			%end;
			DATA=&ilib..&_idsn
			/* if the ICOND condition is present, filter the reference dataset */
			%if  not %macro_isblank(icond) %then %do;
				(WHERE=&icond)
			%end;
			FORCE NOWARN
			;
		run;
	%end;

	/* update the list of variables: it is possible that we already cleaned the input dataset,
	* hence no need to do it again... */
	%ds_contents(&dsn, _varlst_=_var, varnum=yes, lib=&lib);
	/* reduce the list of variables to those present in the list above, so as to avoid any message like:
			WARNING: The variable [...] in the DROP, KEEP, or RENAME list has never been referenced 
	* for that purpose, we intersect the variables to drop from the last reference dataset with the variables
	* in the master dataset */
	%let _drop&nidsn=%list_intersection(&_var, &&_drop&nidsn);

	/* actually drop the desired variables from the master dataset */
	%if not %macro_isblank(_drop&nidsn) %then %do;
		/*DATA &lib..&dsn; 
			SET &lib..&dsn(DROP=&&_drop&nidsn);
		run;*/
	   	PROC SQL;
			ALTER TABLE &lib..&dsn DROP &&_drop&nidsn;	
		quit;
	%end;

	/* alternative approach : DATA step  
	DATA  &lib..&dsn;
		SET &lib..&dsn 	
		%if  not %macro_isblank(cond) %then %do;
			(WHERE=&cond)
		%end;
		%do _i=1 %to %list_length(&idsn);
		   	%let _idsn=%scan(&idsn, &_i);
		    &ilib..&_idsn
			%if not (%macro_isblank(icond) and %macro_isblank(idrop)) %then %do;
			(
			%end;
			%if  not %macro_isblank(icond) %then %do;
				WHERE=&icond
			%end;
			%if  not %macro_isblank(idrop) %then %do;
				%if  not %macro_isblank(_idrop&_i) %then %do;
					DROP=&&_idrop&_i
				%end;
			%end;
			%if not (%macro_isblank(icond) and %macro_isblank(idrop)) %then %do;
			)
			%end;
		%end; 
		;
		%let drop=%list_intersection(%list_unique(&_ilvar.&SEP.&_var), &drop); 
		%if  not %macro_isblank(drop) %then %do;
			DROP &drop;
		%end;
	 run;
	* The reasons we did not adopt this approach:
	*	- efficiency reasons: see articles mentioned in list of references
	* 	- issue with the contemporaneous use of DROP and WHERE when the condition in WHERE uses one of
	*	  the variables to DROP.
	*/
 
	%exit:
%mend ds_append;

%macro _example_ds_append;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%work_clean(_dstest25, _dstest26, _dstest31, _dstest32, _dstest33, _dstest37, _dstest38);
	%local TMP dsn idsn;

 	%_dstest25;
   	%put;
	%put (i) Crash test: update a master dataset (test #25) using a DUMMY non-existing dataset;
	%ds_append(_dstest25, DUMMY); 

   	%put;
	%put (ii) Crash test: ibid, update a DUMMY master dataset with an existing one (test #25);
	%ds_append(&idsn, &dsn); 

	%_dstest26;
    %put;
	%put (iii) Update a master dataset (test #26) with two datasets, one of which is DUMMY;
	%ds_append(_dstest26, DUMMY _dstest26); 
	%ds_print(_dstest32, title="Test (iii): _dstest32");

	%_dstest32;
	%ds_print(_dstest32);
	%put; 
	%put (iv) Update a master dataset (test #32) with two datasets;
	%ds_append(_dstest32, _dstest32 _dstest32, drop=geo); 
	%ds_print(_dstest32, title="Test (iv): _dstest32");

	%_dstest31;
	%_dstest33;
	%let drop=unit;
    %put;
	%put (v) Update master dataset #33 with dataset #31 dropping UNIT variable;
	%ds_append(_dstest33, _dstest31, drop=&drop);
 	%ds_print(_dstest33, title="Test (v): _dstest33");

	%work_clean(_dstest32); %_dstest32; /* reset */
	%work_clean(_dstest33); %_dstest33; /* reset */
	%let geo=BE;
	%let icond=(geo = "&geo");
	%let cond=(not(geo = "&geo"));
    %put;
   	%put (vi) Update master dataset #33 with conditions:  icond=&icond and cond=&cond;
	%ds_append(_dstest32, _dstest31, cond=&cond, icond=&icond); 
 	%ds_print(_dstest33, title="Test (vi): _dstest33");

	%_dstest38;
	%_dstest37;
 	%ds_print(_dstest37, title="Test (vii): _dstest37");
	%let drop=time;
	%let icond=(time = 2013);
    %put;
	%put (vii) Update master dataset # with input condition and drop;
	%ds_append(_dstest38, _dstest37, drop=&drop, icond=&icond);   
 	%ds_print(_dstest38, title="Test (vii): _dstest38");

	%put;
	%_dstest26;
	%_dstest27;
	%ds_print(_dstest27, title="Test (viii): _dstest27");
	%ds_print(_dstest26, title="Test (viii): _dstest26");
    %let cond=(not(time = 2013));
	%put (vii) Update master dataset # with condition ;
	%ds_append(_dstest26, _dstest27, cond=&cond);   
 	%ds_print(_dstest26, title="Test (viii): _dstest26");

	%work_clean(_dstest25, _dstest26, _dstest27,_dstest31, _dstest32, _dstest33, _dstest37, _dstest38);
%mend _example_ds_append;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_append; 
*/

/** \endcond */

