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
