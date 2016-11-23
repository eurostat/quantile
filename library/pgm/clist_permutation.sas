/** 
## clist_permutation {#sas_clist_permutation}
Perform a pseudo-random permutation of either the elements of a list or a sequence of integers.

	%clist_permutation(par, _clist_=, seed=, mark=%str(%"), sep=%quote(,));

### Arguments
* `par` : input parameter; this can be:
		+ either a positive INTEGER defining the desired length of the output list,
		+ or a list whose items will be permuted/shuffled;
* `seed` : (_option_) seed of the pseudo-random numbers generator; if seed<=0, the time of day 
	is used to initialize the seed stream; default: `seed=0`; see [%ranuni](@ref sas_ranuni);
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`_clist_` : output sequenced list, _i.e._ the length of the considered list (calculated as the number of 
	strings separated by `sep`).

### Examples
Using a fixed seed, it is possible to retrieve pseudo-random lists (sequence) of INTEGER values, _e.g._:

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
[%ranuni](@ref sas_ranuni), [%list_sequence](@ref sas_list_sequence).
*/ /** \cond */

%macro clist_permutation(par 		/* Positive integer OR list of items comma-separated by a delimiter and between parentheses	(REQ) */
				 		, _clist_= 	/* Name of the macro variable storing the output permutted list 							(REQ) */
				 		, seed=		/* Seed of the pseudo-random numbers generator 												(OPT) */ 
						, mark=		/* Character/string used to quote items in input lists 										(OPT) */
						, sep=		/* Character/string used as list separator 													(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;
 	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_clist_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _CLIST_ not set !!!) %then
		%goto exit;

	/* default settings */
	%if %macro_isblank(mark) %then 							%let mark=%str(%"); /* mark */
	%else %if &mark EQ _EMPTY_ or &mark EQ _empty_ %then 	%let mark=%quote(); 
	%if %macro_isblank(sep) %then 							%let sep=%quote(,);  /* clist separator */
	/* note that all types of checkings are already performed in clist_unquote/list_slice */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local REP; 		/* replacement of list separator */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	%if %clist_length(&par, sep=&sep, mark=&mark)>1 %then 
		/* 1. transform the lists of characters into blank separated lists
		* 	(easier to manipulate) using %clist_unquote */
		%let par=%clist_unquote(&clist, mark=&mark, sep=&sep, rep=&REP);

	/* 2. actually apply the permutation using %list_permutation */
	%list_permutation(&par, _list_=&_clist_, seed=&seed, sep=&REP);
	
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(&_clist_) EQ 1, mac=&_mac,		
			txt=!!! Wrong input list formatting for permutation !!!) %then
		%goto exit;

	/* 3. reform again the initial list of characters (note the inversion of sep/rep) 
	*	using %list_quote */
	%let &_clist_=(%list_quote(&&&_clist_, mark=&mark, sep=&REP, rep=&sep));

	%exit:
%mend clist_permutation;

%macro _example_clist_permutation;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local clist oclist ocres;
	%let oclist=;

	%put;
	%put (i) Crash test with dummy parameters;
	%clist_permutation(-1, _clist_=oclist);
	%if %macro_isblank(oclist) %then 	%put OK: TEST PASSED - Operation crashed;
	%else 								%put ERROR: TEST FAILED - Operation did not crash;
	
	%put;
	%put (ii) Generate a permutation of the set {1-10};
	%let ocres=(%list_quote(%list_sequence(len=10)));
	%clist_permutation(10, _clist_=oclist);
	%if %clist_compare(&ocres, &oclist)=0 %then 	%put OK: TEST PASSED - Recognised list permutation: &oclist;
	%else 											%put ERROR: TEST FAILED - Wrong list permutation: &oclist;

	%let clist=("a","b","c","d","e","f","g","h","i","j");
	%put;
	%put (iii) Perform a permutation of the items of the list=&clist;
	%clist_permutation(&clist, _clist_=oclist);
	%if %clist_compare(&clist, &oclist)=0 %then 	%put OK: TEST PASSED - Recognised list permutation: &oclist;
	%else 										%put ERROR: TEST FAILED - Wrong list permutation: &oclist;

	%put;
%mend _example_clist_permutation; 

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_permutation; 
*/

/** \endcond */
