/** 
## list_count {#sas_list_count}
Count the number of occurences of an element in a (blank separated) list. 

	%let count=%list_count(list, item, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `item` : a string defining the pattern to count for the occurrence of appearance in input `list`;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case pattern `item` will be searched/matched;
* `sep` : (_option_) character/string separator in input `list`; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`count` : output count number, _i.e._ the number of times the element `item` appears in the list; note 
	that when the element `item` is not found in the input list, it returns `count=0` as expected.

### Examples
Let us consider a simple example:

	%let list=NL UK AT DE AT BE AT;
	%let count=%list_count(&list, AT);

which returns `count=3`. 	

Run macro `%%_example_list_count` for more examples.

### See also
[%list_slice](@ref sas_list_slice), [%list_find](@ref sas_list_find), [%list_remove](@ref sas_list_remove), 
[%list_length](@ref sas_list_length).
*/ /** \cond */

%macro list_count(list 			/* List of blank separated items 								(REQ) */
				, item 			/* Element to count the occurrence of appearance in input list 	(REQ) */ 
				, casense=no	/* Boolean flag set for case sensitive comparison 				(OPT) */
				, sep=			/* Character/string used as string separator in input list		(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%local _len	/* lenght of input list */
		_item 	/* scanned item */
		_count 	/* output result */
		_i; 	/* increment counter */		

	/* set default output to empty */
	%let _count=;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(item) EQ 1, mac=&_mac,	
			txt=!!! Parameter ITEM must be passed !!!)
			or
			%error_handle(ErrorInputParameter, 
				%par_check(%upcase(&casense), type=CHAR, set=YES NO) NE 0, mac=&_mac,	
				txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit; /* return a blank result/error */
		
	%if %macro_isblank(sep)  %then %let sep=%quote( ); 

	/* deal with case insentiveness */
	%if %upcase("&casense")="NO" %then %do;
		%let list=%upcase(&list);
		%let item=%upcase(&item);
	%end;
	
	/* run the enumeration/counting */
	%let _count=0;
	%let _len=%list_length(&list, sep=&sep); 
	%do _i=1 %to &_len;
		%let _item = %scan(&list, &_i, &sep);
		%if %quote(&_item)=%quote(&item) %then  	%let _count=%eval(&_count+1);
	%end;

	%exit:
	&_count
%mend list_count;


%macro _example_list_count;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let list=NL UK AT DE AT BE AT;

	%let item=TOTO;
	%put;
	%put (o) Crash test ...;
	%if %macro_isblank(%list_count(&list, &item, casense=MUF)) %then 	%put OK: TEST PASSED - Test fails;
	%else 																%put ERROR: TEST FAILED - Test passes;

	%let item=TOTO;
	%put;
	%put (i) Test list=&list and item=&item ...;
	%if %list_count(&list, &item)=0 %then 	%put OK: TEST PASSED - Item &item not found (counted 0 time);
	%else 									%put ERROR: TEST FAILED - Wrong item found ;

	%let item=AT;
	%put;
	%put (ii) Test list=&list and item=&item ...;
	%if %list_count(&list, &item)=3 %then 	%put OK: TEST PASSED - Item &item counted: 3 times;
	%else 									%put ERROR: TEST FAILED - Wrong item counting;

	%let item=at;
	%put;
	%put (iii) Case sensitive test (casense=yes) list=&list and item=&item ...;
	%put %list_count(&list, &item, casense=yes);
	%if %list_count(&list, &item, casense=yes)=0 %then 	
		%put OK: TEST PASSED - Item &item not found (counted 0 time);
	%else 													
		%put ERROR: TEST FAILED - Wrong item counting;

	%let item=at;
	%put;
	%put (iv) Case sensitive test (default casense=no) list=&list and item=&item ...;
	%if %list_count(&list, &item)=3 %then 	
		%put OK: TEST PASSED - Item &item counted: 3 times;
	%else 													
		%put ERROR: TEST FAILED - Wrong item counting;

	%let list=1995_2000_2000_1998_1997_2000_2000;
	%let item=2000;
	%let sep=_;
	%put;
	%put (v) Test list=&list and item=&item, sep=&sep ...;
	%if %list_count(&list, &item, sep=&sep)=4 %then 	%put OK: TEST PASSED - Item &item counted: 4 times;
	%else 												%put ERROR: TEST FAILED - Wrong item counting;

	%put;
%mend _example_list_count;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_count; 
*/

/** \endcond */
