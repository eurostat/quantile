/** 
## list_quote {#sas_list_quote}
Transform an unformatted list of items (_e.g._ considered as char) into a list of comma-separated 
and/or quote-enhanced items. 

	%let clist=%list_quote(list, mark=%str(%"), sep=%quote( ), rep=%quote(,));

### Arguments
* `list` : a list of blank separated items/char;
* `mark` : (_option_) character/string used to quote the items in the output list; default: 
	`mark` is the double quote "; any type of character can be used, though the macros `%%str/%%quote` 
	should be employed to pass it in practice (see examples and notes below); note also the 
	particular case where it is passed as `mark=_EMPTY_` then it is set to `mark=%%quote()`;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` is 
	blank;
* `rep` : (_option_) character/string used to replace the separator in the output list; default: 
	`%%quote(,)`, _i.e._ the output list is comma separated; note that `rep=_BLANK_` can also be 
	passed so as to set `rep=%%quote( )`.
 
### Returns
`clist` : output formatted list of items, _e.g._, comma-separated items/char in between quotes..

### Examples
With the default settings `mark=%%str(%"), sep=%%quote( ), rep=%%quote(,)`, the following command:

	%let list=DE AT BE NL UK SE;
	%let clist=%list_quote(&list);
	
returns: `clist="DE","AT","BE","NL","UK","SE"`, while:

	%let clist=%list_quote(&list, mark=_EMPTY_);
	
returns: `clist=DE,AT,BE,NL,UK,SE`, and:

	%let clist=%list_quote(&list, mark=%quote(*), rep=%quote( ));
	
returns: `clist=*DE* *AT* *BE* *NL* *UK* *SE*`.
 
Finally, note also the following use:

	%let var=AGE RB090 HT1 QITILE;
	%let per_var=%list_quote(&var, mark=_EMPTY_, rep=%quote(*));

with returns `per_var=AGE*RB090*HT1*QITILE`.

Run macro `%%_example_list_quote` for more examples.

### Notes
* Note the different use of `%%quote` or `%%str` when the marks/separators are special characters (since 
it takes effect during macro compilation/execution). 
* When considering the above-mentioned default settings for `mark`, `rep` and `sep`, this is 
roughly equivalent to running:

	%let clist="%sysfunc(tranwrd(%sysfunc(compbl(&list)),%quote( ),%quote(", ")))";

### References
1. Carpenter, A.L. (1999): ["Macro quoting functions, other special character masking tools, and how to use them"](http://www.ats.ucla.edu/stat/sas/library/nesug99/ad088.pdf).
2. Whitlock, I. (2003): ["A serious look macro quoting"](http://www2.sas.com/proceedings/sugi28/011-28.pdf).
3. Patterson, B. and Remigio, M. (2007): ["Don't %QUOTE() me on this: A practical guide to macro quoting functions"](http://www2.sas.com/proceedings/forum2007/152-2007.pdf).
4. Chaudhary, K.R. (2015): ["Essentials of macro quoting functions in SAS"](http://www.mwsug.org/proceedings/2015/RF/MWSUG-2015-RF-08.pdf).

### See also
[%clist_unquote]\(@ref sas_clist_unquote),
[TRANWRD](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000215027.htm),
[COMPBL](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000214211.htm),
[COMPRESS](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000212246.htm),
[%BQUOTE](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#z3514bquote.htm).
*/ /** \cond */

