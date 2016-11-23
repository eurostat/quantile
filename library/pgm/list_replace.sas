/** 
## list_replace {#sas_list_replace}
Find and replace all the occurrences of (an) element(s) in a list.

	%let rlist=%list_replace(list, old, new, startind=1, startpos=1, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `old` : (list of) string(s) defining the pattern(s)/element(s) to replace for in the input list `list`;
* `new` : (list of) string(s) defining the replacement pattern(s)/element(s) in the output list `rlist`;
	this list must be of length 1 or same length as `old`;
* `startind` : (_option_) specifies the index of the item in `list` at which the search should start; 
	incompatible with option `startind` above; default: `startind`, _i.e._ it is not considered;
* `startpos` : (_option_) specifies the position in `list` at which the search should start; default: 
	`startpos=1`; incompatible with option `startind` above; default: `startpos`, _i.e._ it is not 
	considered;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ all lower- and upper-case occurrences of the pattern in `old` will be replaced;
* `sep` : (_option_) character/string separator in input `list`; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`rlist` : output list of indexes where all the elements of `old` present in `list` have been replaced by
	the corresponding elements in `new` (_i.e._ in the same position in both `old` and `new` lists). 

### Examples
Let us consider a simple example:

	%let list=NL UK AT DE AT BE AT;
	%let rlist=%list_replace(&list, AT DE, FR IT);

which returns `rlist=NL UK FR IT FR BE FR`. 	

Run macro `%%_example_list_replace` for more examples.

### Notes
1. Three configurations are accepted for the input lists `old` and `new` of lengths `n` and `m` 
respectively:
	 + `n=1` and `m>=1`: all the occurrences of the single item present in `old` will be replaced by the 
	 list `new`, or
	 + `m=1` and `n>=1`: items in list `old` will be all replaced by the single  item in `new`, or 
	 + `n=m`: the `i`th item of `old` will be replaced by the `i`th item of `new`; 
otherwise, when `n ^= m`, an error is reported. 
2. In practice, when you run a single change on a list, _e.g._ something like:

       %let rlist=%list_replace(&list, &old, &new);
with both `old` and `new` of same length, one should verify that for:

    %let olist=%list_ones(%list_count(&list, &old), item=&new);
	%let ind=%list_find(&list, &old);
the following equality holds: `%list_index(&rlist, &ind) = &olist`.  			

### See also
[%list_find](@ref sas_list_find), [%list_index](@ref sas_list_index), [%list_remove](@ref sas_list_remove), 
[%list_count](@ref sas_list_count), [%list_length](@ref sas_list_length),
[FIND](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002267763.htm).
*/ /** \cond */

%macro list_replace(list 			/* List of blank separated items 					(REQ) */
					, old 			/* (List of) element(s) to replace in input list 	(REQ) */ 
					, new 			/* Replacement (list of) element(s) in output list 	(REQ) */ 
					, startind=		/* Starting index 									(OPT) */
					, startpos=		/* Starting position								(OPT) */
					, casense=no	/* Boolean flag set for case sensitive comparison 	(OPT) */
					, sep=			/* Character/string used as list separator 			(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	%if %macro_isblank(sep)  %then %let sep=%quote( ); 

	%local _len	/* lenght of input list */
		_lold	/* lenght of old list */
		_lnew	/* lenght of replacement list */
		_item 	/* scanned element from the input list */
		_oldit	/* scanned element from the old list */
		_newit	/* scanned element from the new list */
		_uitem 	/* scanned element from the input upcase list */
		_rlist 	/* output result */
		blist	/* substring corresponding to the beginning of input list */
		_i _k;	/* increment counters */		

	/* set default output to empty */
	%let _rlist=;

	/* check OLD and NEW parameters */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(old) or %macro_isblank(new), mac=&_mac,
			txt=!!! Parameters OLD and NEW must be passed !!!) %then
		%goto exit;

	/* special _EMPTY_ case
	%if &old=_EMPTY_ %then %let old=%quote(); */

	/* set the length of the input and old lists */
	%let _len=%list_length(&list);
	%let _lold=%list_length(&old);
	%let _lnew=%list_length(&new);

	/* set/reset OLD and NEW parameters */
	%if &_lold=1 and &_lnew>1	%then %do;
	%end;
	%else %if &_lold>1 and &_lnew=1	%then %do;
		/* duplicate the element in new _lold times */
		%let new=%list_ones(&_lold, item=&new, sep=&sep);
		/* update the length of the new list */
		%let _lnew=%list_length(&new);
	%end;
	%else %if %error_handle(ErrorInputParameter, 
			%list_length(&new) NE &_lold, mac=&_mac,
			txt=!!! Parameters OLD and NEW must be the same length !!!) %then
		%goto exit;

	/* check some possible duplication in the input OLD list */
	%do _k=1 %to &_lold;
		%let _oldit = %scan(&old, &_k, &sep);
		%if %error_handle(ErrorInputParameter, 
				%list_count(&old, item=&_oldit) GT 1, mac=&_mac,	
				txt=%quote(!!! Duplicated item %upcase(&_oldit) in OLD list !!!)) %then
			%goto exit;
	%end;

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

	/* check whether CASESENS was set */
	%if %upcase("&casense")="NO" %then %do;
		%let old=%upcase(&old);
		%let _list=%upcase(&list);
	%end;
	%else
		%let _list=&list;

	/* check whether STARTIND and STARTPOS were set */
	%if &startind>1 %then %do;
		%let _list = %list_slice(&_list, ibeg=&startind);
		%let blist = %list_slice(&_list, iend=&startind);
	%end;
	%else %if &startpos>1 %then %do;
		%let _list = %sysfunc(susbstr(&_list, &startpos));
		%let blist = %sysfunc(susbstr(&_list, 1, &startpos-1));
	%end;
	%else
		%let blist=;

	%let _len=%list_length(&_list);

	%do _i=1 %to &_len;
		%let _item = %scan(&_list, &_i, &sep);
		%if %sysfunc(findw(&old, &_item)) <= 0 %then	
			%goto break;
		%do _k=1 %to &_lold;
			%let _oldit = %scan(&old, &_k, &sep);
			%if %quote(&_item)=%quote(&_oldit) %then %do;
				%if &_lold=1 %then 		%let _newit = &new;
				%else 					%let _newit = %scan(&new, &_k, &sep);
				%if %quote(&_rlist)= %then 		%let _rlist=&_newit;
				%else							%let _rlist=&_rlist.&sep.&_newit;
				%goto next;
			%end;
		%end;
		%break:
		%if %quote(&_rlist)= %then 		%let _rlist=&_item;
		%else							%let _rlist=&_rlist.&sep.&_item;
		%next:
	%end;

	%if &startind>1 or &startpos>1 %then %do;
		%let _rlist = %list_append(&blist, &_rlist);
	%end;

	%exit:
	&_rlist
