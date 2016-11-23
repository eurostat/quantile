/** 
## ds_delete {#sas_ds_delete}
Conditionally delete observations and drop variable(s) from a given dataset.

	%ds_delete(dsn, var=, cond=, firstobs=0, obs=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : (_option_) List of variable(s) to delete (`drop`) from the dataset; if more variables
	are to be deleted, `var` should be defined as an unformatted list; default: not used;
* `cond` : (_option_) an expression that resolves to a boolean (0/1) so that all observations
	for which `cond` is true (1) will be deleted; default: `0`, _i.e._ no observations is deleted;
* `firstobs, obs` : (_option_) indexes of the first and the last observations to consider for the
	delete operation _resp._;  all obsevation whose index is `<firstobs` or `>obs` will be automatically
	deleted; see `DATA` step options; by default, options are not used;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Examples
Let us consider the following `_dstest31` table: 
geo | value | unit
----|------:|-----
 BE |  0    | EUR
 AT |  0.1  | EUR
 BG |  0.2  | NAC
 LU |  0.3  | EUR
 FR |  0.4  | NAC
 IT |  0.5  | EUR

we will delete all VALUEs and keep only observations for which UNIT is EUR: 

	%ds_delete(_dstest31, var=value, cond=%quote(unit="EUR"));

so that we have:
geo | unit
----|-----
 BG | NAC
 FR | NAC

Note that the command can be used to delete more than one variable at a time, _e.g._:

	%ds_delete(_dstest31, var=value unit, cond=%quote(unit="EUR"));

will return instead:
|geo | 
|----|
| BG |
| FR |

Run macro `%%_example_ds_delete` for more examples.

### Notes
1. In short, the macro sequentially runs two operations that summarizes to the following `DATA` step:

       DATA &lib..&dsn (DROP=&var);
		   SET &lib..&dsn(FIRSTOBS=&firstobs OBS=&obs);
   		   IF &cond THEN DELETE;
	   run;
2. It shall be noticed that in practice: first the options `firstobs` and `obs` are applied, then the 
condition `cond` is evaluated (though it occurs inside a unique `DATA` step), and then the variable `var` 
is dropped from the dataset. This matters in the cases where `cond` is an expression based on `var` values.

### Reference
1. ["Selecting and restricting observations"](http://www.albany.edu/~msz03/epi514/notes/fp051_065.pdf).
2. Gupta, S. (2006): ["WHERE vs. IF statements: Knowing the difference in how and when to apply"](http://www2.sas.com/proceedings/sugi31/238-31.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%ds_isempty](@ref sas_ds_isempty), [%ds_iscond](@ref sas_ds_iscond), [%var_check](@ref sas_var_check),
[DELETE](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000247666.htm),
[DROP](http://support.sas.com/documentation/cdl/en/lestmtsref/63323/HTML/default/viewer.htm#n1capr0s7tilbvn1lypdshkgpaip.htm).
*/ /** \cond */

%macro ds_delete(dsn		/* Input reference dataset 								(REQ) */
				, var=  	/* List of variable(s) to drop from the dataset 		(OPT) */
				, cond=		/* Boolean expression used to delete some observations 	(OPT) */
				, firstobs=	/* Index of the first observation to consider 			(OPT) */
				, obs=		/* Index of the last observation to consider 			(OPT) */
				, lib=		/* Name of the input library 							(REQ) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 1 and /*%macro_isblank(cond) EQ 1*/ &cond=, mac=&_mac,		
			txt=!!! Missing parameters VAR or COND !!!) %then
		%goto exit;

	%local _i 		/* loop increment */
		_numvar 	/* Number of variables to drop */
		newvar 		/* Updated list of variables */
		SEP			/* arbirtrary list separator */
		_isblfirst	/* test of existence of firstobs option */
		_isblobs;	/* test of existence of obs option */
	%let SEP=%str( );

	%let _isblfirst=%macro_isblank(firstobs);
	%let _isblobs=%macro_isblank(obs);
	%if %macro_isblank(lib) %then 	%let lib=WORK;

	/* first, apply the deleting condition */
	%if /*not %macro_isblank(cond)*/ &cond^= %then %do;
		DATA &lib..&dsn;
			SET &lib..&dsn
			%if &_isblfirst=0 or &_isblobs=0 %then %do;
				(
			%end;
			%if &_isblfirst=0 %then %do;
				FIRSTOBS=&firstobs
			%end;
			%if &_isblobs=0 %then %do;
				OBS=&obs
			%end;
			%if &_isblfirst=0 or &_isblobs=0 %then %do;
				)
			%end;
			;
   			IF &cond /* %unquote(&cond) */ THEN DELETE;
		run;
	%end;

	/* check if any variable was passed */
	%if %macro_isblank(var) %then 
		%goto exit;

	/* test the list of variables passed; possibly trim the list to keep only those
	* that are actually defined in the input dataset */
	%let newvar=;
	%var_check(&dsn, &var, _varlst_=newvar, lib=&lib);

	/* we should now have only existing variables in newvar...unless it is empty */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(newvar) EQ 1, mac=&_mac,		
			txt=!!! None of the variables defined in %upcase(&var) was found in dataset %upcase(&dsn) !!!) %then
		%goto exit;

	/* finally, drop/delete the existing variables */
	DATA &lib..&dsn (DROP=&newvar);
		SET &lib..&dsn;
	run;

	%exit:
%mend ds_delete;

%macro _example_ds_delete;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%put;
	%put (i) Drop the variable GEO from dataset _dstest30;
	%_dstest30;
	%*ds_print(_dstest30);
	%ds_delete(_dstest30, var=geo);
	%ds_print(_dstest30);

	%put;
	%put (ii) Combining the delete/drop operations on dataset _dstest31;
	%_dstest31;
	%*ds_print(_dstest31);
	%let cond=%quote(unit="EUR");
	%ds_delete(_dstest31, var=value, cond=&cond);
	%ds_print(_dstest31);

	%put;
	%put (iii) Same operation, further forcing the operation to start at the 2nd observation;
	%_dstest31(force=yes);
	%*ds_print(_dstest31);
	%let cond=%quote(unit="EUR");
	%ds_delete(_dstest31, var=value, cond=&cond, firstobs=2);
	%ds_print(_dstest31);

	%put;
	%put (iv) Deleting both UNIT and VALUE fields, as well as non-existing A field, from dataset _dstest31;
	%_dstest31(force=yes);
	%*ds_print(_dstest31);
	%ds_delete(_dstest31, var=value A unit); /* will generate an error message but proceeds anyway */
	%ds_print(_dstest31);

	%put;
	%put (v) Delete all missing VALUE observations from dataset _dstest33;
	%_dstest33;
	%*ds_print(_dstest33);
	%let cond=%quote(MISSING(value));
	%ds_delete(_dstest33, cond=&cond);
	%ds_print(_dstest33);

	%put;

	%work_clean(_dstest30,_dstest31,_dstest33);
%mend _example_ds_delete;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
*/
%_example_ds_delete; 

/** \endcond */

