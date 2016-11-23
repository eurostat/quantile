/** 
## clist_compare {#sas_clist_compare}
Compare two lists of comma-separated and quote-enhanced items, _i.e_ check whether the items 
in one list differ from those in another not taking into account any order or repetition(s).
	
	%let ans=%clist_compare(clist1, clist2, casense=no, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist1, clist2` : two lists of items comma-separated by a delimiter (_e.g._, quotes) and in 
	between parentheses;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case elements in both lists are matched;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist1` and
	`clist2` are both comma-separated lists of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) 
	for further details.
 
### Returns
`ans` : the boolean result of the comparison test, i.e.:
		+ `0` when both lists are equal: `list1 = list2`,
		+ `-1` when `clist1` items are all included in `clist2` (but the opposite does not stand):
			say it otherwise: `list1 < list2`,
		+ `1` when `clist2` items are all included in `clist1` (but the opposite does not stand):
			say it otherwise: `list1 > list2`,
		+ empty (_i.e._ `ans=`) when they differ.

### Examples

	%let clist1=("DE","AT","BE","NL","UK","SE");
	%let ans=%clist_compare(&clist1, &clist1);

returns `ans=0`, while:

	%let clist2=("AT","BE","NL");
	%let ans=%clist_compare(&clist1, &clist2);
	
returns `ans=1`.

Run macro `%%_example_clist_compare` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_compare](@ref sas_list_compare), [%clist_unquote](@ref sas_clist_unquote).
*/ /** \cond */

%macro clist_compare(clist1, clist2	/* Lists of items comma-separated by a delimiter and between parentheses 	(REQ) */
					, casense=no	/* Boolean flag set for case sensitive comparison 							(OPT) */
					, mark= 		/* Character/string used to quote items in input lists 						(OPT) */
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

	%local _ans /* result of the test: returned by the macro */
			REP /* arbitrary replacement of list separator */
			;
	%let _ans=; /* set default output to empty */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	%if %macro_isblank(clist1) or %macro_isblank(clist2) %then
		%goto exit; /* _ans is left empty */
	%else %do;
		%let _ans=/* 2. perform append/concatenation operation */
				%list_compare(/* 1. transform the lists of characters into blank separated 
							  *   lists (easier to manipulate) using %clist_unquote */
							  %clist_unquote(&clist1, mark=&mark, sep=&sep, rep=&REP), 
							  %clist_unquote(&clist2, mark=&mark, sep=&sep, rep=&REP), 
				casense=&casense, sep=&REP);
	%end;

	%exit:
	&_ans
%mend clist_compare;

%macro _example_clist_compare;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local clist1 clist2;

	%let clist1=;
	%let clist2=("DE","AT");
	%put;
	%put (i) Compare a emapty list with an non empty one (clist2=&clist2);
	%if %macro_isblank(%clist_compare(&clist1, &clist2)) %then 	
			%put OK: TEST PASSED - clist1 is empty: empty result;
	%else 										
			%put ERROR: TEST FAILED - clist1 is empty: non-empty result;

	%let clist1=("DE","AT","BE","NL","UK","SE");
	%put;
	%put (ii) Compare a list (say clist1=&clist1)...with itself;
	%if %clist_compare(&clist1, &clist1)=0 %then 	%put OK: TEST PASSED - one list only: result 0;
	%else 											%put ERROR: TEST FAILED - one list only: wrong result;

	%let clist2 =("AT","BE","NL");
	%put;
	%put (iii) Compare lists clist1=&clist1 and clist2=&clist2...;
	%if %clist_compare(&clist1, &clist2)=1 %then 	%put OK: TEST PASSED - clist1>clist2: result 1;
	%else 											%put ERROR: TEST FAILED - clist1>clist2: wrong result;

	%put;								
%mend _example_clist_compare;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_compare; 
*/

/** \endcond */