%mend list_replace;


%macro _example_list_replace;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let list=NL UK LT DE LT BE LT;
	%let old=DK UK LT;
	%let new=DK IT;
	%put;
	%put (i) Dummy test on list=&list with old=&old and new=&new ...;
	%let oind=;
	%if %macro_isblank(%list_replace(&list, &old, &new)) %then 	
		%put OK: TEST PASSED - Dummy parameterisation passed;
	%else 												
		%put ERROR: TEST FAILED - Dummy parameterisation not identified;

	%let old=EL;
	%let new=IT;
	%put;
	%put (ii) Dummy test on list=&list with old=&old and new=&new ...;
	%let res=%list_replace(&list, &old, &new);
	%if %quote(&res)=%quote(&list) %then 	%put OK: TEST PASSED - No replacement performed;
	%else 									%put ERROR: TEST FAILED - Wrong replacement performed;

	%let old=LT;
	%put;
	%put (iii) Replacement test list=&list with old=&old and new=&new ...;
	%let ores=%list_ones(%list_count(&list, &old), item=&new);
	%let res=%list_replace(&list, &old, &new);
	%let olist=NL UK IT DE IT BE IT;
	%if %quote(&res)=%quote(&olist) and %quote(%list_index(&res, %list_find(&list, &old)))=%quote(&ores) %then 			
		%put OK: TEST PASSED - Item &old correctly replaced by &new in input list: &res;
	%else 															
		%put ERROR: TEST FAILED - Item &old wrongly replaced by &new in input list: &res;

	%let old=DE BE;
	%let new=BE DE;
	%put;
	%put (iv) Test list=&list with old=&old and new=&new ...;
	%let olist=NL UK LT BE LT DE LT;
	%let res=%list_replace(&list, &old, &new);
	%if %quote(&res)=%quote(&olist) %then 	
		%put OK: TEST PASSED - Item &old correctly replaced by &new in input list: &res;
	%else 					
		%put ERROR: TEST FAILED - Item &old wrongly replaced by &new in input list: &res;

	%let old=DE;
	%let new=DE1 DE2 DE3 DE4;
	%put;
	%put (v) Test list=&list with old=&old and new=&new ...;
	%let olist=NL UK LT DE1 DE2 DE3 DE4 LT BE LT;
	%let res=%list_replace(&list, &old, &new);
	%if %quote(&res)=%quote(&olist) %then 	
		%put OK: TEST PASSED - Item &old correctly replaced by &new in input list: &res;
	%else 					
		%put ERROR: TEST FAILED - Item &old wrongly replaced by &new in input list: &res;

	%let list=NL UK LT dk LT BE LT;
	%let old=DK lt;
	%let new=it FR;
	%put;
	%put (vi) Case sensitive (default: casense=no) test list=&list with old=&old and new=&new ...;
	%let olist=NL UK FR it FR BE FR;
	%let res=%list_replace(&list, &old, &new);
	%if %quote(&res)=%quote(&olist) %then 	
		%put OK: TEST PASSED - Item &old correctly replaced by &new in input list: &res;
	%else 					
		%put ERROR: TEST FAILED - Item &old wrongly replaced by &new in input list: &res;

	%put;
%mend _example_list_replace;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_replace; 
*/

/** \endcond */
