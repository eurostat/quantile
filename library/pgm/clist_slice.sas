/**
## clist_slice {#sas_clist_slice}
Slice a list, _i.e._ extract a sequence of items from the beginning and/or ending positionsand/or 
matching items.

	%let res=%clist_slice(clist, beg=, ibeg=, end=, iend=, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist` : a list of formatted (_e.g._, comma-separated quote-enhanced) strings;
* `beg` : (_option_) item to look for in the input list; the slicing will 'begin' from the
	first occurrence of `beg` (with quotes); if not found, an empty list is returned;
* `end` : (_option_) ibid, the slicing will 'end' at the first occurrence of `end`; if not found, 
	the slicing is done till the last item;
* `ibeg` : (_option_) position of the first item to look for in the input list; must be a numeric
	value >0; if the value is > length of the input list, an empty list is returned; incompatible
	with `beg` option (see above); if neither `beg` nor `ibeg` is passed, `ibeg` is set to 1; 
* `iend` : (_option_) ibid, position of the last item; must be a numeric value >0; in the case 
	`iend<iend`, an empty list is returned; in the case, `iend=ibeg` then the item `beg` (in position 
	`ibeg`) is returned; incompatible with `end` option (see above); if neither `end` nor `iend` is 
	passed, `iend` is set to the length of `list`;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`res` : output list defined as the sequence of items extract from the input list `list` from the `ibeg`-th 
	position or the first occurrence of `beg`, till the `iend`-th position or the first occurrence of `end` 
	(after the `ibeg`-th position).

### Examples

	%let clist=("a","bb","ccc","dddd","bb","fffff");
	%let res=%clist_slice(&clist, beg=bb, iend=4);
	
returns: `res=("bb","ccc")`, while
 
	%let res=%clist_slice(&list, beg=ccc);
	%let res2=%clist_slice(&list, ibeg=bb, end=bb);
	%let res3=%clist_slice(&list, beg=ccc, iend=3);
	
return respectively: `res=("bb","ccc","dddd","bb","fffff")`, `res2=("bb","ccc","dddd")` and `res3=("ccc")`.

Run macro `%%_example_clist_slice` for more examples.

### Notes
1. The parameters `beg` and `end` shall be passed without the quotes ".
2. The first occurrence of `end` is necessarily searched for in `list` after the `ibeg`-th position (or first occurrence of `beg`).
3. The item at position `iend` (or first occurrence of `end`) is not inserted in the output `res` list.
4. The macro returns an empty list `res=` instead of () when there is no match.
5. The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_slice](@ref sas_list_slice), [%clist_compare](@ref sas_clist_compare), [%clist_append](@ref sas_clist_append), 
[%clist_unquote](@ref sas_clist_unquote).
*/ /** \cond */

