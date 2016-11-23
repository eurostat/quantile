/** 
## list_intersection {#sas_list_intersection}
Calculate the intersection (list of common items) between two unformatted lists of char.

	%let isec=%list_intersection(list1, list2, casense=no, unique=yes, sep=%quote( ));

### Arguments
* `list1, list2` : two lists of unformatted strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive comparison/matching; 
	default: `casense=no`, _i.e._ upper-case "intersection" items in both lists are matched;
* `unique` : (_option_) boolean flag (`yes/no`) set in combination with `casense=no` so as to return 
	unique values from the input lists, independently of the case; in practice when `unique=no`, when
	two items present in the input lists with distinct (lower- and upper-) cases match through their 
	upper-case versions (_i.e._, `casense=no`), both will be kept in the intersection list; default: 
	`unique=yes`;
* `sep` : (_option_) character/string used as a separator in the input lists; default: `sep=%%quote( )`, 
	_i.e._ the input `list1` and `list2` are both blank-separated lists of items.
 
### Returns
`isec` : output list of strings, namely the list of items obtained as the intersection `list1 /\ list2`, 
	_i.e._ items common to both lists are preserved.

### Examples
We first show some simple examples of use: 

	%let list1=A B C D E F A;
	%let list2=C A B Z A;
	%let isec1=%list_intersection(&list1, &list2);
	
returns: `isec1=A B C`, while:

	%let isec2=%list_intersection(&list2, &list1);
	
returns a different: `isec2=C A B`.	Then, also note the use of case sensitiveness:
 
	%let list1=a B C D e F A;
	%let list2=C A b Z A;
	%let isec1=%list_intersection(&list1, &list2, casense=yes);
	
returns: `isec1=C A`. As for the use of the flag `unique`, note that: 

	%let isec2=%list_intersection(&list1, &list2);
	%let isec3=%list_intersection(&list1, &list2, unique=no);
	
return: `isec2=a B C` and `isec3=a B C A b` respectively, while:

	%let isec4=%list_intersection(&list2, &list1);
	%let isec5=%list_intersection(&list2, &list1, unique=no);
	
return: `isec4=C A b` and `isec5=C A b a B` respectively.

Run macro `%%_example_list_difference` for more examples.

### Notes
1. As shown in the first example above, the order the lists are passed to the macro matters. Namely, the  
items, that are common to both lists `list1` and `list2`, will be ordered in `isec` according to their
order of appearance in the first list `list1`. For that reason, `isec1` and `isec2` above differ; still, 
it can be checked that:

    %let res=%list_compare(&isec1,&isec2);
will return `res=0`, hence the sets supported by `isec1` and `isec2` are identical. Similarly, in the last
example above:

    %let res=%list_compare(&isec2,&isec4);
will return `res=0` as well (only the order of the elements in the intersection lists differs).
2. Items present multiple times in input lists `list1` and `list2` are reported only once in the output
intersection `isec`. For that reason, the item `A` in the first example above appears only once in `isec1` 
and `isec2`. Items present multiple times with both lower- and upper-cases in the input lists will be 
reported only once in the output list iif `unique=yes` and `casense=yes`.
3. The parameter `unique` is ignored when `casense=no`. 

### See also
[%list_difference](@ref sas_list_difference), [%list_compare](@ref sas_list_compare), [%list_append](@ref sas_list_append), 
[%list_find](@ref sas_list_find), [%list_unique](@ref sas_list_unique),
[FINDW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002978282.htm).
*/ /** \cond */

%macro list_intersection(list1, list2	/* Lists of blank-separated items 					(REQ) */
						, casense=no	/* Boolean flag set for case sensitive comparison 	(OPT) */
						, unique=yes	/* Boolean flag set for unique elements 			(OPT) */
						, sep=			/* character/string used as list separator 			(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _isec 	/* output result */
		_nloop;	/* counting number of operations */
	/* set default output to empty */
	%let _isec=;
	%let _nloop=0;

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&casense), type=CHAR, set=YES NO) NE 0,	
			txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

	/* default setting */
	%if %macro_isblank(sep) %then 	%let sep=%quote( );  /* list separator */

	/* deal with simple cases */
	%if %macro_isblank(list1) or %macro_isblank(list2) %then 
		%goto exit;
	%else %if %list_compare(&list1, &list2, sep=&sep, casense=&casense)=0 %then %do;
		%let _isec=%list_unique(%list_append(&list1, &list2, sep=&sep), casense=yes);
		%goto exit;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i 	/* increment counter */	
		_list2	/* temporary copy of list2, possibly upcase */
		_item	/* scanned element from the input list */
		_uitem;  	/* scanned element from the temporary list _list2 */

	/* check if casense were set */
	%if %upcase("&casense")="NO" %then 		%let _list2=%upcase(&list2);
	%else									%let _list2=&list2;

	/* calculate the actual intersection, i.e. the set of items of list1
	 * which are also present in list2 */
	%loop_intersection:
	%let _nloop=%eval(&_nloop+1); /* incrememt: we will will stop at 2 anyway ... */
	%do _i=1 %to %list_length(&list1, sep=&sep);
		/* we test whether the items in list1 are present in list2 */ 
		%let _item=%scan(&list1, &_i, &sep);
		%if %upcase("&casense")="NO" %then	
			/* because we are not case sensitive, we will test an upper case version
			* of _item */	
			%let _uitem=%upcase(&_item); 
		%else									
			/* otherwise, we test _item iteself */	
			%let _uitem=&_item;
		/* the test is operated against _list2 which is possibly upper case itself */
		%if %sysfunc(findw(&_list2, &_uitem))>0 %then %do;
			%if %macro_isblank(_isec) %then 
				/* initialise _isec */	
				%let _isec=&_item;
			%else %if %sysfunc(findw(&_isec, &_item))<=0 %then %do;
				%if %upcase("&unique")="NO" or %sysfunc(findw(&_isec, &_uitem))<=0 %then
					/* avoid repetition by inserting _item iif it is not already in _isec */	
					%let _isec=&_isec.&sep.&_item;
			%end;
			/* %else : do nothing */
		%end;
	%end;

	/* we will exchange the roles of list1 and list2 in the loop above */
	%if %upcase("&unique")="NO" and %upcase("&casense")="NO" and &_nloop<2 %then %do;
		/* exchange the roles of list1 and list2 */
		%let _list2=%upcase(&list1);
		%let list1=&list2;
		%goto loop_intersection;
	%end;

	%exit:
	&_isec
