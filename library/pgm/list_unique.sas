/** 
## list_unique {#sas_list_unique}
Trim a given list from its duplicated elements and return the list of unique items.

	%let luni=%list_unique(list, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of unformatted strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive representation; default:
	`casense=no`, _i.e._ lower- and upper-case versions of the same strings are regarded as repeated 
	elements and one only shall be kept;
* `sep` : (_option_) character/string used as a separator in the input list; default: `sep=%%quote( )`, 
	_i.e._ the input `list` is blank-separated lists of items.
 
### Returns
`luni` : output list of unique elements present in the input list `list`; when the case unsentiveness is
	set (through `casense=no`), `luni` is returned as a list of upper case elements.

### Examples
We show some simple examples of use, namely: 

	%let list=A B b b c C D E e F F A B E D;
	%let luni=%list_unique(&list, casense=yes);
	
returns: `luni=A B b c C D E e F`, while:

	%let luni=%list_unique(&list);
	
returns: `luni=A B C D E F`.

Run macro `%%_example_list_unique` for more examples.

### See also
[%clist_unique](@ref sas_clist_unique), [%list_difference](@ref sas_list_difference), [%list_compare](@ref sas_list_compare), 
[%list_append](@ref sas_list_append), [%list_find](@ref sas_list_find), [%list_count](@ref sas_list_count).
*/ /** \cond */

%macro list_unique(list 		/* List of blank separated items 					(REQ) */
				, casense=no	/* Boolean flag set for case sensitive comparison 	(OPT) */
				, sep=			/* Character/string used as list separator 			(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%local _i 	/* increment counter */	
		_item 	/* scanned element from the input list */
		_luni; 	/* output result */
			
	/* set default output to empty */
	%let _luni=;

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&casense), type=CHAR, set=YES NO) NE 0,	
			txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

	/* default setting */
	%if %macro_isblank(sep) %then 	%let sep=%quote( );  /* list separator */

	%if %upcase("&casense")="NO" %then 
		%let list=%upcase(&list);

	/* loop */
	%do _i=1 %to %list_length(&list, sep=&sep);
		%let _item = %scan(&list, &_i, &sep);
		%if %macro_isblank(_luni) %then 
			%let _luni=&_item;
		%else %if %sysfunc(find(&_luni, &_item))<=0 %then 
			%let _luni=&_luni.&sep.&_item;
	%end;

	%exit:
	&_luni
%mend list_unique;

%macro _example_list_unique;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local list olist;

	%let list=A B b b c C D E e F F A B E D;
	%put;
	%put (i) Return the list of unique (case unsensitive: casense=yes) elements in list=&list ...;
	%let olist=A B b c C D E e F;
	%if %list_unique(&list, casense=yes) EQ %quote(&olist) %then 
		%put OK: TEST PASSED - Unique representation of list: &olist;
	%else											
		%put ERROR: TEST FAILED - Wrong list of unique elements returned;

	%put;
	%put (ii) Ibid, considering the case sensitiveness (default: casense=no) ...;
	%let olist=A B C D E F;
	%if %list_unique(&list) EQ %quote(&olist) %then 
		%put OK: TEST PASSED - Unique case sensitive representation of list: &olist;
	%else														
		%put ERROR: TEST FAILED - Wrong list of unique elements returned;

	%put;
%mend _example_list_unique;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_unique; 
*/

/** \endcond */
