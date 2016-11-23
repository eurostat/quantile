/** 
## list_find {#sas_list_find}
Find all the occurrences of an element in a list and returns the indices of its position in that 
list.

	%let ind=%list_find(list, item, startind=1, startpos=1, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `item` : a string defining the pattern/element to look for in input `list`;
* `startind` : (_option_) specifies the index of the item in `list` at which the search should start; 
	incompatible with option `startind` above; default: `startind`, _i.e._ it is not considered;
* `startpos` : (_option_) specifies the position in `list` at which the search should start and the direction
	of the search (see argument of function `find`); default: `startpos=1`; incompatible with option
	`startind` above; default: `startpos`, _i.e._ it is not considered;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case pattern `match` will be searched/matched;
* `sep` : (_option_) character/string separator in input `list`; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`ind` : output list of indexes, _i.e._ the positions of the element `item` in the list if it is found,
	and empty variable (_i.e_, `ind=`) otherwise. 

### Examples
Let us consider a simple example:

	%let list=NL UK AT DE AT BE AT;
	%let ind=%list_find(&list, AT);

which returns `ind=3 5 7`, while: 	

	%let ind=%list_find(&list, AT, startind=4);

only returns `ind=5 7`.

Run macro `%%_example_list_find` for more examples.

### See also
[%list_index](@ref sas_list_index), [%list_slice](@ref sas_list_slice), [%list_count](@ref sas_list_count), 
[%list_remove](@ref sas_list_remove), [%list_length](@ref sas_list_length),
[FIND](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002267763.htm),
[FINDW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002978282.htm).
*/ /** \cond */

%macro list_find(list 			/* List of blank separated items 							(REQ) */
				, item 			/* Element whose positions in input list are retrieved		(REQ) */ 
				, startind=		/* Starting index 											(OPT) */
				, startpos=		/* Start position 											(OPT) */
				, casense=no	/* Boolean flag set for case sensitive comparison 			(OPT) */
				, sep=			/* Character/string used as string separator in input list	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%local _len	/* lenght of input list */
		_item 	/* scanned element from the input list */
		_ind 	/* output result */
		_inum 	/* value to add to the index after reducing the list through startpos or startind */
		_i; 	/* increment counter */		

	%if %macro_isblank(sep) %then 	%let sep=%quote( ); 

	/* set default output to empty */
	%let _ind=;
	%let _len=%list_length(&list, sep=&sep);

	/* check CASESENS parameter */
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&casense), type=CHAR, set=YES NO) NE 0,	
			txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;
	
	/* check STARTIND and STARTPOS parameters */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(startind) EQ 0 and %macro_isblank(startpos) EQ 0, mac=&_mac,
			txt=!!! Parameters STARTIND and STARTPOS are incompatible !!!) %then
		%goto exit;
	%if %macro_isblank(startind) %then 	%let startind=1;
	%if %macro_isblank(startpos) %then 	%let startpos=1;
	%if %error_handle(ErrorInputParameter, 
			%par_check(&startind, type=INTEGER, range=0 %eval(&_len+1)) NE 0,	
			txt=!!! Parameter STARTIND is strictly positive integer < &_len !!!) 
			or 
			%error_handle(ErrorInputParameter, 
				%par_check(&startpos, type=INTEGER, noset=0) NE 0,	
				txt=!!! Parameter STARTPOS is strictly non null integer !!!) %then
		%goto exit;
	%if %error_handle(ErrorInputParameter, 
			&startind>1 and &startpos>1,	
			txt=!!! Parameters STARTIND and STARTPOS cannot be used together !!!) %then
		%goto exit;

	/* test whether CASESENS is NO : upcase the strings to look for/to */
	%if %upcase("&casense")="NO" %then %do;
		%let list=%upcase(&list);
		%let item=%upcase(&item);
	%end;

	/* reduce the list */
	%if &startind>1 %then %do;
		/* reduce the list */
		%let list=%list_slice(&list, ibeg=&startind, sep=&sep);
		/* update the length of the list */
		%let _len=%list_length(&list, sep=&sep); 
		%let _inum=&startind;
	%end;
	%else %if &startpos>1 %then %do;
		%let list = %sysfunc(susbstr(&list, &startpos));
		%let _inum=%list_length(%sysfunc(susbstr(&list, 1, &startpos-1)), sep=&sep);
	%end;
	%else 
		%let _inum=1;

	%if %sysfunc(findw(&list, &item, 1)) <= 0 %then	
		%goto exit;

	%do _i=1 %to &_len;
		%let _item = %scan(&list, &_i, &sep);
		%if %quote(&_item)=%quote(&item) %then %do;
			%if %quote(&_ind)= %then 	%let _ind=%eval(&_i + &_inum - 1);
			%else						%let _ind=&_ind.&sep.%eval(&_i + &_inum - 1);
		%end;
	%end;

	%exit:
	&_ind
%mend list_find;


%macro _example_list_find;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let list=NL UK LT DE LT BE LT;
	%let item=DK;
	%put;
	%put (i) Test list=&list and item=&item ...;
	%let oind=;
	%if %macro_isblank(%list_find(&list, &item)) %then 	%put OK: TEST PASSED - Item &item not found in input list;
	%else 												%put ERROR: TEST FAILED - Item &item found;

	%let list=NL UK LT dk LT BE LT;
	%let item=DK;
	%put;
	%put (ii) Case insensitive (default: casense=no) test list=&list and item=&item ...;
	%let oind=4;
	%if %list_find(&list, &item)=%quote(&oind) %then 	%put OK: TEST PASSED - Item &item found in position: &oind;
	%else 												%put ERROR: TEST FAILED - Item &item found in wrong position;

	%let list=NL UK LT dk LT BE LT;
	%let item=DK;
	%put;
	%put (iii) Case sensitive (casense=yes) test list=&list and item=&item ...;
	%let oind=4;
	%if %macro_isblank(%list_find(&list, &item, casense=yes)) %then 
		%put OK: TEST PASSED - Item &item not found;
	%else 												
		%put ERROR: TEST FAILED - Item &item found;

	%let item=LT;
	%put;
	%put (iv) Test list=&list and item=&item ...;
	%let oind=3 5 7;
	%if %list_find(&list, &item)=%quote(&oind) %then 	%put OK: TEST PASSED - Item &item found in positions: &oind;
	%else 												%put ERROR: TEST FAILED - Wrong positions found;

	%put;
	%put (v) Further test the compatibility with the macro %nrstr(%list_count) ...;
	%let count=%list_length(&oind);
	%if %list_count(&list,&item)=&count %then 	%put OK: TEST PASSED - Item &item found &count times in list;
	%else 										%put ERROR: TEST FAILED - Item &item found &count times in list;

	%let item=LT;
	%let startind=4;
	%put;
	%put (vi) Test again list=&list and item=&item, with startind=&startind ...;
	%let oind=5 7;
	%if %list_find(&list, &item, startind=&startind)=%quote(&oind) %then 	
		%put OK: TEST PASSED - Item &item found in positions: &oind;
	%else 												
		%put ERROR: TEST FAILED - Wrong positions found;

	%put;
%mend _example_list_find;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_find; 
*/

/** \endcond */
