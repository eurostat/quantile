/**
## list_remove {#sas_list_remove}
Remove one or more items from an unformatted list. 

	%let res=%list_remove(list, item, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `item` : (list of) item(s) to remove from the list;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the all (low-case or upper-case) occurrences of the pattern `item` will be removed;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` 
	is blank.
 
### Returns
`res` : output list where all occurences of the item(s) present in both `item` and `list` lists 
	have been removed.

### Examples

	%let list=DE AT BE NL AT SE;
	%let mylist=%list_remove(&list, AT);
	
returns: `mylist=DE BE NL SE`, while similarly:
 
	%let list=0 0.1 1 2 3 3.5 4;
	%let mylist=%list_remove(&list, 0.1 3 4);
	
returns: `mylist=0 1 2 3 3.5`.

Run macro `%%_example_list_remove` for more examples.

### See also
[%list_count](@ref sas_list_count), [%list_compare](@ref sas_list_compare), [%list_slice](@ref sas_list_slice), 
[%list_append](@ref sas_list_append).
*/ /** \cond */

%macro list_remove(list 		/* List of blank separated items 					(REQ) */
				, item 			/* (list of) item(s) to remove from the input list 	(REQ) */ 
				, casense=no	/* Boolean flag set for case sensitive matching 	(OPT) */
				, sep=			/* character/string used as list separator 			(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%local _i _k	/* increment counters */	
		_v 			/* scanned element from the input list */
		_item  		/* scanned element from the item list */
		_llen  		/* lenght of input list */
		_litem 		/* lenght of item list */
		_olist; 	/* output result */

	/* set default output to empty */
	%let _olist=;

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&casense), type=CHAR, set=YES NO) NE 0,	
			txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;
	%else %if %upcase("&casense")="NO" %then %do;
		%let list=%upcase(&list);
		%let item=%upcase(&item);
	%end;

	%if %macro_isblank(sep)  %then %let sep=%quote( ); /* list separator */

	%let _llen=%list_length(&list, sep=&sep);
	%let _litem=%list_length(&item, sep=&sep);

	%do _k=1 %to &_llen;
		%let _v=%scan(&list, &_k, &sep);
		%do _i=1 %to &_litem;
			%let _item=%scan(&item, &_i, &sep);
			%if %quote(&_v)=%quote(&_item) %then  
				%goto next; /*_v won't be inserted in the output list */
		%end;
		%let _olist=&_olist.&sep.&_v;
		%next:
	%end;

	%if not %macro_isblank(_olist) %then 	%let _olist=%sysfunc(trim(&_olist));

	%exit:
	&_olist
%mend list_remove;

%macro _example_list_remove;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local list item olist;

	%let list=DE IT GR UK LT toto;
	%let item=LT;
	%put;
	%put (i) Remote the item=&item from the char list=&list;
	%let olist=DE IT GR UK toto;
	%if %list_remove(&list, &item)=&olist %then 	%put OK: TEST PASSED - List returned: &olist;
	%else 											%put ERROR: TEST FAILED - Wrong list returned;

	%put;
	%let item=LT UK;
	%put (ii) Same operation, removing more items: &item;
	%let olist=DE IT GR toto;
	%if %list_remove(&list, &item)=&olist %then 	%put OK: TEST PASSED - List returned: &olist;
	%else 											%put ERROR: TEST FAILED - Wrong list returned;

	%let list=0 1 0.1 0.2 2 0 1 10 0.5 0;
	%let item=0;
	%put;
	%put (iii) Remote the item=&item from the numeric list=&list;
	%let olist=1 0.1 0.2 2 1 10 0.5;
	%if %list_remove(&list, &item)=&olist %then 	%put OK: TEST PASSED - List returned: &olist;
	%else 											%put ERROR: TEST FAILED - Wrong list returned;

	%put;
	%let item=0 0.2;
	%put (iv) Same operation, removing more items: &item;
	%let olist=1 0.1 2 1 10 0.5;
	%if %list_remove(&list, &item)=&olist %then 	%put OK: TEST PASSED - List returned: &olist;
	%else 											%put ERROR: TEST FAILED - Wrong list returned;

	%put;
%mend _example_list_remove;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_remove; 
*/

/** \endcond */
