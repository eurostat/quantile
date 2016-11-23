/** 
## ds_contents {#sas_ds_contents}
Retrieve the list (possibly ordered by varnum) of variables/fields in a given dataset.

	%ds_contents(dsn, _varlst_=, _lenlst_=, _typlst_=, varnum=yes, lib=);

### Arguments
* `dsn` : a dataset reference;
* `varnum` : (_option_) boolean flag (`yes/no`) set to order the output list of variables
	by varnum, _i.e._ their actual position in the table; default: `varnum=yes` and the 
	variables returned in `_varlst_` (see below) are ordered;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
* `_varlst_` : name of the output macro variable where the list of variables/fields of the
	dataset `dsn` are stored;
* `_typlst_` : (_option_) name of the output macro variable storing the corresponding list of 
	variables/fields types; the output list shall be of the same length as `&_varlst_`; default: 
	it will not be returned;
* `_lenlst_` : (_option_) ibid with the variable lengths; default: it will not be returned.

### Examples
Consider the test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

One can retrieve the ordered list of variables in the dataset with the command:

	%let list=;
	%ds_contents(_dstest5, _varlst_=list);

which returns `list=f e d c b a`, while:

	%ds_contents(_dstest5, _varlst_=list, varnum=no);

returns `list=a b c d e f`. Similarly, we can also run it on our database, _e.g._:

	libname rdb "&G_PING_C_RDB"; 
	%let lens=;
	%let typs=;
	%ds_contents(PEPS01, _varlst_=list, _typlst_=typs, _lenlst_=lens, lib=rdb);

returns:
	* `list=geo time age sex unit ivalue iflag unrel n ntot totwgh lastup lastuser`,
	* `typs=  2    1   2   2    2      1     2     1 1    1      1      2        2`,
	* `lens=  5    8  13   3   13      8     1     8 8    8      8      7        7`.

Another useful use: we can retrieve data of interest from existing tables, _e.g._ the list of geographical 
zones in the EU:

	%let zones=;
	%ds_contents(&G_PING_COUNTRYxZONE, _varlst_=zones, lib=&G_PING_LIBCFG);
	%let zones=%list_slice(&zones, ibeg=2);

which will return: `zones=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU15 EU25 EU27 EU28 EFTA EU07 EU09 EU10 EU12`.

Run macro `%%_example_ds_contents` for more examples.

### Note
In short, the program runs (when `varnum=yes`):

	PROC CONTENTS DATA = &dsn 
		OUT = tmp(keep = name type length varnum);
	run;
	PROC SORT DATA = tmp 
		OUT = &tmp(keep = name type length);
     	BY varnum;
	run;
and retrieves the resulting `name`, `type` and `length` variables.

### References
1. Smith,, C.A. (2005): ["Documenting your data using the CONTENTS procedure"](http://www.lexjansen.com/wuss/2005/sas_solutions/sol_documenting_your_data.pdf).
2. Thompson, S.R. (2006): ["Putting SAS dataset variable names into a macro variable"](http://analytics.ncsu.edu/sesug/2006/CC01_06.PDF).
3. Mullins, L. (2014): ["Give me EVERYTHING! A macro to combine the CONTENTS procedure output and formats"](http://www.pharmasug.org/proceedings/2014/CC/PharmaSUG-2014-CC43.pdf).

### See also
[%var_to_list](@ref sas_var_to_list), [%ds_check](@ref sas_ds_check),
[CONTENTS](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000085766.htm).
*/ /** \cond */ 

