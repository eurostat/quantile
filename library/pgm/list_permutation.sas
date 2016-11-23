/** 
## list_permutation {#sas_list_permutation}
Perform a pseudo-random permutation of either the elements of a list or a sequence of integers.

	%list_permutation(par, _list_=, seed=0, sep=%quote( ));

### Arguments
* `par` : input parameter; this can be:
		+ either a positive INTEGER defining the desired length of the output list,
		+ or a list whose items will be permuted/shuffled;
* `seed` : (_option_) seed of the pseudo-random numbers generator; if seed<=0, the time of day 
	is used to initialize the seed stream; default: `seed=0`; see [%ranuni](@ref sas_ranuni);
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` 
	is blank.
 
### Returns
`_list_` : output sequenced list, _i.e._ the length of the considered list (calculated as the number of 
	strings separated by `sep`).

### Examples
Using a fixed `>0` seed, it is possible to retrieve pseudo-random lists (sequence) of INTEGER values, _e.g._:

	%let olist=;
	%let seed=1;
	%let par=10;
	%list_permutation(&par, _list_=olist, seed=&seed);
	
(always) returns `olist=9 10 1 4 3 8 7 5 6 2`, while using the same seed over some lists of NUMERIC or CHAR 
lists enables us to permute the items of the lists, _e.g._:

	%let par=a b c d e f g h i j;
	%list_permutation(&par, _list_=olist, seed=&seed);
	%let alist=;
	%let par=-2 105 43 56 89 0.5 8.2 10 1 0;
	%list_permutation(&par, _list_=alist, seed=&seed);

return always the same lists `olist=i j a d c h g e f b` and `alist=1 0 -2 56 43 10 8.2 89 0.5 105`.

Run macro `%%_example_list_permutation` for examples.

### Notes
1. In the example above, one can simply check that `%%list_compare(&par, &olist)=0` holds.
2. The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%ranuni](@ref sas_ranuni), [%list_sequence](@ref sas_list_sequence), [%list_sort](@ref sas_list_sort).
*/ /** \cond */

%macro list_permutation(par 		/* Positive integer OR list of blank separated items 			(REQ) */
				 		, _list_= 	/* Name of the macro variable storing the output permutted list (REQ) */
				 		, seed=0	/* Seed of the pseudo-random numbers generator 					(OPT) */ 
						, sep=		/* Character/string used as list separator 						(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;
 	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_list_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _LIST_ not set !!!) %then
		%goto exit;
	/*%let &_list_=;*/

	%if %macro_isblank(sep) %then 	%let sep=%quote( ); /* list separator */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _len	/* length of the input parameter par; will be updated with the length of the output list */
		_dsn 	/* temporary dataset used to store the table of pseudo-random numbers */
		_ilist 	/* list of indexes generated from the pseudo-random numbers */	
		_list; 	/* output list that will be stored in _list_ */
		
	%let _len=%list_length(&par, sep=&sep);

	%if &_len=1 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&par, type=INTEGER, range=0) NE 0, mac=&_mac,		
				txt=!!! Wrong input %upcase(&par) value: must be a INTEGER >0 value !!!) %then
			%goto exit;
		/* update the length */
		%let _len=&par;
		%let par=%list_sequence(len=&_len, sep=&sep);
	%end;
	/* %else: do nothing */

	%if &_len=1 %then %do;
		%let _list=1;
		%goto quit;
	%end;

	%let _dsn=TMP_%upcase(&_mac);

	%ranuni(&_dsn, &_len, seed=&seed);
	/*DATA &_dsn;
		do i = 1 to &_len;
			u=ranuni(&seed);
			output;
		end;
	run;*/

	%let _ilist=;
	
	/* using a PROC SQL-based approach */
	PROC SQL noprint;
	      SELECT i INTO: _ilist SEPARATED BY " " /* indexes need to be blank separated */
	      FROM &_dsn
	      ORDER BY u;
	quit;
	/* using a PROC SORT-based approach 
	PROC SORT data=&_dsn out=&_dsn(drop=u);
		BY u;
	quit;
	%var_to_list(&_dsn, i, _varlst_=_ilist, sep=&sep);
	*/
	%work_clean(&_dsn);
%put in &_mac: par=&par and _ilist=&_ilist;

	%let _list=%list_index(&par, &_ilist, sep=&sep);

	%quit:
	DATA _null_;
		call symput("&_list_","&_list");
	run;

	%exit:
%mend list_permutation;

%macro _example_list_permutation;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local list olist;
	%let olist=;

	%put;
	%put (i) Crash test with dummy parameters;
	%list_permutation(-1, _list_=olist);
	%if %macro_isblank(olist) %then 	%put OK: TEST PASSED - Operation crashed;
	%else 								%put ERROR: TEST FAILED - Operation did not crash;
	
	%put;
	%put (ii) Generate a permutation of the set {1-10};
	%list_permutation(10, _list_=olist);
	%if %list_compare(%list_sequence(len=10), &olist)=0 %then 	%put OK: TEST PASSED - Recognised list permutation: &olist;
	%else 														%put ERROR: TEST FAILED - Wrong list permutation: &olist;

	%let list=a b c d e f g h i j;
	%put;
	%put (iii) Perform a permutation of the items of the list=&list;
	%list_permutation(&list, _list_=olist);
	%if %list_compare(&list, &olist)=0 %then 	%put OK: TEST PASSED - Recognised list permutation: &olist;
	%else 										%put ERROR: TEST FAILED - Wrong list permutation: &olist;

	%put;
%mend _example_list_permutation; 

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_permutation; 
*/

/** \endcond */
