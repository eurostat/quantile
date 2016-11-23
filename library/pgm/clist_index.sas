/**
## clist_index {#sas_clist_index}
Extract elements from a formatted list at given position(s).

	%let res=%clist_index(clist, index, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist` : a formatted (_e.g._, parentheses-enclosed, comma-separated quote-enhanced) list;
* `index` : a list of numeric indexes providing with the positions of items to extract from `list`; 
	must that the values of items in `index` should be < length of the list and >0; 
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) 
	for further details.
 
### Returns
`res` : output list defined as the sequence of elements extract from the input list `list` so that:
		+ the `i`-th element in `res` is equal to the `j`-th element of `list` where the position `j` 
		is given by the `i`-th element of `index`.

### Examples

	%let index = 3 5 2 100 4 1;
	%let list=("a","bb","ccc","dddd","bb","fffff");
	%let res=%list_index(&list, &index);
	
returns: `res=("ccc","bb","bb","dddd","a")` since the index 100 is ignored.
 
Run macro `%%_example_clist_index` for more examples.

### Notes
1. Indexes larger than the length of the input list `clist` are ignored, while whenever one index is <0,
and error is generated.
2. For wrongly typed indexes (_e.g._ non numeric index), an error is also generated.
3. In general case of error, the output `res` returned is empty (_i.e._ `res=`).
4. The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_index](@ref sas_list_index), [%clist_slice](@ref sas_clist_slice), [%clist_compare](@ref sas_clist_compare), 
[%clist_append](@ref sas_clist_append),
[%INDEX](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a000543562.htm).
*/ /** \cond */

%macro clist_index(clist 	/* List of items comma-separated by a delimiter and between parentheses (REQ) */
				, index		/* (List of) position(s) of elements to extract from the list 	(REQ) */
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
	/*%else %if %upcase(&sep)=_EMPTY_ %then 	%let sep=%quote( ); */
	/* note that all types of checkings are already performed in clist_unquote/list_slice */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local REP; 	/* replacement of list separator */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	/* 3. reform again the initial list of characters (note the inversion of sep/rep) 
	* 	using %list_quote */
	(%list_quote(
		/* 2. return the desired item at position given by index */
		%list_index(
				/* 1. transform the list of characters into a blank separated list
				* 	(easier to manipulate) using %clist_unquote */
				%clist_unquote(&clist, mark=&mark, sep=&sep, rep=&REP), 
				&index, sep=&REP),
		mark=&mark, sep=&REP, rep=&sep))

%mend clist_index;

%macro _example_clist_index;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local clist index oclist;

	%let clist=("aaa","bbbb","c","dd","aaa","eeee");

	%let index=4 2 1 2;
	%put;
	%put (i) Extract all items in positions (&index);
	%let oclist=("dd","bbbb","aaa","bbbb");
	%if %clist_index(&clist, &index) EQ &oclist %then 	%put OK: TEST PASSED - List returned: &oclist;
	%else 												%put ERROR: TEST FAILED - Wrong list returned;

	%let index=5 3 2 4 8 3; /* one will be ignored */
	%put;
	%put (ii) Extract all items in positions (&index), where one index is > %clist_length(&clist);
	%let oclist=("aaa","c","bbbb","dd","c"); 
	%if %clist_index(&clist, &index) EQ &oclist %then 	%put OK: TEST PASSED - List returned: &oclist;
	%else 												%put ERROR: TEST FAILED - Wrong list returned;

	%let clist=("aaa h","c","bbbb gg","dd ee","c dd"); 
	%let index=1 5 3; /* one will be ignored */
	%put;
	%put (iii) Extract all items in positions (&index) from clist=&clist;
	%let oclist=("aaa h","c dd","bbbb gg"); 
	%if %clist_index(&clist, &index) EQ &oclist %then 	%put OK: TEST PASSED - List returned: &oclist;
	%else 												%put ERROR: TEST FAILED - Wrong list returned;

	%put;
%mend _example_clist_index;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_index; 
*/ 

/** \endcond */
