/**
## clist_unique {#sas_clist_unique}
Trim a given formatted list from its duplicated elements and return the list of unique items.

	%let cluni=%clist_unique(clist, casense=no, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist` : a list of formatted (_e.g._, comma-separated quote-enhanced) strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive representation; default:
	`casense=no`, _i.e._ lower- and upper-case versions of the same strings are considered as equal;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`cluni` : output formatted list of unique elements present in the input list `clist`; when the case 
	unsentiveness is set (through `casense=no`), `cluni` is returned as a list of upper case elements.

### Examples

	%let clist=("A","B","b","b","c","C","D","E","e","F","F","A","B","E","D");
	%let cluni=%clist_unique(&clist, casense=yes);
	
returns: `cluni=("A","B","b","c","C","D","E","e","F")`, while:

	%let cluni=%clist_unique(&clist);
	
returns: `cluni=("A","B","C","D","E","F")`.

Run macro `%%_example_clist_unique` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_unique](@ref sas_list_unique), [%list_slice](@ref sas_list_slice), [%clist_compare](@ref sas_clist_compare), 
[%clist_append](@ref sas_clist_append), [%clist_unquote](@ref sas_clist_unquote).
*/ /** \cond */

%macro clist_unique(clist 			/* List of items comma-separated by a delimiter and between parentheses (REQ) */
					, casense=no	/* Boolean flag set for case sensitive comparison 						(OPT) */
					, mark=			/* Character/string used to quote items in input lists 					(OPT) */
					, sep=			/* Character/string used as list separator 								(OPT) */
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

	%local REP; 	/* replacement of list separator */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	/* 3. reform again the initial list of characters (note the inversion of sep/rep) 
	* 	using %list_quote */
	(%list_quote(
		/* 2. return the actual unique representation */
		%list_unique(
				/* 1. transform the list of characters into a blank separated list
				* 	(easier to manipulate) using %clist_unquote */
				%clist_unquote(&clist, mark=&mark, sep=&sep, rep=&REP), 
				casense=&casense, sep=&REP),
		mark=&mark, sep=&REP, rep=&sep))

%mend clist_unique;

%macro _example_clist_unique;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local clist oclist;

	%let clist=("A","B","b","b","c","C","D","E","e","F","F","A","B","E","D");
	%put;
	%put (i) Return the list of unique elements in clist=&clist ...;
	%let oclist=("A","B","b","c","C","D","E","e","F");
	%if %quote(%clist_unique(&clist, casense=yes)) EQ %quote(&oclist) %then 
		%put OK: TEST PASSED - Unique representation of list: &oclist;
	%else											
		%put ERROR: TEST FAILED - Wrong list of unique elements returned;

	%put;
	%put (ii) Ibid, considering the case sensitiveness (casense=no) ...;
	%let oclist=("A","B","C","D","E","F");
	%if %quote(%clist_unique(&clist)) EQ %quote(&oclist) %then 
		%put OK: TEST PASSED - Unique case sensitive representation of list: &oclist;
	%else														
		%put ERROR: TEST FAILED - Wrong list of unique elements returned;

	%put;
%mend _example_clist_unique;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_unique; 
*/

/** \endcond */