%mend list_intersection;

%macro _example_list_intersection;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local list1 list2 olist olist2;

	%let list1=BE DE NL AT UK NL SE;
	%let list2 =;
	%put;
	%put (i) Test the intersection "list1 /\ list2" with an empty list list2 ...;
	%if %macro_isblank(%list_intersection(&list1, &list2)) 	%then 	
		%put OK: TEST PASSED - Intersection with empty list: empty list returned;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection: non-empty list returned;

	%let list2=AT BE NL NL;
	%put;
	%put (ii) Test the intersection "list1 /\ list2" with list1=&list1 and list2=&list2 ...;
	%let olist=BE NL AT; 
	%put %list_intersection(&list1, &list2);
	%if %list_intersection(&list1, &list2) EQ &olist %then 	
		%put OK: TEST PASSED - "list1 /\ list2" returns: &olist (ordered like in list1);
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%put;
	%put (iii) Ibid, test the intersection "list2 /\ list1" with the same lists ...;
	%let olist=AT BE NL;
	%if %list_intersection(&list2, &list1) EQ &olist %then 	
		%put OK: TEST PASSED - "list2 /\ list1" returns: &olist (ordered like in list2);
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list2 /\ list1" returned;

	%let list2=FR IT AT BE NL RO MT; 
	%put;
	%put (iv) Test the intersection "list1 /\ list2" where list1=&list1 and list2=&list2 ...;
	%let olist=BE NL AT;
	%if %list_intersection(&list1, &list2) EQ &olist %then 	
		%put OK: TEST PASSED - "list1 /\ list2" returns: &olist;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%let list1=AT BE NL NL;
	%let list2=%lowcase(&list1);
	%put;
	%put (v) Test the intersection "list1 /\ list2" where list1=&list1 and list2=&list2 and casense=yes ...;
	%if %macro_isblank(%list_intersection(&list1, &list2, casense=yes)) %then 	
		%put OK: TEST PASSED - "list2 /\ list1" returns: empty list;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%put;
	%put (vi) Ibid, test the intersection "list1 /\ list2" with default casense=no and unique=yes ...;
	%let olist=AT BE NL;
	%if %list_intersection(&list1, &list2) EQ &olist %then 	
		%put OK: TEST PASSED - "list2 /\ list1" returns: &olist;

	%put;
	%put (vii) Ibid, with unique=no this time...;
	%let olist=AT BE NL at be nl;
	%if %list_intersection(&list1, &list2, unique=no) EQ &olist %then 	
		%put OK: TEST PASSED - "list2 /\ list1" returns: &olist;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%let list1=BE DE NL at UK nl NL SE;
	%let list2=fr IT AT be NL RO se MT; 
	%put;
	%put (viii) Test the intersection "list1 /\ list2" where list1=&list1 and list2=&list2 with default casense=no and unique=yes...;
	%let olist=BE NL at SE; 
	%if %list_intersection(&list1, &list2) EQ &olist %then 	
		%put OK: TEST PASSED - "list1 /\ list2" returns: &olist;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%put;
	%put (ix) Ibid, with unique=no this time...;
	%let olist=BE NL at nl SE AT be se; 
	%if %list_intersection(&list1, &list2, unique=no) EQ &olist %then 	
		%put OK: TEST PASSED - "list1 /\ list2" returns: &olist;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%put;
	%put (x) Ibid, with casense=yes this time ...;
	%let olist=NL;
	%if %list_intersection(&list1, &list2, casense=yes) EQ &olist %then 	
		%put OK: TEST PASSED - "list1 /\ list2" returns: &olist;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%let list1=AT BE NL;
	%let list2=BE AT NL;
	%put;
	%put (xi) Test the intersection "list1 /\ list2" with "identical" list1=&list1 and list2=&list2 ...;
	%if %list_intersection(&list1, &list2) EQ &list1 %then 	
		%put OK: TEST PASSED - "list1 /\ list2" returns: &list1;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%put;
	%put (xii) Check the intersection "list2 /\ list1" with the same lists ...;
	%if %list_intersection(&list2, &list1) EQ &list2 %then 	
		%put OK: TEST PASSED - "list2 /\ list1" returns: &list2;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list2 /\ list1" returned;

	%let list1=AT BE NL;
	%let list2=B E A T N L;
	%put;
	%put (xiii) Check that is does not work with substrings: "list1 /\ list2" with list1=&list1 and list2=&list2 ...;
	%if %macro_isblank(%list_intersection(&list1, &list2)) %then 	
		%put OK: TEST PASSED - "list1 /\ list2" returns empty list;
	%else 																
		%put ERROR: TEST FAILED - Wrong intersection "list1 /\ list2" returned;

	%put;
%mend _example_list_intersection;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_intersection; 
*/

/** \endcond */

