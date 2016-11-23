/** 
## clist_difference {#sas_clist_difference}
Calculate the (asymmetric) difference between two parentheses-enclosed, comma-separated and/or 
quote-enhanced lists of char.

	%let diff=%clist_difference(clist1, clist2, casense=no, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist1, clist2` : two lists of formatted (_e.g._, parentheses-enclosed, comma-separated 
	quote-enhanced) strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case elements in both lists need to differ;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input lists; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ `clist1` and `clist2` 
	are both comma-separated lists of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) 
	for further details.
 
### Returns
`diff` : output concatenated list of characters, namely the list of (comma-separated) strings in between 
	quotes obtained as the asymmetric difference: `clist1 - clist2`.

### Examples

	%let clist1=("A","B","C","D","E","F");
	%let clist2=("A","B","C");
	%let diff=%clist_difference(&clist1, &clist2);
	
returns: `diff=("D","E","F")`, while:

	%let diff=%clist_difference(&clist2, &clist1);
	
returns: `diff=()`.
 
Run macro `%%_example_clist_difference` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_difference](@ref sas_list_difference), [%clist_compare](@ref sas_clist_compare), [%clist_append](@ref sas_clist_append), 
[%clist_unquote](@ref sas_clist_unquote), [%list_quote](@ref sas_list_quote).
*/ /** \cond */

%macro clist_difference(clist1, clist2	/* Lists of items comma-separated by a delimiter and between parentheses 	(REQ) */
						, casense=no	/* Boolean flag set for case sensitive comparison 							(OPT) */
						, mark=			/* character/string used to quote items in input lists 						(OPT) */
						, sep=			/* character/string used as list separator 									(OPT) */
						);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* default settings */
	%if %macro_isblank(mark) %then 							%let mark=%str(%"); /* mark */
	%else %if &mark EQ _EMPTY_ or &mark EQ _empty_ %then 	%let mark=%quote(); 
	%if %macro_isblank(sep) %then 							%let sep=%quote(,);  /* clist separator */
	/* note that all types of checkings are already performed in clist_unquote/list_slice */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	
	%local REP;				/* intermediary replacement of list separator */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	/* 3. reform again the initial list of characters (note the inversion of sep/rep) 
	*	using %list_quote */
	(%list_quote(
		/* 2. compute the actual difference between those lists through the call to
		*	%list_difference */
		%list_difference(
				/* 1. transform the list of characters into blank separated lists
				* 	(easier to manipulate) using %clist_unquote */
				%clist_unquote(&clist1, mark=&mark, sep=&sep, rep=&REP), 
				%clist_unquote(&clist2, mark=&mark, sep=&sep, rep=&REP), 
				casense=&casense, sep=&REP),
		mark=&mark, sep=&REP, rep=&sep))

%mend clist_difference;


%macro _example_clist_difference;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local clist1 clist2 oclist oclist2;

	%let clist1=("DE","AT","BE","NL","UK","SE");
	%let clist2 =();
	%put;
	%put (i) Test the difference "clist1-clist2" with an empty list clist2 ...;
	%if %bquote(%clist_difference(&clist1, &clist2)) EQ %bquote(&clist1) 	%then 	
		%put OK: TEST PASSED - Difference with empty list returns: clist1;
	%else 																
		%put ERROR: TEST FAILED - Wrong difference "clist1 - clist2" returned;

	%put;
	%put (ii) Test the difference "clist2-clist1" with an empty list clist2 ...;
	%let oclist=();
	%if %bquote(%clist_difference(&clist2, &clist1)) EQ %bquote(&oclist) %then 	
		%put OK: TEST PASSED - Difference from empty list returns: empty list;
	%else 																
		%put ERROR: TEST FAILED - Wrong difference "clist2 - clist1" returned;

	%let clist2 =("AT","BE","NL");
	%put;
	%put (iii) Test the difference "clist1-clist2" with clist1=&clist1 and clist2=&clist2 ...;
	%let oclist2=("DE","UK","SE");
	%if %bquote(%clist_difference(&clist1, &clist2)) EQ %bquote(&oclist2) %then 	
		%put OK: TEST PASSED - "clist1 - clist2" returns: &oclist2;
	%else 																
		%put ERROR: TEST FAILED - Wrong difference "clist1 - clist2" returned;

	%put;
	%put (iv) Test then the asymetric difference "clist2 - clist1"...;
	%let oclist=();
	%if %bquote(%clist_difference(&clist2, &clist1)) EQ %bquote(&oclist) %then 	
		%put OK: TEST PASSED - "clist2 - clist1" returns: &oclist;
	%else 																
		%put ERROR: TEST FAILED - Wrong difference "clist2 - clist1" returned;

	%let clist1 =("AT","BE","NL");
	%let clist2=("NL","BE","AT");
	%put;
	%put (v) Test the difference "clist1-clist2" with clist1=&clist1 and clist2=&clist2 ...;
	%if %bquote(%clist_difference(&clist1, &clist2)) EQ %bquote(&oclist) %then 	
		%put OK: TEST PASSED - "clist1 - clist2" returns: &oclist;
	%else 																
		%put ERROR: TEST FAILED - Wrong difference "clist1 - clist2" returned;

	%put;
%mend _example_clist_difference;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_difference; 
*/

/** \endcond */
