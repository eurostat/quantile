/** 
## list_length {#sas_list_length}
Compute the length of an unformatted (_i.e._, blank separated) list of strings. 

	%let len=%list_length(list, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`len` : output length, _i.e._ the length of the considered list (calculated as the number of strings 
	separated by `sep`).

### Examples

	%let list=DE_UK_LU_AT_EL_IT;
	%let len=%list_length(&list, sep=_);
	
returns `len=6`.

Run macro `%%_example_list_length` for examples.

### Note
As kindly reported by P.BBES.Lamarche (<mailto:pierre.lamarche@ec.europa.eu>, _a.k.a_ the "Base-Ball 
Equation Solver") in his own well-tempered language, this macro is mostly useless as one can check that 
running `%list_length(&list, &sep)` is essentially nothing else than:
	
	%sysfunc(countw(&list, &sep));

Still, we enjoyed recoding it (and so did the GSAST guys, though it seemed "complex"). Further note that
one could also use (in the case `sep=%%quote( )`):

	%eval(1 + %length(%sysfunc(compbl(&list))) - %length(%sysfunc(compress(&list))))

### See also
[%clist_length](@ref sas_clist_length), [%list_count](@ref sas_list_count), 
[LENGTH](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000218807.htm).
[COUNTW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002977495.htm).
*/ /** \cond */

%macro list_length(list /* List of blank separated items 			(REQ) */
				, sep=	/* Character/string used as list separator 	(OPT) */
				);
	%local _len; /* result length returned */

	/* set default output to empty */
	%let _len=0;

	%if %macro_isblank(list) %then 
		%goto exit;

	%if %macro_isblank(sep) %then %let sep=%quote( ); /* list separator */

	%let _len=1;
	%do %while (%quote(%scan(&list, &_len, &sep)) ne %quote());
		/* note the use of %quote: this is necessary when dealing with items like -3.55 (example iv below) */
		%let _len=%eval(&_len+1);
	%end;
	%let _len=%eval(&_len-1);

	%exit:
	/* return the answer */
	/* try also: %sysfunc(countw(&list, &sep)) */
	&_len
%mend list_length;


%macro _example_list_length;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local len;

	%let list=;
	%put;
	%put (i) Compute the length of...an empty list; /* 0? */
	%if %list_length(&list)=0 %then 			%put OK: TEST PASSED - 0 returned;
	%else 										%put ERROR: TEST FAILED - Wrong length returned;

	%let list=NL UK DE AT BE;
	%put;
	%put (ii) Compute the length of the CHAR list &list; /* 5? */
	%if %list_length(&list)=5 %then 			%put OK: TEST PASSED - 5 returned;
	%else 										%put ERROR: TEST FAILED - Wrong length returned;

	%let list=toto_UK_popo_AT_EL_IT;
	%let sep=_;
	%put;
	%put (iii) Compute the length of the CHAR list &list with sep=&sep; /* 6? */
	%if %list_length(&list, sep=&sep)=6 %then 	%put OK: TEST PASSED - 6 returned;
	%else 										%put ERROR: TEST FAILED - Wrong length returned;

	%let list=0 1.5 -2 -3.55 4;
	%let sep=%str( );
	%put;
	%put (iv) Compute the length of the NUMERIC list &list with sep=&sep; /* 5? */
	%if %list_length(&list, sep=&sep)=5 %then 	%put OK: TEST PASSED - 5 returned;
	%else 										%put ERROR: TEST FAILED - Wrong length returned;

	%put;
%mend _example_list_length;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_length; 
*/

/** \endcond */
