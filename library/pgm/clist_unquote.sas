/** 
## clist_unquote {#sas_clist_unquote}
Transform a parentheses-enclosed, comma-separated, and quote-enhanced list of items into an 
unformatted/unquoted list. 

	%let list=%clist_unquote(clist, mark=%str(%"), sep=%quote(,), rep=%quote( ));

### Arguments
* `clist` : a list of items comma-separated by a delimiter (_e.g._, quotes) and in between 
	parentheses;
* `mark` : (_option_) character/string used as "quote" the elements in the input list; note the 
	particular case where it is passed as `mark=_EMPTY_` then it is set to `mark=%%quote()`; 
	default: `mark` is the double quote "; 
* `sep` : (_option_) character/string separator in input list; default: `%%quote(,)`, _i.e._ 
	`sep` the input list is comma separated;
* `rep` : (_option_) character/string used to replace the separator in the output list; default: 
	`%%quote( )`, _i.e._ `rep` is blank by default.
 
### Returns
`list` : output unformatted list of (unquoted) strings.

### Examples

	%let clist=("A","B","C","D","E");
	%let list=%clist_unquote(&clist);
	
returns `list=A B C D E`.

Run macro `%%_example_clist_unquote` for more examples.

### Notes
1. The following command:

       %let clist=(A,B,C,D,E);
       %let list=%clist_unquote(&clist, mark=_EMPTY_);
returns `list=A B C D E`, while other possible uses include:

	%let var1="a,b,c";
    %put %clist_unquote(%quote(%(&var1%)), sep=%quote( ));
    %let var2=("a,b,c");
    %put %clist_unquote(&var2, sep=%quote( ));
    %let var3=("a"/"b"/"c");
    %put %clist_unquote(&var3, sep=%quote(/), rep=%quote(,));
which all display `a,b,c`.
2. The macro also deals with "empty" items, _e.g._:

       %let clist=("A",,,"D","E");
	   %let list=%clist_unquote(&clist, mark=_EMPTY_);
will return `list=A D E`.
3. Finally note the idempotence:
	
       %let clist1=("A","B","C","D","E");
       %let clist2=(%list_quote(%clist_unquote(&clist1)));
since then `clist1=clist2`.

### References
(see also references in [%list_quote](@ref sas_list_quote))
1. Carpenter, A.L. (1999): ["Macro quoting functions, other special character masking tools, and how to use them"](http://www.ats.ucla.edu/stat/sas/library/nesug99/ad088.pdf).
2. Whitlock, I. (2003): ["A serious look macro quoting"](http://www2.sas.com/proceedings/sugi28/011-28.pdf).
3. Chaudhary, K.R. (2015): ["Essentials of macro quoting functions in SAS"](http://www.mwsug.org/proceedings/2015/RF/MWSUG-2015-RF-08.pdf).

### See also
[%list_quote](@ref sas_list_quote),
[TRANWRD](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000215027.htm),
[COMPBL](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000214211.htm),
[COMPRESS](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000212246.htm),
[FIND](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002267763.htm),
[%UNQUOTE](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a000543618.htm).
*/ /** \cond */

