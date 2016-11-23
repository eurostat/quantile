/** 
## list_compare {#sas_list_compare}
Compare two lists of characters/strings, _i.e_ check whether the items in one list differ
from those in another not taking into account any order or repetition(s).

	%list_compare(list1, list2, casense=no, sep=%quote( ));

### Arguments
* `list1, list2` : two lists of items;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case elements in both lists are matched;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ 
	items are separated by a blank.

### Returns
`ans` : the boolean result of the comparison test of the "sets" associated to the input lists, 
	i.e.:
		+ `0` when both lists are equal: `list1 = list2`,
		+ `-1` when `list1` items are all included in `list2` (but the opposite does not stand):
			say it otherwise: `list1 < list2`,
		+ `1` when `list2` items are all included in `list1` (but the opposite does not stand):
			say it otherwise: `list1 > list2`,
		+ ` ` (_i.e._ `ans=`) when they differ.

### Examples
Simple examples (with `casense=yes` by default):

	%let list1=NL UK DE AT BE;
	%let list2=DE AT BE NL UK SE;
	%let ans=%list_compare(&list1, &list2);
	
returns `ans=-1`, while:

	%let ans=%list_compare(&list2, &list1);

returns `ans=1`, and:

	%let list1=NL UK DE AT BE;
	%let list2=DE NL AT UK BE;
	%let ans=%list_compare(&list1, &list2);

returns `ans=0`. We also further use the case sensitiviness (`yes/no`) for comparison:

	%let list1=NL uk de AT BE;
	%let list2=DE NL at UK be;
	%let ans1=%list_compare(&list1, &list2, casense=yes);
	%let ans2=%list_compare(&list1, &list2);

return `ans1=` (_i.e._ list differ) and `ans2=0` (_i.e._ lists are equal with default `casense=no`).

Run macro `%%_example_list_compare` for examples.

### Notes
* If one of the lists is empty, then the result is empty (set to `ans=`).
* If elements are duplicated in a list, `%%list_compare` may still return `0`, for instance:

        %let list1=NL DE AT BE;
	    %let list2=DE AT NL BE NL BE;
	    %let ans=%list_compare(&list1, &list2);
returns `ans=0`...	

### See also
[%clist_compare](@ref sas_clist_compare), [%list_remove](@ref sas_list_remove), [%list_count](@ref sas_list_count), 
[%list_slice](@ref sas_list_slice),
[TRANWRD](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000215027.htm),
[FINDW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002978282.htm).
*/ /** \cond */

%macro list_compare(list1, list2	/* Lists of blank-separated items 							(REQ) */
				  	, casense=no	/* Boolean flag set for case sensitive comparison 			(OPT) */
					, sep=			/* Character/string used as string separator in input list	(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	%local _ans	/* output answer */
		alist1 	/* intermediary list 1 */
		alist2 	/* intermediary list 2 */
		NEWSEP	/* temporary separator */
		TMP; 	/* temporary variable */

	/* set default output to empty */
	%let _ans=; 
	%let NEWSEP=%quote( );

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&casense), type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

	%if %macro_isblank(sep) %then %let sep=%quote( ); 

	%let alist1=%sysfunc(tranwrd(&list1, &sep, &NEWSEP));
	%let alist2=%sysfunc(tranwrd(&list2, &sep, &NEWSEP));
	%if %upcase("&casense")="NO" %then %do;
		%let alist1=%upcase(&alist1);
		%let alist2=%upcase(&alist2);
	%end;

	%if %macro_isblank(alist1) or %macro_isblank(alist2) %then 
		%goto exit; /* ans is empty */

	%let TMP=;
	%do %while (%macro_isblank(alist1) EQ 0 or %macro_isblank(alist2) EQ 0);
		%let item=%scan(&alist1, 1, &NEWSEP);
		%if %macro_isblank(item) or %macro_isblank(alist2) %then 
			%goto break;
		%let exist_in_alist2=%sysfunc(findw(&alist2, &item));
		%if &exist_in_alist2<=0 %then %do; /* item1 has not been found */
			%if not %macro_isblank(TMP) %then 
				%goto break;
			%let TMP=&alist1;
			%let alist1=&alist2;
			%let alist2=&TMP;
		%end;
		%else %do;
			/* trim the value from the list */
			%let alist1=%sysfunc(tranwrd(%quote(&alist1), &item, &NEWSEP));
			%let alist1=%sysfunc(compbl(%quote(&alist1)));
			%let alist2=%sysfunc(tranwrd(%quote(&alist2), &item, &NEWSEP));
			%let alist2=%sysfunc(compbl(%quote(&alist2))); /* works with blanks */
		%end;
	%end;

	%break:
	%if %macro_isblank(alist1)  %then %do;	
		%if %macro_isblank(alist2) %then 		%let _ans=0;
		%else %if %macro_isblank(TMP) %then		%let _ans=-1;
		%else 									%let _ans=1;
	%end;
	%else %if %macro_isblank(alist2) %then %do;
		%if %macro_isblank(TMP) %then			%let _ans=1;
		%else 									%let _ans=-1;
	%end;
	%else /* do nothing */						%let _ans=;

	%exit:
	&_ans