%macro list_quote(list 	/* List of blank separated items 							(REQ) */
				, mark=	/* Character/string used to quote items in input list 		(OPT) */
				, sep=	/* Character/string used as string separator in input list	(OPT) */
				, rep=	/* Replacement of string separator 							(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _clist 	/* output list */
		_METHOD_ 	/* dummy parameter */;

	/* set default output to empty */
	%let _clist=;
	%let _METHOD_=CANONICAL;

	%if %macro_isblank(list) %then 	
		%goto exit;

	%if %macro_isblank(mark) %then 	%let mark=%str(%"); 
	%else %if &mark=_EMPTY_ %then 	%let mark=%quote(); /* mark */
	%if %macro_isblank(sep) %then 	%let sep=%quote( );  /* list separator */
	%if %macro_isblank(rep) %then 	%let rep=%quote(,);  /* replacement of list separator */
	%else %if &rep=_EMPTY_ /* stupid legacy*/ or &rep=_BLANK_ 	%then 	%let rep=%quote( ); /* mark */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%if &mark=%quote() /* _EMPTY_ was passed */ %then %do;
		%let _clist=%sysfunc(tranwrd(%qsysfunc(compbl(%sysfunc(strip(&list)))), &sep, &rep));
	%end;
	%else %if &mark EQ %str(%") %then %do; /* most common use we will make of it */
		/* note that the comparisons: &mark EQ %str(%"), &mark EQ %str(%')) and &rep EQ %quote(,) do not
		* take into account the blanks present in the string, e.g. if mark=%quote(,    ), then the test 
		* &mark EQ %str(%") still return true */
		%let _clist="%sysfunc(tranwrd(%sysfunc(compbl(&list)), &sep, %quote("&rep")))"; 
		/* note the use of %quote here... */
	%end; 
	%else %if &_METHOD_=CANONICAL %then %do;
		/* we use bquote here to ensure that this macro works with all types of marks, in particular
		 * when mark=%str(%') */
		%let _clist=&mark%bquote(%sysfunc(tranwrd(%sysfunc(compbl(&list)), &sep, &mark.&rep.&mark)))&mark;
	%end;
	%else %if &_METHOD_=LOOP %then %do;
		%local i;
		%do i=1 %to %sysfunc(countw(&list));
			%let item=%scan(&list,&i,&sep);
			%if &_clist= %then 		%let _clist=&mark.&item.&mark;
			%else 					%let _clist = &_clist.&rep.&mark.&item.&mark;
		%end; 
	%end;
	
	%exit:
	/*(&_clist%)*/
	&_clist

%mend list_quote;


%macro _example_list_quote;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let list=;
	%put;
	%put (i) Test the empty list=&list ...;
	%if %macro_isblank(%list_quote(&list)) %then 	%put OK: TEST PASSED - empty list returned;
	%else 											%put ERROR: TEST FAILED - wrong list returned;

	%let list=DE AT BE NL UK SE;
	%put;
	%put (ii) Default quote of an arbitrary list=&list ...;
	%let oclist="DE","AT","BE","NL","UK","SE";
	%if %list_quote(&list) EQ %quote(&oclist) %then %put OK: TEST PASSED - returns: %bquote(&oclist);
	%else 											%put ERROR: TEST FAILED - wrong list returned;

	%put;
	%put (iii) Ibid, using the separator rep="%quote(, )" ...;
	%let oclist="DE", "AT", "BE", "NL", "UK", "SE";
	%if %list_quote(&list, rep=%str(, )) EQ %quote(&oclist) %then 	%put OK: TEST PASSED - returns: %bquote(&oclist);
	%else 															%put ERROR: TEST FAILED - wrong list returned;

	%let rep=_EMPTY_;
	%put;
	%put (iv) Ibid, using this time rep=&rep ...;
	%let oclist="DE" "AT" "BE" "NL" "UK" "SE";
	%if %list_quote(&list,rep=&rep) EQ %quote(&oclist) %then  	%put OK: TEST PASSED - returns: %bquote(&oclist);
	%else 											 			%put ERROR: TEST FAILED - wrong list returned;

	%let mark=%str(%');
	%put;
	%put (v) Quote of the same list=&list with mark=&mark ...;
	%let oclist='DE','AT','BE','NL','UK','SE';
	%if %list_quote(&list, mark=&mark) EQ %quote(&oclist) %then %put OK: TEST PASSED - returns: %bquote(&oclist);
	%else 														%put ERROR: TEST FAILED - wrong list returned;

	%let list=DE_AT_BE_NL_UK_SE;
	%let mark=%quote(*);
	%let sep=_;
	%put;
	%put (vi) Paremeterised quote of an arbitrary list=&list with sep=&sep and mark=&mark ...;
	%let oclist=*DE*,*AT*,*BE*,*NL*,*UK*,*SE*; 
	/* note in this last example the use of %quote because of the combination of *, when testing */
	%if  %quote(%list_quote(&list, sep=&sep, mark=&mark)) EQ %quote(&oclist) %then 
		%put OK: TEST PASSED - returns: %quote(&oclist);
	%else 																
		%put ERROR: TEST FAILED - wrong list returned;

	%let list=DE AT BE NL UK SE;
	%put;
	%put (vii) Quote "without quotes" of an arbitrary list=&list using the mark=_EMPTY_ option...;
	%let oclist=DE,AT,BE,NL,UK,SE;
	%if %list_quote(&list, mark=_EMPTY_) EQ %quote(&oclist) %then 	%put OK: TEST PASSED - returns: %bquote(&oclist);
	%else 															%put ERROR: TEST FAILED - wrong list returned;

	%put;
	%let rep=_EMPTY_;
	%put (viii) Ibid "without quotes" (mark=_EMPTY_) and rep=_EMPTY_: dummy idempotent replacement!;
	%if %list_quote(&list, mark=_EMPTY_, rep=&rep) EQ %quote(&list) %then 	
		%put OK: TEST PASSED - returns: %bquote(&list);
	%else 															
		%put ERROR: TEST FAILED - wrong list returned;

	%put;
%mend _example_list_quote;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_quote; 
*/

/** \endcond */