%macro clist_unquote(clist 	/* List of items comma-separated by a delimiter and between parentheses (REQ) */
					, mark=	/* Character/string used to quote items in input lists 					(OPT) */
					, sep=	/* Character/string used as string separator in input list				(OPT) */
					, rep=	/* Replacement of list separator 										(OPT) */
					);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* default settings */
	%if %macro_isblank(mark) %then 							%let mark=%str(%"); 
	%else %if &mark EQ _EMPTY_ or &mark EQ _empty_ %then 	%let mark=%quote(); 
	%if %macro_isblank(sep) %then 							%let sep=%quote(,); 
	%else %if &sep EQ _EMPTY_ or &sep EQ _empty_ %then 		%let sep=%quote( ); 
	%if %macro_isblank(rep) %then 							%let rep=%quote( );   

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _clist	/* temporary formatted list */
		_list; 		/* output list */	
	/* set default output to empty */
	%let _list =;

	/* deal with the most common use 
	* !!! this does not support lists containing empty items !!! 
	%if &sep=%quote(,) and &mark=%str(%") and &rep=%quote( ) %then %do;
		%let _list=%sysfunc(strip(%qsysfunc(tranwrd(
									%qsysfunc(tranwrd(
										%qsysfunc(tranwrd(%sysfunc(compbl(&clist)), 
											%quote(","), %quote( ))),
										%str(%(%"), %quote())), 
									%str(%"%)), %quote()))
								));
		%goto exit;
	%end;
	*/

	/* first get rid of potential carriage returns, blanks, ... in between segments */
	%let _clist = %sysfunc(compbl(&clist));
	/* the syntax for taking out all carriage return ('OD'x) and line feed ('OA'x) characters is 
		%sysfunc(tranwrd(&clist,'0D'x,''));
		%sysfunc(tranwrd(&clist,'OA'x,''));
	%let _clist = %sysfunc(compress(%quote(&clist), ,s));
	*/

	/* remove enclosing parentheses (i.e., replace with blanks) that appear together
	* with the mark (e.g. (" and ") ) */
	%let _list=%bquote(%sysfunc(tranwrd(&_clist, &mark%str(%)), %str( ))));

	%let _list=%bquote(%sysfunc(tranwrd(&_list,	 %str(%()&mark, %str( )))); 


	/* in the case of "empty" items, at the beginning or the end of the list, remove enclosing 
	parentheses that appear together with the sep (e.g. (" and ") ) */
	%let _list=%bquote(%sysfunc(tranwrd(&_list, &mark.&sep%str(%)), %str( ))));
	%let _list=%bquote(%sysfunc(tranwrd(&_list,	 %str(%()&sep.&mark, %str( )))); 

	/* replace the occurrences of duplicated separators (when empty item) */
	%do %while(%sysfunc(find(&_list, %quote(&sep.&sep))));
		%let _list=%bquote(%sysfunc(tranwrd(&_list,	 &sep.&sep, &sep))); 
	%end; 

	/* replace the marks and separators occurrences "," */
	%let _list=%bquote(%sysfunc(tranwrd(&_list, &mark.&sep.&mark, &rep))); 

	/* replace special occurrences with blanks, either of the form: ", " */
	%let _list=%bquote(%sysfunc(tranwrd(&_list, &mark.&sep%quote( )&mark, &rep))); 
	/* or of the form: " ," */
	%let _list=%bquote(%sysfunc(tranwrd(&_list, &mark%quote( )&sep.&mark, &rep))); 
	/* or even of the form: " , " */
	%let _list=%bquote(%sysfunc(tranwrd(&_list, &mark%quote( )&sep%quote( )&mark, &rep))); 

	/* note: if we had to accept clist without enclosing parentheses, we would run instead:
	%let _list=%quote(%sysfunc(tranwrd(%quote(&_clist), &mark%str(%)), %str( ))));
	%let _list=%quote(%sysfunc(tranwrd(%quote(&_list),	 %str(%()&mark, %str( )))); 
	%let _list=%quote(%sysfunc(tranwrd(%quote(&_list), &mark.&sep.&mark, &rep))); 
	*/

	/* at this stage, test if we have an empty list, i.e. ( ) was passed in input */
	%if %quote(&_list)^="()" and %quote(&_list)^= /* not %macro_isblank(_list) */ %then %do;
		/* compress the blanks */
		%let _list = %sysfunc(compbl(%quote(&_list)));
	%end;

	%exit:
	&_list
%mend clist_unquote;

%macro _example_clist_unquote;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local clist olist sep rep;

	%put;
	%put (i) When one passes an empty list (""):;
	%let clist =("");
	%let olist=;
	%if %macro_isblank(%clist_unquote(&clist)) %then 	%put OK: TEST PASSED - empty list returned;
	%else 												%put ERROR: TEST FAILED - wrong list returned;

	%let clist =("toto","assa","muf","ougl","zorro");
	%let olist=toto assa muf ougl zorro;
	%put;
	%put (ii) Test the comma-separated list &clist with default mark/sep/rep...;
	%if %clist_unquote(&clist) EQ %quote(&olist) %then 	%put OK: TEST PASSED - returns: &olist;
	%else 												%put ERROR: TEST FAILED - wrong list returned;

	%let clist =("toto",,"muf","ougl",);
	%let olist=toto muf ougl;
	%put;
	%put (iii) Test the comma-separated list &clist, where one item is missing, with default mark/sep/rep...;
	%if %clist_unquote(&clist) EQ %quote(&olist) %then 	%put OK: TEST PASSED - returns: &olist;
	%else 												%put ERROR: TEST FAILED - wrong list returned;

	%let clist =('toto','assa','muf','ougl','zorro');
	%let olist=toto assa muf ougl zorro;
	%let mark=%str(%');
	%put;
	%put (iv) Test the equivalent list with single quote: clist=&clist with mark=&mark ...;
	%if %clist_unquote(&clist, mark=&mark) EQ %quote(&olist) %then 	%put OK: TEST PASSED - returns: &olist;
	%else 															%put ERROR: TEST FAILED - wrong list returned;

	%let clist =(toto tata,assa,muf,ougl,zorro);
	%let olist=toto tata_assa_muf_ougl_zorro;
	%let rep=_;
	%let mark=_EMPTY_;
	%put;
	%put (v) Test the unquoted list &clist, with mark=&mark and rep=&rep...;
	%if %clist_unquote(&clist, mark=&mark, rep=&rep) EQ %quote(&olist) %then 	
		%put OK: TEST PASSED - returns: &olist;
	%else 																	
		%put ERROR: TEST FAILED - wrong list returned;

	%let clist =("toto","assa","muf",
				 "ougl","zorro"); /* string with return char */
	%let olist=%str(toto;assa;muf;ougl;zorro); /* note the use of str since there are ; characters */
	%let mark=%str(%");
	%let rep=%str(;);
	%put;
	%put (vi) Test a list &clist with carriage return, mark=&mark and rep=&rep ...;
	%if %bquote(%clist_unquote(&clist, mark=&mark, rep=&rep)) EQ %bquote(&olist) %then 	
		%put OK: TEST PASSED - returns: &olist;
	%else 																	
		%put ERROR: TEST FAILED - wrong list returned;

	%let clist =("toto assa" , "muf ougl" , "zorro est arrive");
	%let olist=toto assa muf ougl zorro est arrive;
	%put;
	%put (vii) Test the comma-separated list &clist with default mark/sep/rep...;
	%if %clist_unquote(&clist) EQ %quote(&olist) %then 	%put OK: TEST PASSED - returns: &olist;
	%else 												%put ERROR: TEST FAILED - wrong list returned;

%mend _example_clist_unquote;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_unquote; 
*/

/** \endcond */