%mend list_compare;

%macro _example_list_compare;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local list_1 list_2;

	%let list_1=;
	%let list_2=AT;
	%put;
	%put (i) Compare the empty list list1=&list_1 with list2=&list_2....;
	%if %macro_isblank(%list_compare(&list_1, &list_2)) %then 		
		%put OK: TEST PASSED - list1 is empty: empty result;
	%else 											
		%put ERROR: TEST FAILED - list1 is empty: non-empty result;

	%let list_1=BE;
	%let list_2=BE DE;
	%put;
	%put (ii) Compare lists list1=&list_1 and list2=&list_2....;
	%if %list_compare(&list_1, &list_2)=-1 %then 	%put OK: TEST PASSED - list1<list2: result -1;
	%else 											%put ERROR: TEST FAILED - list1<list2: wrong result;

	%let list_1=BE DE;
	%let list_2=AT BE;
	%put;
	%put (iii) Compare lists list1=&list_1 and list2=&list_2....;
	%if %macro_isblank(%list_compare(&list_1, &list_2)) %then 		
		%put OK: TEST PASSED - list1!=list2: empty result;
	%else 											
		%put ERROR: TEST FAILED - list1!=list2: non-empty result;

	%let list_1=NL UK DE AT BE;
	%let list_2=DE AT BE NL UK SE;
	%put;
	%put (iv) Compare lists list1=&list_1 and list2=&list_2....;
	%if %list_compare(&list_1, &list_2)=-1 %then 	%put OK: TEST PASSED - list1<list2: result -1;
	%else 											%put ERROR: TEST FAILED - list1<list2: wrong result;

	%let list_1=NL UK DE AT BE;
	%let list_2=FR EL NL UK SE;
	%put;
	%put (v) Compare lists list1=&list_1 and list2=&list_2....;
	%if %macro_isblank(%list_compare(&list_1, &list_2)) %then 		
		%put OK: TEST PASSED - list1!=list2: empty result;
	%else 											
		%put ERROR: TEST FAILED - list1!=list2: non-empty result;

	%let list_1=NL UK DE AT BE;
	%let list_2=DE NL AT UK BE;
	%put;
	%put (vi) Compare lists list1=&list_1 and list2=&list_2....;
	%if %list_compare(&list_1, &list_2)=0 %then 	%put OK: TEST PASSED - list1=list2: result 0;
	%else 											%put ERROR: TEST FAILED - list1=list2: wrong result;

	%let list_1=NL uk de AT BE;
	%let list_2=DE NL at UK be;
	%put;
	%put (vii) Case sensitive comparison of lists list1=&list_1 and list2=&list_2....;
	%if %macro_isblank(%list_compare(&list_1, &list_2, casense=yes)) %then 	
		%put OK: TEST PASSED - list1 and list2 differ;
	%else 														
		%put ERROR: TEST FAILED - Wrong result;

	%put;
	%put (viii) Ibid, but case insensitive (casense=no)....;
	%if %list_compare(&list_1, &list_2)=0 %then 	%put OK: TEST PASSED - list1=list2: result 0;
	%else 											%put ERROR: TEST FAILED - list1=list2: wrong result;

	%let list_1=NL UK DE AT BE SE;
	%let list_2=DE AT NL BE;
	%put;
	%put (ix) Compare lists list1=&list_1 and list2=&list_2....;
	%if %list_compare(&list_1, &list_2)=1 %then 	%put OK: TEST PASSED - list1>list2: result 1;
	%else  											%put ERROR: TEST FAILED - list1>list2: wrong result;		

	%let list_1=NL DE AT BE;
	%let list_2=DE AT NL BE NL BE;
	%put;
	%put (x) Compare lists list1=&list_1 and list2=&list_2....;
	%if %list_compare(&list_1, &list_2)=0 %then 	%put OK: TEST PASSED - Different lists, but same (repeated) items: result 0;
	%else 											%put ERROR: TEST FAILED - Different lists, but same (repeated) items: wrong result;

	%let list_1=NL_UK_DE_AT_BE;
	%let list_2=DE_AT_NL_BE_UK;
	%let sep=_;
	%put;
	%put (xi) Compare lists list1=&list_1 and list2=&list_2 (with sep=&sep)...;
	%if %list_compare(&list_1, &list_2, sep=&sep)=0 %then 	%put OK: TEST PASSED - list1=list2: result 0;
	%else 													%put ERROR: TEST FAILED - Identical lists: wrong result;

	%let list_1=NL_UK_DE_AT_BE_FR;
	%let list_2=DE_AT_NL_BE_UK;
	%let sep=_;
	%put;
	%put (xii) Compare lists list1=&list_1 and list2=&list_2 (with sep=&sep)...;
	%if %list_compare(&list_1, &list_2, sep=&sep)=1 %then 	%put OK: TEST PASSED - list1>list2: result 1;
	%else 													%put ERROR: TEST FAILED - list1>list2: wrong result;

	%put;
%mend _example_list_compare;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_compare;  
*/

/** \endcond */
