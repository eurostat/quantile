/**
## list_slice {#sas_list_slice}
Slice a given list, _i.e._ extract a sequence of items from the beginning and/or ending positions and/or 
matching items.

	%let res=%list_slice(list, beg=, ibeg=, end=, iend=, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `beg` : (_option_) item to look for in the input list; the slicing will 'begin' from the
	first occurrence of `beg`; if not found, an empty list is returned;
* `end` : (_option_) ibid, the slicing will 'end' at the first occurrence of `end`; if not found, 
	the slicing is done till the last item;
* `ibeg` : (_option_) position of the first item to look for in the input list; must be a numeric
	value >0; if the value is > length of the input list, an empty list is returned; incompatible
	with `beg` option (see above); if neither `beg` nor `ibeg` is passed, `ibeg` is set to 1; 
* `iend` : (_option_) ibid, position of the last item; must be a numeric value >0; in the case 
	`iend<iend`, an empty list is returned; in the case, `iend=ibeg` then the item `beg` (in position 
	`ibeg`) is returned; incompatible with `end` option (see above); if neither `end` nor `iend` is 
	passed, `iend` is set to the length of `list`;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`res` : output list defined as the sequence of items extract from the input list `list` from the 
	`ibeg`-th position or the first occurrence of `beg`, till the `iend`-th position or the first 
	occurrence of `end` (after the `ibeg`-th position).

### Examples

	%let list=a bb ccc dddd bb fffff;
	%let res=%list_slice(&list, beg=bb, iend=4);
	
returns: `res=bb ccc`, while
 
	%let res=%list_slice(&list, beg=ccc);
	%let res2=%list_slice(&list, ibeg=bb, end=bb);
	%let res3=%list_slice(&list, beg=ccc, iend=3);
	
return respectively: `res=bb ccc dddd bb fffff`, `res2=bb ccc dddd` and `res3=ccc`.

Run macro `%%_example_list_slice` for more examples.

### Note
1. The first occurrence of `end` is necessarily searched for in `list` after the `ibeg`-th position 
(or first occurrence of `beg`).
2. The item at position `iend` (or first occurrence of `end`) is not inserted in the output `res` list.

### See also
[%list_index](@ref sas_list_index), [%list_compare](@ref sas_list_compare), [%list_count](@ref sas_list_count), 
[%list_remove](@ref sas_list_remove),  [%list_append](@ref sas_list_append).
*/ /** \cond */

%macro list_slice(list 	/* list  blank-separated items 						(REQ) */
				, beg=  /* First item to look for in the list 				(OPT) */
				, ibeg= /* Index of the first item to look for in the list 	(OPT) */
				, end=  /* Last item to look for in the list 				(OPT) */
				, iend= /* Index of the last item to look for in the list 	(OPT) */
				, sep=	/* Character/string used as list separator 			(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%local _i 	/* increment counter */
		_len	/* lenght of input list */
		_item 	/* scanned element from the input list */
		_alist; /* output result */

	/* set default output to empty */
	%let _alist=;

	/* check the consitency of the arguments passed */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(beg) EQ 0 and %macro_isblank(ibeg) EQ 0, mac=&_mac,		
			txt=!!! Input parameters BEG and IBEG are incompatible !!!) 
		or
		%error_handle(ErrorInputParameter, 
			%macro_isblank(end) EQ 0 and %macro_isblank(iend) EQ 0, mac=&_mac,		
			txt=!!! Input parameters END and IEND are incompatible !!!) %then
		%goto exit;

	/* check the types of the ibeg and iend variables */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(ibeg) EQ 0 and %datatyp(&ibeg) NE NUMERIC, mac=&_mac,		
			txt=!!! Input parameter IBEG must be of NUMERIC type !!!) 
		or
		%error_handle(ErrorInputParameter, 
			%macro_isblank(iend) EQ 0 and %datatyp(&iend) NE NUMERIC, mac=&_mac,		
			txt=!!! Input parameter IEND must be of NUMERIC type !!!) %then
		%goto exit;

	%if %macro_isblank(sep)  %then %let sep=%quote( ); /* list separator */

	%let _len=%list_length(&list, sep=&sep);

	/* set the default indexes where to start/finish the extraction */
	%if %macro_isblank(ibeg) and %macro_isblank(beg) %then	
		%let ibeg=1; 
	%if %macro_isblank(iend) and %macro_isblank(end) %then	
		%let iend=%eval(&_len+1); /* +1 since by default we also include the last item of the list */

	%if not (%macro_isblank(iend) or %macro_isblank(ibeg)) %then %do;
		%if %error_handle(ErrorInputParameter, 
				&iend <&ibeg, mac=&_mac, 
				txt=!!! Wrong index setting: IEND must be > IBEG !!!) %then 
			%goto exit;	
	%end;

	/* actually start the extraction */
	%do _i=1 %to &_len;
		%let _item=%scan(&list, &_i, &sep);
		%if %macro_isblank(beg) and &_i=&ibeg %then	%do;
			%let beg=&_item;
			%goto append;
		%end;
		%else %if %macro_isblank(ibeg) %then %do;
			%if &_item=&beg %then	%let ibeg=&_i;
			%else 					%goto continue; /* not set = not found yet */
		%end;
		%else %if %macro_isblank(iend) and &_item=&end %then %do; 
			%let iend=&_i;
			%goto break;
		%end;
		%if not %macro_isblank(ibeg) and &_i<&ibeg %then 	
			%goto continue;
		%else %if not %macro_isblank(ibeg) and &_i=&ibeg %then 	
			%goto append; /* we in fact deal here with the case iend=ibeg */
		%else %if not %macro_isblank(iend) and &_i>=&iend %then 	
			%goto break;
		/* actually append the item to the list */
		%append:
		%if &_alist= %then 		%let _alist=&_item;
		%else					%let _alist=&_alist.&sep.&_item;
		/* continue to next iteration in the loop */
		%continue:
	%end;

	/* break (from the previous loop) */
	%break:

	/* further consistency checks */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(ibeg) EQ 1 or &ibeg <=0, mac=&_mac, 
			txt=!!! Wrong index setting - OR - Item %upcase(&beg) not found in list !!!) 
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(iend) EQ 1 or &iend <=0, mac=&_mac, 
				txt=!!! Item %upcase(&end) not found in list !!!) /* note: one type of error only (iend>_len is accepted) */
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(iend) EQ 0 and %macro_isblank(ibeg) EQ 0 and &iend < &ibeg, mac=&_mac, 
				txt=!!! Index IEND must be > IBEG !!!) %then %do;
		%let _alist=;
		%goto exit;
	%end;

	%*let _alist=%sysfunc(trim(&_alist));

	%exit:
	&_alist

