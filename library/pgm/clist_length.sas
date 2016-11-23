/** 
## clist_length {#sas_clist_length}
Compute the length of a formatted (_i.e._, comma-separated and quota-enhanced) list of strings. 

	%let len=%clist_length(clist, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist` : a list of formatted (_e.g._, comma-separated quote-enhanced) strings;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`len` : output length, _i.e._ the length of the  considered list (say it otherwise, the number 
	of strings separated by `mark`).

### Examples

	%let clist=("DE","AT","BE","NL","UK","SE");
	%let len=%clist_length(&clist);
	
returns `len=6`.

Run macro `%%_example_clist_length` for more examples.

### Notes
1. Note the "special" treatment of empty items, _e.g._

       %let clist=("DE",,,,"UK");
       %let len=%clist_length(&clist);
will return `len=2`, _i.e._ the comma-separated empty items are not taken into
account in the counting.
2. See note of [%list_length](@ref sas_list_length).
3. The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_length](@ref sas_list_length), [%clist_unquote](@ref sas_clist_unquote).
*/ /** \cond */

%macro clist_length(clist 	/* List of items comma-separated by a delimiter and between parentheses (REQ) */
					, mark=	/* Character/string used to quote items in input lists 					(OPT) */
					, sep=	/* Character/string used as list separator 								(OPT) */
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

	%local REP;	/* replacement of list separator */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	/* Method 1
	%let _len=1;
	%let _clist=%sysfunc(tranwrd(&clist, %str(%)), %quote()));
	%let _clist=%sysfunc(tranwrd(%bquote(&_clist), %str(%(), %quote()));
	%do %while (%quote(%scan(%bquote(&_clist), &_len, &sep)) ne %quote());
		%let _len=%eval(&_len+1);
	%end;
	%eval(&_len-1)
	*/

	/* Method 2
	* compute the length of the unformatted list */
	%list_length(%clist_unquote(&clist, mark=&mark, sep=&sep, rep=&REP), sep=&REP) 

	/* Method 3
	%sysfunc(countw(&clist, &sep))
	*/

%mend clist_length;

%macro _example_clist_length;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let clist=("DE","AT","BE","NL","UK","SE");
	%put;
	%put (i) Compute the length of clist=&clist; /* 6? */
	%if %clist_length(&clist)=6 %then 			%put OK: TEST PASSED - Length 6 returned;
	%else 										%put ERROR: TEST FAILED - Wrong length returned;

	%let clist =("AT","BE","NL");
	%put;
	%put (ii) Compute the length of clist=&clist; /* 3? */
	%if %clist_length(&clist)=3 %then 			%put OK: TEST PASSED - Length 3 returned;
	%else 										%put ERROR: TEST FAILED - Wrong length returned;

	%let clist =("AT",,"NL");
	%put;
	%put (iii) Compute the length of clist=&clist; /* 2? */
	%if %clist_length(&clist)=2 %then 			%put OK: TEST PASSED - Length 2 returned (though we may have preferred 3: see next result);
	%else 										%put ERROR: TEST FAILED - Wrong length returned;

	%let clist=("DE","AT",,,,"UK");
	%put;
	%put (iv) Similarly, compute the length of clist=&clist; /* 3? */
	/*%let res=%sysfunc(find(&clist, %quote(,,)));*/
	%if %clist_length(&clist)=3 %then 			%put OK: TEST PASSED - Length 3 returned (see previous result);
	%else 										%put ERROR: TEST FAILED - Wrong length returned;
	
	%put;								
%mend _example_clist_length;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_length; 
*/

/** \endcond */
