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
