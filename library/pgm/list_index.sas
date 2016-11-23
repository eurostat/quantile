/**
## list_index {#sas_list_index}
Extract elements from a list at given position(s).

	%let res=%list_index(list, index, sep=%quote( ));

### Arguments
* `list` : a list of (_e.g._, blank separated) items;
* `index` : a list of numeric indexes providing with the positions of items to extract from `list`; 
	must that the values of items in `index` should be < length of the list and >0; 
* `sep` : (_option_) character/string separator in input list `list` (but not `index`); default: 
	`%%quote( )`, _i.e._ `sep` is blank.
 
### Returns
`res` : output list defined as the sequence of elements extract from the input list `list` so that:
		+ the `i`-th element in `res` is equal to the `j`-th element of `list` where the position `j` 
		is given by the `i`-th element of `index`.

### Examples

	%let index = 3 5 2 100 4 1;
	%let list=a bb ccc dddd bb fffff;
	%let res=%list_index(&list, &index);
	
returns: `res=ccc bb bb dddd a` since the index 100 is ignored.
 
Run macro `%%_example_list_index` for more examples.

### Notes
1. Indexes larger than the length of the input list `list` are ignored, while whenever one index is <0,
and error is generated.
2. For wrongly typed indexes (_e.g._ non numeric index), an error is also generated.
3. In general case of error, the output `res` returned is empty (_i.e._ `res=`).

### See also
[%clist_index](@ref sas_clist_index), [%list_slice](@ref sas_list_slice), [%list_compare](@ref sas_list_compare), 
[%list_count](@ref sas_list_count), [%list_remove](@ref sas_list_remove), [%list_append](@ref sas_list_append),
[%INDEX](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a000543562.htm).
*/ /** \cond */

%macro list_index(list 	/* List of blank separated items 								(REQ) */
				, index	/* (List of) position(s) of elements to extract from the list 	(REQ) */
				, sep=	/* Character/string used as string separator in input list		(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(sep)  %then %let sep=%quote( ); /* list separator */

	%local _i 	/* increment counter */	
		_test  	/* list used for checking of index */
		_item  	/* scanned element from the input list */
		_len  	/* lenght of input list */
		_ind 	/* scanned index */
		_alist; /* output result */

	/* set default output to empty */
	%let _alist=;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(list) EQ 1 or %macro_isblank(index) EQ 1, mac=&_mac,		
			txt=!!! Input parameters LIST and INDEX need both to be set !!!) %then
		%goto exit;

	%let _len=%list_length(&list, sep=&sep);
	%let _nind=%list_length(&index, sep=%quote( )); /* note that we use a different separator ... */

	/* check that all indexes are correct */
	%let _test = %list_ones(&_nind, item=0);
	%if %error_handle(ErrorInputParameter, 
			%par_check(&index, type=INTEGER, range=0) NE &_test, mac=&_mac,		
			txt=!!! Wrong input INDEX value(s) %upcase(&index): must be INTEGER >0 !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* start the extraction */
	%do _i=1 %to &_nind;
		%let _ind=%scan(&index, &_i, %quote( ));
		%if %error_handle(WarningInputParameter, 
				&_ind GT &_len, 
				txt=! Index &_ind ignored: INDEX values must be <= &_len (length of the list) !!!, 
				verb=warn) %then 
			%goto next;
		%let _item=%scan(&list, &_ind, &sep);
		%if &_i=1 %then 	%let _alist=&_item;
		%else 				%let _alist=&_alist.&sep.&_item;
		%next:
	%end;

	%exit:
	&_alist

%mend list_index;

%macro _example_list_index;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local list index olist;

	%let list=aaa bbbb c dd aaa eeee;

	%let index=1 a;
	%put;
	%put (i) Test the program with dummy parameters: index=&index;
	%put %list_index(&list, &index);
	%if %macro_isblank(%list_index(&list, &index)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let index=1 -1;
	%put;
	%put (ii) Test the program with dummy parameters: index=&index;
	%if %macro_isblank(%list_index(&list, &index)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let index=4 2 1 2;
	%put;
	%put (iii) Extract all items in positions (&index);
	%let olist=dd bbbb aaa bbbb;
	%if %list_index(&list, &index)=&olist %then 	%put OK: TEST PASSED - List returned: "&olist";
	%else 											%put ERROR: TEST FAILED - Wrong list returned;

	%let index=5 3 2 4 8 3; /* one will be ignored */
	%put;
	%put (iv) Extract all items in positions (&index), where one index is > %list_length(&list);
	%let olist=aaa c bbbb dd c; 
	%if %list_index(&list, &index)=&olist %then 	%put OK: TEST PASSED - List returned: "&olist";
	%else 											%put ERROR: TEST FAILED - Wrong list returned;

	%put;
%mend _example_list_index;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_index; 
*/

/** \endcond */