%macro ds_contents(dsn			/* Input reference dataset 															(REQ) */
				, _varlst_=		/* Name of the output macro variable storing the list of variables' names 			(REQ) */
				, _lenlst_=		/* Name of the macro variable storing the corresponding list of variables lengths 	(OPT) */
				, _typlst_=		/* Name of the macro variable storing the corresponding list of variables types 	(OPT) */
				, varnum=yes	/* Boolean flag used to order the output list of variables 							(OPT) */
				, lib=			/* Name of the input library 														(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* various checkings */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_varlst_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _VARLST_ needs to be set !!!) %then
		%goto exit;

	%local __istyplst	/* output of the test of _TYPLST_ parameter setting */
		__islenlst		/* output of the test of _LENLST_ parameter setting */
		__isvarnum		/* output of the test of VARNUM parameter setting */
		__tmp			/* temporary dataset */
		__vars 			/* output list of variable names */
		__lens			/* (optional) output list of variable lengths */
		__typs			/* (optional) output list of variable types */
		SEP;			/* arbitrary chosen separator for the output lists */
	%let __tmp=TMP_&_mac;
	%let SEP=%str( );

	%let __istyplst=%macro_isblank(_typlst_);
	%let __islenlst=%macro_isblank(_lenlst_);
	%if %macro_isblank(lib) %then 		%let lib=WORK;
	%if %macro_isblank(varnum) %then 	%let __isvarnum=YES;
	%else								%let __isvarnum=%upcase(&varnum);

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=%bquote(!!! Input dataset %upcase(&dsn) not found in library %upcase(&lib) !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* run the PROC CONTENTS */
	PROC CONTENTS noprint
		DATA = &lib..&dsn 
        OUT = &__tmp(keep = name 
		%if &__isvarnum=YES %then %do; 
			varnum 
		%end;
		%if &__istyplst EQ 0 %then %do; 
			type 
		%end;
		%if &__islenlst EQ 0 %then %do; 
			length 
		%end;
		);
	run;

	/* sort "data_info" by "varnum";
	* export the sorted data set with the name "variable_names", and keep just the "name" column; */
	%if &__isvarnum=YES %then %do; 
		PROC SORT
	     	DATA = &__tmp
			OUT = &__tmp(keep = name
			%if &__istyplst EQ 0 %then %do; 
				type 
			%end;
			%if &__islenlst EQ 0 %then %do; 
				length 
			%end;
			) OVERWRITE;
	     	BY varnum;
		run;
	%end;

	/* finally return desired output(s) */
	PROC SQL noprint; 	
		SELECT
			name 
			%if &__istyplst EQ 0 %then %do; 
				, type
			%end;
			%if &__islenlst EQ 0 %then %do; 
				, length
			%end;
		INTO 
			/* list of variable names */
			:&_varlst_ SEPARATED BY "&SEP"
			/* list of variable types */
			%if &__istyplst EQ 0 %then %do; 
				, :&_typlst_ SEPARATED BY "&SEP"
			%end;
			/* list of variable lengths */
			%if &__islenlst EQ 0 %then %do; 
				, :&_lenlst_ SEPARATED BY "&SEP"
			%end;		
		FROM &__tmp;
	quit;

	/*	!!! We shall avoid getting into a kind of "large black hole", as Hubert Reeves uses to say,
	 * since the function %var_to_list may itself calls %ds_contents... Hi Hi Hi Hi          !!!
	data _null_;
		%var_to_list(&__tmp, name, _varlst_=__vars);
		call symput("&_varlst_","&__vars");
		%if &__istyplst EQ 0 %then %do; 
			%var_to_list(&__tmp, type, _varlst_=__typs);
			call symput("&_typlst_","&__typs");
		%end;
		%if &__islenlst EQ 0 %then %do; 
			%var_to_list(&__tmp, length, _varlst_=__lens);
			call symput("&_lenlst_","&__lens");
		%end;
	run;
	*/

	%work_clean(&__tmp);
	%exit:
%mend ds_contents;


%macro _example_ds_contents;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/* inputs: set some local parameters of your own */
	%local list olist lens olens typs otyps;

	%_dstest1;
	%put;
	%put (i) Retrieve the variable from test dataset #1 (with missing observation);
	%let olist=a;
	%ds_contents(_dstest1, _varlst_=list);
	%if &list EQ &olist %then 	%put OK: TEST PASSED - _dstest1 returns: %upcase(&olist);
	%else 						%put ERROR: TEST FAILED - Wrong result returned;

	%_dstest5;
	%put;
	%put (ii) Retrieve the ordered (by VARNUM) list of variables/fields from test dataset #5;
	%let olist=f e d c b a;
	%let olens=8 8 8 8 8 8;
	%let otyps=1 1 1 1 1 1;
	%ds_contents(_dstest5, _varlst_=list, _lenlst_=lens, _typlst_=typs);
	%if &list EQ &olist and &lens EQ &olens and &typs EQ &otyps %then 	
		%put OK: TEST PASSED - _dstest5 returns: %upcase(&olist) with lengths: (&olens) and types=(&otyps);
	%else 						
		%put ERROR: TEST FAILED - Wrong results returned;

	%put;
	%put (iii) Retrieve the (alphanumerically ordered) list of variables/fields from test dataset #5;
	%let olist=a b c d e f;
	%ds_contents(_dstest5, _varlst_=list, varnum=no);
	%if &list EQ &olist %then 	%put OK: TEST PASSED - _dstest5 returns: %upcase(&olist);
	%else 						%put ERROR: TEST FAILED - Wrong result returned;

	%_dstest35;
	%put;
	%put (iv) Retrieve the ordered list of variables/fields from test dataset #35;
	%let olist=geo time EQ_INC20 RB050a;
	%ds_contents(_dstest35, _varlst_=list);
	%if &list EQ &olist %then 	%put OK: TEST PASSED - _dstest35 returns: %upcase(&olist);
	%else 						%put ERROR: TEST FAILED - Wrong result returned;


	%if %symexist(EUSILC) %then %do;
		libname rdb "&G_PING_C_RDB"; 
		%put;
		%put (v) What about one of our database, for instance DI01 in rdb...?;
		%let olist=geo time indic_il currency quantile ivalue iflag unrel n ntot totwgh lastup lastuser;
		%ds_contents(DI01, _varlst_=list, _lenlst_=lens, _typlst_=typs, lib=rdb);
		%if &list EQ &olist %then 	%put OK: TEST PASSED - DI01 returns: %upcase(&olist);
		%else 						%put ERROR: TEST FAILED - Wrong result returned;
	%end;

	%put;

	%work_clean(_dstest1,_dstest5,_dstest35);
%mend _example_ds_contents;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_contents;  
*/

/** \endcond */