%mend list_slice;

%macro _example_list_slice;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local list beg ibeg end iend olist;

	%let list=aaa bbbb c dd aaa eeee;

	%let ibeg=a;
	%put;
	%put (i) Test the program with dummy parameters: ibeg=&ibeg;
	%if %macro_isblank(%list_slice(&list, ibeg=&ibeg)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let ibeg=-1;
	%put;
	%put (ii) Test the program with dummy parameters: ibeg=&ibeg;
	%if %macro_isblank(%list_slice(&list, ibeg=&ibeg)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let ibeg=5;
	%let iend=2;
	%put;
	%put (iii) Test the program with dummy parameters: ibeg=&ibeg and iend=&iend;
	%if %macro_isblank(%list_slice(&list, ibeg=&ibeg, iend=&iend)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let beg=a;
	%put;
	%put (iv) Test the program with dummy parameters: beg=&beg (item not in the list);
	%if %macro_isblank(%list_slice(&list, beg=&beg)) %then 	
		%put OK: TEST PASSED - Dummy test returns empty result;
	%else 															
		%put ERROR: TEST FAILED - Output list returned for dummy test;

	%let beg=bbbb;
	%put;
	%put (v) Extract all items from the first occurrence of "&beg" till the end (iend/end not set);
	%let olist=bbbb c dd aaa eeee;
	%if %list_slice(&list, beg=&beg)=&olist %then 	%put OK: TEST PASSED - List returned: "&olist";
	%else 												%put ERROR: TEST FAILED - Wrong list returned;
	
	%let ibeg=3;
	%let end=dd;
	%put;
	%put (vi) Extract all items from the &ibeg.rd position till the first occurrence of "&end";
	%let olist=c;
	%if %list_slice(&list, ibeg=&ibeg, end=&end)=&olist %then 	%put OK: TEST PASSED - List returned: "&olist";
	%else 															%put ERROR: TEST FAILED - Wrong list returned;
	
	%let beg=bbbb;
	%let iend=2;
	%put;
	%put (vii) Extract all items from the first occurrence of "&beg" till the &iend.nd position;
	%let olist=bbbb; 
	%if %list_slice(&list, beg=&beg, iend=&iend)=&olist %then 	%put OK: TEST PASSED - List returned: "&olist";
	%else 															%put ERROR: TEST FAILED - Wrong list returned;
	
	%let ibeg=2;
	%let end=c;
	%put;
	%put (viii) Extract all items from the &ibeg.nd position till the first occurrence of "&end";
	%let olist=bbbb; /* same as case (vii) */
	%if %list_slice(&list, ibeg=&ibeg, end=&end)=&olist %then 	%put OK: TEST PASSED - List returned: "&olist";
	%else 															%put ERROR: TEST FAILED - Wrong list returned;
	
	%let ibeg=1;
	%let end=aaa;
	%put;
	%put (ix) Extract all items from the &ibeg.rst position till the first occurrence of "&end";
	%let olist=aaa bbbb c dd; /* the first occurrence of aaa is searched for after the 1st position */
	%if %list_slice(&list, ibeg=&ibeg, end=&end)=&olist %then 	%put OK: TEST PASSED - List returned: "&olist";
	%else 															%put ERROR: TEST FAILED - Wrong list returned;

	%put;
%mend _example_list_slice;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_slice; 
*/

/** \endcond */
