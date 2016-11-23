/**
## var_to_clist {#sas_var_to_clist}
Return the values of a given variable in a dataset into a formatted (_e.g._, parentheses-enclosed, 
comma-separated and/or quote-enhanced) list of strings.

	%var_to_clist(dsn, var, _varclst_=, distinct=no, mark=%str(%"), sep=%str(,), lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : either a field name, or the position of a field name in, in `dsn`, whose values (observations) 
	will be converted into a list;
* `distinct` : (_option_) boolean flag (`yes/no`) set to return in the list only distinct values
	from `var` variable; in practice, runs a SQL `SELECT DISTINCT` process prior to the values'
	extraction; default: `no`, _i.e._ all values are returned;
* `na_rm` : (_option_) boolean flag (`yes/no`) set to remove missing (NA) values from the observations;
	default: `na_rm=yes`, therefore all missing (`.` or ' ') values will be discarded in the output
	list;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep= %%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
`_varclst_` : name of the macro variable used to store the output formatted list, _i.e._ the list 
	of (comma-separated) main observations in between quotes.

### Examples
Let us consider the test dataset #32 in `WORK.dsn`:
geo | value
----|------
 BE |  0
 AT |  0.1
 BG |  0.2
 LU |  0.3
 FR |  0.4
 IT |  0.5
then running the macro:
	
	%let ctry=;
	%var_to_clist(_dstest32, geo, _varclst_=ctry);
	%var_to_clist(_dstest32,   1, _varclst_=ctry);

will both return: `ctry=("BE","AT","BG","LU","FR","IT")`, while:

	%let val=;
	%var_to_clist(_dstest32, value, _varclst_=val, distinct=yes, lib=WORK);
	
will return: `val=("0","0.1","0.2","0.3","0.4","0.5")`.

Run macro `%%_example_var_to_clist` for more examples.

### See also
[%var_to_list](@ref sas_var_to_list), [%clist_to_var](@ref sas_clist_to_var), [%var_info](@ref sas_var_info), [%list_quote](@ref sas_list_quote).
*/ /** \cond */

%macro var_to_clist(dsn			/* Input dataset 														(REQ) */
				, var 			/* Name of the variable in the input dataset 							(REQ) */ 
			    , _varclst_=	/* Name of the output formatted list of observations in input variable 	(REQ) */
				, distinct=no 	/* Distinc clause 														(OPT) */
				, na_rm=yes		/* Boolean flag set to remove missing (NA) values from the observations (OPT) */
				, mark=			/* Character/string used to quote items in the input list 				(OPT) */
				, sep=			/* Character/string used as list separator 								(OPT) */
				, lib=			/* Input library 														(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_varclst_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _VARCLST_ not set !!!) %then
		%goto exit;

	/*%if %macro_isblank(mark) %then %let mark=%str(%");
	%if %macro_isblank(sep) %then %let sep=%str(,);*/

	%local REP		/* arbitrarily chosen replacement of list separator */
		__varlist 	/* intermediary unformatted list used by var_to_list */
		__varclist;  /* intermediary formatted list used by list_quote */
	%let REP=%str( ); 

	%var_to_list(&dsn, &var, _varlst_=__varlist, distinct=&distinct, na_rm=&na_rm, sep=&REP, lib=&lib);

	/* transform back into a quoted list; note the inversion of parameters sep/REP */
	%let __varclist=(%list_quote(&__varlist, mark=&mark, sep=&REP, rep=&sep));

	/* set the output variable (whose name is &_varclst_) to the value of __varclist */
	%let &_varclst_=&__varclist;
	/*data _null_;
		call symput("&_varclst_",%nrbquote(&__varclist));
	run;*/

	%exit:
%mend var_to_clist;


%macro _example_var_to_clist;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local a;
	%put;
	%put (i) Retrieve the empty variable A from _dstest1...;
	%_dstest1;
	%var_to_clist(_dstest1, A, _varclst_=a);
	%if %macro_isblank(a) %then 	%put OK: TEST PASSED - Empty list retrieved from empty in _dstest1;
	%else 							%put ERROR: TEST FAILED - Wrong list returned from empty in _dstest1;

	%_dstest32; /* create the test dataset #32 in WORK directory */
	%*ds_print(_dstest32);

	%local ctry octry;
	%put;
	%put (ii) Retrieve the list of GEO countries in test dataset #32...;
	%let octry=("BE","AT","BG","LU","FR","IT");
	%var_to_clist(_dstest32, geo, _varclst_=ctry);
	%if &ctry EQ &octry %then 		%put OK: TEST PASSED - List &octry returned from GEO in _dstest32;
	%else 							%put ERROR: TEST FAILED - Wrong list returned from GEO in _dstest32;

	%local val oval;
	%let oval=("0","0.1","0.2","0.3","0.4","0.5");
	%put;
	%put (iii) Retrieve the list of VALUE of test dataset #32...;
	%var_to_clist(_dstest32, value, _varclst_=val, lib=WORK);
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List &oval returned from VALUE in _dstest32;
	%else 							%put ERROR: TEST FAILED - Wrong list returned from VALUE in _dstest32;

	%local val oval;
	%put;
	%put (iv) Retrieve the list of (missing or not) VALUE in test dataset #28 using the option NA_RM;
	%_dstest28;
	%let oval=("1",".","2","3",".","4");
	%var_to_clist(_dstest28, value, _varclst_=val, na_rm=no, lib=WORK);
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List of (missing or not) VALUE returned for _dstest28: &oval;
	%else 							%put ERROR: TEST FAILED - Wrong list of (missing or not) VALUE returned for _dstest28: &val;

	%local val oval;
	%put;
	%put (v) Same operation passing this time var as a varnum position, instead of a field: varnum=2;
	%var_to_clist(_dstest28, 2, _varclst_=val, na_rm=no, lib=WORK);
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List of (missing or not) VALUE returned for _dstest28: &oval;
	%else 							%put ERROR: TEST FAILED - Wrong list of (missing or not) VALUE returned for _dstest28: &val;

	%put;

	/* clean your shit... */
	%work_clean(_dstest1,_dstest28,_dstest32); 
%mend _example_var_to_clist;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_to_clist; 
*/

/** \endcond */