%macro clist_slice(clist 	/* List of items comma-separated by a delimiter and between parentheses (REQ) */
				, beg=  	/* First item to look for in the list 									(OPT) */
				, ibeg= 	/* Index of the first item to look for in the list 						(OPT) */
				, end=  	/* Last item to look for in the list 									(OPT) */
				, iend= 	/* Index of the last item to look for in the list 						(OPT) */
				, mark=		/* Character/string used to quote items in input lists 					(OPT) */
				, sep=		/* Character/string used as list separator 								(OPT) */
				);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* default settings */
	%if %macro_isblank(mark) %then 			%let mark=%str(%"); /* mark */
	%else %if %upcase(&mark)=_EMPTY_ %then 	%let mark=%quote(); 
	%if %macro_isblank(sep) %then 			%let sep=%quote(,);  /* clist separator */
	/* note that all types of checkings are already performed in clist_unquote/list_slice */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local REP; 	/* replacement of list separator */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	/* 3. reform again the initial list of characters (note the inversion of sep/rep) 
	* 	using %list_quote */
	(%list_quote(
		/* 2. perform the actual desired slicing */
		%list_slice(
				/* 1. transform the list of characters into a blank separated list
				* 	(easier to manipulate) using %clist_unquote */
				%clist_unquote(&clist, mark=&mark, sep=&sep, rep=&REP), 
				beg=&beg, ibeg=&ibeg, 
				end=&end, iend=&iend, 
				sep=&REP),
		mark=&mark, sep=&REP, rep=&sep))

%mend clist_slice;

%macro _example_clist_slice;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local clist beg ibeg end iend oclist;

	%let clist=("aaa","bbbb","c","dd","aaa","eeee");

	%let ibeg=a;
	%put;
	%put (i) Test the program with dummy parameters: ibeg=&ibeg;
	%if %macro_isblank(%clist_slice(&clist, ibeg=&ibeg)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let ibeg=-1;
	%put;
	%put (ii) Test the program with dummy parameters: ibeg=&ibeg;
	%if %macro_isblank(%clist_slice(&clist, ibeg=&ibeg)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let ibeg=5;
	%let iend=2;
	%put;
	%put (iii) Test the program with dummy parameters: ibeg=&ibeg and iend=&iend;
	%if %macro_isblank(%clist_slice(&clist, ibeg=&ibeg, iend=&iend)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let beg=a;
	%put;
	%put (iv) Test the program with dummy parameters: beg=&beg (item not in the list);
	%if %macro_isblank(%clist_slice(&clist, beg=&beg)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let beg=bbbb;
	%put;
	%put (v) Extract all items from the first occurrence of "&beg" till the end (iend/end not set);
	%let oclist=("bbbb","c","dd","aaa","eeee");
	%if %bquote(%clist_slice(&clist, beg=&beg))=%bquote(&oclist) %then 	
		%put OK: TEST PASSED - List returned: &oclist;
	%else 												
		%put ERROR: TEST FAILED - Wrong list returned;
	
	%let ibeg=3;
	%let end=dd;
	%put;
	%put (vi) Extract all items from the &ibeg.rd position till the first occurrence of "&end";
	%let oclist=("c");
	%if %bquote(%clist_slice(&clist, ibeg=&ibeg, end=&end))=%bquote(&oclist) %then 	
		%put OK: TEST PASSED - List returned: &oclist;
	%else 															
		%put ERROR: TEST FAILED - Wrong list returned;
	
	%let beg=bbbb;
	%let iend=2;
	%put;
	%put (vii) Extract all items from the first occurrence of "&beg" till the &iend.nd position;
	%let oclist=("bbbb"); 
	%if %bquote(%clist_slice(&clist, beg=&beg, iend=&iend))=%bquote(&oclist) %then 	
		%put OK: TEST PASSED - List returned: &oclist;
	%else 															
		%put ERROR: TEST FAILED - Wrong list returned;
	
	%let ibeg=2;
	%let end=c;
	%put;
	%put (viii) Extract all items from the &ibeg.nd position till the first occurrence of "&end";
	%let oclist=("bbbb"); /* same as case (vii) */
	%if %bquote(%clist_slice(&clist, ibeg=&ibeg, end=&end))=%bquote(&oclist) %then 	
		%put OK: TEST PASSED - List returned: &oclist;
	%else 															
		%put ERROR: TEST FAILED - Wrong list returned;
	
	%let ibeg=1;
	%let end=aaa;
	%put;
	%put (ix) Extract all items from the &ibeg.rst position till the first occurrence of "&end";
	%let oclist=("aaa","bbbb","c","dd"); /* the first occurrence of aaa is searched for after the 1st position */
	%if %bquote(%clist_slice(&clist,ibeg=&ibeg, end=&end))=%bquote(&oclist) %then 	
		%put OK: TEST PASSED - List returned: &oclist;
	%else 																
		%put ERROR: TEST FAILED - Wrong list returned;

	%put;
%mend _example_clist_slice;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_slice; 
*/

/** \endcond */