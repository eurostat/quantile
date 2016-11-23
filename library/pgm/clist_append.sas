/** 
## clist_append {#sas_clist_append}
Append (_i.e._, concatenate) a comma-separated quote-enhanced (char or numeric) list to another, 
possibly interleaving the items in the lists.

	%let conc=%clist_append(clist1, clist2, zip=no, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist1, clist2` : two lists of formatted (_e.g._, comma-separated quote-enhanced) strings;
* `zip` : (_option_) a boolean flag (`yes/no`) set to interleave the lists; when `zip=yes`, 
	the i-th element from each of the lists are appended together and put into the 2*i-1 element 
	of the output list; the returned list is truncated in length to the length of the shortest list; 
	default: `zip=no`, _i.e._ lists are simply appended;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist1` and
	`clist2` are both comma-separated lists of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) 
	for further details.
 
### Returns
`conc` : output concatenated list of characters, _e.g._ the list of comma-separated (if `sep=%%quote(,)`) 
	items in between quotes (if `mark=%%str(%")`) obtained as the union/concatenation of the input lists
	`clist1` and `clist2`.

### Examples

	%let clist1=("A","B","C","D","E");
	%let clist2=("F","G","H","I","J"); 
	%let conc=%clist_append(&clist1, &clist2) 
	
returns: `conc=("A","B","C","D","E","F","G","H","I","J")`. 

	%let clist0=("1","2","3");
	%let conc=%clist_append(&clist0, &clist1, zip=yes) 
	
returns: `conc=("1","A","2","B","3","C")`. 

Run macro `%%_example_clist_append` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%clist_append](@ref sas_clist_append), [%clist_difference](@ref sas_clist_difference), [%clist_unquote](@ref sas_clist_unquote), [%list_quote](@ref sas_list_quote).
*/ /** \cond */

%macro clist_append(clist1, clist2	/* Lists of items comma-separated by a delimiter and between parentheses 	(REQ) */
					, zip=no		/* Boolean flag used to interleave the lists 								(OPT) */
					, mark=			/* Character/string used to quote items in input lists 						(OPT) */
					, sep=			/* Character/string used as list separator 									(OPT) */
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
	
	%local REP;	/* intermediary replacement of list separator */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	/* 3. reform again the initial list of characters (note the inversion of sep/rep) 
	*	using %list_quote */
	(%list_quote(
		/* 2. compute the actual difference between those lists through the call to
		*	%list_difference */
		%list_append(
				/* 1. transform the lists of characters into blank separated lists
				* 	(easier to manipulate) using %clist_unquote */
				%clist_unquote(&clist1, mark=&mark, sep=&sep, rep=&REP),
				%clist_unquote(&clist2, mark=&mark, sep=&sep, rep=&REP), 
				zip=&zip, sep=&REP),
		mark=&mark, sep=&REP, rep=&sep)) /*Lisp-like implementation :) */
	
%mend clist_append;

%macro _example_clist_append;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local clist1 clist2;
	%let clist1=("A","B","C","D","E","F");	
	%let clist2=("G","H","I","J","K","L","M","N","O");	

	%local oclist1 oclist2;
	%put;
	%put (i) Append lists list1=&clist1 and list2=&clist2 ...; 
	%let oclist1=("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O");
	%if %bquote(%clist_append(&clist1, &clist2)) EQ %bquote(&oclist1) %then 	
		%put OK: TEST PASSED - Appended "clist1 + clist2" returns: &oclist1;
	%else 															
		%put ERROR: TEST FAILED - Wrong concatenated list "clist1 + clist2" returned;

	%put;
	%put (ii) Append lists list1=&clist1 and list2=&clist2 ...; 
	%let oclist2=("G","H","I","J","K","L","M","N","O","A","B","C","D","E","F");
	%if %bquote(%clist_append(&clist2, &clist1)) EQ %bquote(&oclist2) %then 	
		%put OK: TEST PASSED - Appended "clist2 + clist1" returns: &oclist2;
	%else 															
		%put ERROR: TEST FAILED - Wrong concatenated list "clist2 + clist1" returned;

	%let clist1=("1","2","3","4");	
	%put;
	%put (iii) Zip (append and interleave) lists list1=&clist1 and list2=&clist2 ...; 
	%let oclist2=("1","G","2","H","3","I","4","J");
	%if %bquote(%clist_append(&clist1, &clist2, zip=yes)) EQ %bquote(&oclist2) 	%then 	
		%put OK: TEST PASSED - Zipped "clist1 + clist2" returns: &oclist2;
	%else 															
		%put ERROR: TEST FAILED - Wrong concatenated list "clist1 + clist2" returned;

	%put;

%mend _example_clist_append;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_append; 
*/

/** \endcond */
