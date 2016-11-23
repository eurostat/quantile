/** 
## str_to_keyvalue {#sas_str_to_keyvalue}
Retrieve and discard the (key,value) pairs present in a given string/list.

	%str_to_keyvalue(str, key=, value=, _key_, _value_=, _item_=, _str_=, op=%quote(=), sep=%quote( ));

### Arguments
* `str` : strings of items that may be defined as `(key,value)` pairs of the form `A&opB` where
	`op` is defined below; 
* `key` : (_option_) string(s) defining the keys to look for in the input string; a key is defined
	as the left-hand side of the `(key,value)` pair `A&opB`, _i.e._ `A`; when passed, only those
	`(key,value)` pairs associated to keys in `key` are retrieved; when not passed (_i.e._ left
	blank), the macro retrieves all possible keys present in the input string;
* `value` : (_option_) string(s) defining the values to look for in the input string; a value is
	defined as the right-hand side of the `(key,value)` pair `A&opB`, _i.e._ `B`; when passed, the
	values retrieved from the input string are matched against those in `value`; by default, `value`
	is not considered;
* `op` : (_option_) separator character of `(key,value)` pairs in input string `str`; default:
	`op=%quote(=)`;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` is 
	blank.

### Returns
* `_key_` : (_option_) name of the variable storing the (list of) key(s) found in `(key,value)` pairs 
	present of `str` and that match the criteria on `key` and `value` parameters above;
* `_value_` : (_option_) ibid with value(s); 
* `_item_` : (_option_) name of the variable storing the `(key,value)` zipped pairs that match the 
	criteria on `key` and `value` parameters above; 
* `_str_` : (_option_) updated string from which all `(key,value)` pairs that macth the criteria
	on `key` and `value` parameters are discarded.

### Examples
Let us consider the following simple examples:

	%let str=A, B, K=C, D;
	%let ovalue=;
	%let ostr=;
	%let oitem=;
	%str_to_keyvalue(%quote(&str), key=K, _value_=ovalue, _str_=ostr, _item_=oitem, sep=%quote(,));

which sets: `ovalue=C`, `item=K=C` and `ostr=A,B,D`. Let us also consider the following case:

	%let str=A, B, K1=C, D, K2=E, K3=, F, K4=G;
	%let okey=;
	%let ovalue=;
	%let ostr=;
	%let oitem=;
	%str_to_keyvalue(%quote(&str), value=C F G, _value_=ovalue, _key_=okey, _str_=ostr, _item_=oitem, sep=%quote(,));

sets: `ovalue=C G`, `okey=K1 K4`, `item=K1=C,K4=G` and `ostr=A,B,D,K2=E,K3=,F`, while

	%str_to_keyvalue(%quote(&str), _value_=ovalue, _key_=okey, _str_=ostr, _item_=oitem, sep=%quote(,));

sets: `ovalue=C E _EMPTY_ G`, `okey=K1 K2 K3 K4`, `item=K1=C,K2=E,K3=,K4=G` and `ostr=A,B,D,F`.

Run macro `%%_example_str_to_keyvalue` for more examples.

### Notes
1. This macro assumes that the `(key,value)` pairs in the input string parameter `str` are unique!
2. Zipped `(key,value)` pairs returned through `_item_` are built using 
[%list_append](@ref sas_list_append).
3. Output updated lists are (blank) compressed.

### See also
[%list_append](@ref sas_list_append).
*/ /** \cond */

%macro str_to_keyvalue(list
					, key=
					, value=
					, _key_=
					, _value_=
					, _item_=
					, _str_=
					, op=
					, sep=
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_key_) EQ 1 and %macro_isblank(_value_) EQ 1 
			and %macro_isblank(_item_) EQ 1 and %macro_isblank(_str_) EQ 1, mac=&_mac,		
			txt=%bquote(!!! At least one of the output parameters _KEY_, _VALUE_, _ITEM_ or _STR_ must be set !!!)) %then 
		%goto exit;

	%local _okey
		_ovalue
		_oitem
		_olist;
	/* initialise outputs */
	%let _olist=&list;
	%let _okey=;
	%let _ovalue=;
	%let _oitem=;

	%if %macro_isblank(op) %then 		%let op=%quote(=);
	%if %error_handle(WarningInputParameter, 
			%sysfunc(find(%quote(&_olist), &op)) LE 0, mac=&_mac,		
			txt=! No (KEY&op.VALUE) pair found in input list !, verb=warn) %then 
		%goto quit; /* in case _STR_ is passed for example, then the original list is still returned */

	%local _ik
		_itest
		_ikey
		_value
		_tmplist
		_tmp
		lenkey
		lenval
		lenop
		lensep
		REP;
	%let REP=%quote( );
	%let lenop=%length(&op);
	%let lensep=%length(&sep);

	%if %macro_isblank(sep) %then 	%let sep=%quote( );
	%if &sep=%quote( ) %then 	%let _olist=%sysfunc(compbl(&_olist));
	%else 						%let _olist=%sysfunc(compress(&_olist));

	/* check the cases where no keys were passed, then retrieve them all */
	%if %macro_isblank(key) %then %do;
		/* create a temporary list */
		%let _tmplist=&_olist;
		/* loop over the occurrences of the "&OP" string */
		%let _ind=%sysfunc(find(%quote(&_tmplist), &op, i));
		%do %while(&_ind > 0);
			/* set the temporary strings _TMP to the substring FROM the beginning TO the first occurrence of "&OP" in _TMPLIST */
			%let _tmp=%substr(%quote(&_tmplist), 1, %eval(&_ind - 1));  
			/* retrieve the key as the substring FROM the last occurrence of "&SEP" TO the end of _TMP */
			%let _ikey=%scan(%quote(&_tmp), %list_length(%quote(&_tmp), sep=&sep), &sep);
			%let _ikey=%sysfunc(strip(&_ikey));
			/* update the list of possible keys */
			%if %macro_isblank(key) %then 	%let key=&_ikey;
			%else							%let key=&key.&REP.&_ikey;
			/* update the temporary list with the substring FROM the first occurrence of "&OP" TO the end of _TMPLIST */
			%let _tmplist=%substr(%quote(&_tmplist), %eval(&_ind + &lenop));
			/* update the index of occurrenec of the "&OP" string */
			%let _ind=%sysfunc(find(%quote(&_tmplist), &op, i));
		%end;
	%end;

	/* loop over the found/passed keys */
	%do _ik=1 %to %list_length(&key);
		%let _ikey=%quote(%scan(&key, &_ik));
		/* let us look for the occurrence of "&_IKEY&OP"; note that when _IKEY is blank, we will just look
		* for the occurrence of "&OP" */
		%let _ind=%sysfunc(find(%quote(&_olist), &_ikey.&op, i));
		/*%let _ind=%index(%quote(%upcase(&_olist)), &_ikey.&op);*/
		%if &_ind>0 %then %do;
			/* compute the actual length of the key string */
			%let lenkey=%length(&_ikey);
			/* retrieve the substring FROM the end of the occurrence of "&_IKEY&OP" TO the end of the string */
			%let _tmp=%substr(%quote(&_olist), %eval(&_ind + &lenkey + &lenop));  
			%let _tmp=%sysfunc(strip(%quote(&_tmp)));
			/* check whether _TMP starts with the separator: in that case, an empty value corresponds to the
			* key "&_IKEY" */
			%if %substr(%quote(&_tmp), 1, &lensep) EQ &sep %then %do; 
				/* set _VALUE to the empty value */
				%let _value=_EMPTY_;
				%let lenval=0;
			%end;
			%else %do;
				/* retrieve the _VALUE as the substring FROM the beginning of _TMP TO the first blank */
				%let _value=%list_index(%quote(&_tmp), 1, sep=&sep); /* %scan(&_tmp, 1, %quote(&sep)); */
				%let lenval=%length(&_value);
			%end;
			/* check whether values were specified through VALUE: in that case, filter out those values in
			* _VALUE that do not match any value in VALUE */
			%if not %macro_isblank(value) %then %do;
				%let _itest=%list_find(&value, &_value);
				%if %macro_isblank(_itest) %then %goto next;
			%end;
			/* update the list _OKEY of found keys */
			%let _okey=&_okey.&REP.&_ikey;
			/* update the output list _OVALUE of values */
			%let _ovalue=&_ovalue.&REP.&_value;
			/* update _OLIST with all the substring FROM the beginning TO the occurrence of "&_IKEY&OP" */
			%if %eval(&_ind - &lensep > 1) %then								
				%let _olist=%substr(%quote(&_olist), 1, %eval(&_ind - &lensep - 1));
			%else			
				%let _olist=;
			/* update _TMP as the substring FROM the end of the occurrence of "&_VALUE" to the end of _TMP */
			%if %eval(&lenval + &lensep) < %length(%quote(&_tmp)) %then 		
				%let _tmp=%substr(%quote(&_tmp), %eval(&lenval + &lensep + 1));
			%else				
				%let _tmp=;
			/* append both substrings from which the pattern "&KEY.&OP.&_VALUE" has been deleted */
			%if %macro_isblank(_olist) or  %macro_isblank(_tmp) %then 		
				%let _olist=&_olist.&_tmp;
			%else															
				%let _olist=&_olist.&sep.&_tmp;
			/* possibly get rid of duplicated separator that may occur from deleting the pattern */
			%let _olist=%sysfunc(tranwrd(%quote(&_olist), &sep.&sep, &sep));
			%next:
		%end;
	%end;

	/* somehow clean/trim */
	%if not %macro_isblank(_ovalue) %then 	%let _ovalue=%sysfunc(strip(&_ovalue));
	%if not %macro_isblank(_okey) %then 	%let _okey=%sysfunc(strip(&_okey));
	/*%if not %macro_isblank(_olist) %then 	%let _olist=%sysfunc(strip(&_olist));*/

	/* let us calculate the items, even if this is not required */
	%if not (%macro_isblank(_okey) or %macro_isblank(_ovalue)) %then %do;
		%let _oitem=%list_append(&_okey, &_ovalue, zip=&op, rep=&sep);
		%let _oitem=%sysfunc(tranwrd(%quote(&_oitem),_EMPTY_,%quote()));
		%if &sep=%quote( ) %then 	%let _oitem=%sysfunc(compbl(%quote(&_oitem)));
		%else 						%let _oitem=%sysfunc(compress(%quote(&_oitem)));
	%end;

	/* set the outputs */
	%quit:
	DATA _null_;
		%if not %macro_isblank(_value_) %then %do;
			call symput("&_value_", "&_ovalue");
		%end;
		%if not %macro_isblank(_str_) %then %do;
			call symput("&_str_", "&_olist");
		%end;
		%if not %macro_isblank(_key_) %then %do;
			call symput("&_key_", "&_okey");
		%end;
		%if not %macro_isblank(_item_) %then %do;
			call symput("&_item_", "&_oitem");
		%end;
	run;

	%exit:
%mend str_to_keyvalue;


%macro _example_str_to_keyvalue;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local op list olist rlist ivalue ovalue rvalue key nkey oitem ritem;
	%let op=%quote(=);

	%let key=KEY;
	%let sep=%quote(,);
	%let list=A&sep.B&sep.C&sep.D; /* A,B,C,D */
	%put;
	%put (i) Dummy example on list without (key,value) pairs;
	%str_to_keyvalue(%quote(&list), key=&key, sep=&sep, _str_=olist);
	%if %quote(&olist)=%quote(&list) %then 	
		%put OK: TEST PASSED - No (key,value) detected / List unchanged: &list;
	%else 				
		%put ERROR: TEST FAILED - List changed: &olist;

	%let list=&key.&op.A&sep.B;		/* KEY=A,B */
	%put;
	%put (ii) Simple test with list=&list;
	%str_to_keyvalue(%quote(&list), key=&key, _value_=ovalue, _key_=nkey, _str_=olist, _item_=oitem, sep=&sep);
	%let rvalue=A; 			
	%let rlist=B;	
	%let ritem=&key.&op.A; 			
	%if &nkey=&key and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) and %quote(&oitem)=%quote(&ritem) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&rkey,&rvalue) / Items: &ritem / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&ovalue) / Items: &oitem / List updated: &olist;

	%let list=A&sep.B&sep.&key.&op.C&sep.D; /* A,B,KEY=C,D */
	%put;
	%put (iii) Retrieve the value(s) from &list with the key=&key;
	%str_to_keyvalue(%quote(&list), key=&key, _key_=nkey, _value_=ovalue, _str_=olist, sep=&sep);
	%let rvalue=C;
	%let rlist=A&sep.B&sep.D;
	%if &nkey=&key and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&key,&rvalue) / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&ovalue) / List updated: &olist;

	%let list=A&sep.B&sep.&key.&op.&sep.D; /* A,B,KEY=,D */
	%put;
	%put (iv) Retrieve the value(s) from &list with the key=&key;
	%str_to_keyvalue(%quote(&list), key=&key, _value_=ovalue, _key_=nkey, _str_=olist, sep=&sep);
	%let rvalue=_EMPTY_;
	/* rlist unchanged: A B D */
	%if &nkey=&key and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&key,&rvalue) / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&ovalue) / List updated: &olist;

	%let key1=KEY1;
	%let key2=KEY2;
	%let key=&key1 &key2;	/* KEY1 KEY2 */
	%let list=A&sep.&key2.&op.B&sep.&key1.&op.C&sep.D; /* A,KEY2=B,KEY1=C,D */
	%put;
	%put (v) Retrieve the value(s) from &list with the keys=&key1 &key2;
	%str_to_keyvalue(%quote(&list), key=&key, _key_=nkey, _value_=ovalue, _str_=olist, sep=&sep);
	%let rvalue=C B;
	%let rlist=A&sep.D;	/* A D */
	%if &nkey=&key and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&key,&rvalue) / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&ovalue) / List updated: &olist;

	%put;
	%put (vi) Ibid with &list: show that blanks have no effect;
	%str_to_keyvalue(%quote(&list), key=&key, _key_=nkey, _value_=ovalue, _str_=olist, sep=&sep);
	%if &nkey=&key and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&key,&rvalue) / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&ovalue) / List updated: &olist;

	%put;
	%put (vii) Similarly retrieve the key(s) from &list corresponding to value=&rvalue;
	%str_to_keyvalue(%quote(&list), value=&rvalue, _key_=nkey, _value_=ovalue, _str_=olist, sep=&sep);
	%let rvalue=B C;		/* depends on the ... */
	%let rkey=&key2 &key1;	/* order of appearance of the keys in list: KEY2 KEY1 */
	/* rlist unchanged: A D */
	%if &nkey=&rkey and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&key,&rvalue) / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&rvalue) / List updated: &olist;

	%let key3=KEY3;
	%let key=&key1 &key2 &key3;		/* KEY1 KEY2 KEY3 */
	%let list=A&sep.&key2.&op.B&sep.&key1.&op.C&sep.D&sep.&key3.&op.E; /* A,KEY2=B,KEY1=C,D,KEY3=E */
	%put;
	%put (viii) Retrieve all value(s) from &list (keys are not passed);
	%str_to_keyvalue(%quote(&list), _key_=nkey, _value_=ovalue, _str_=olist, sep=&sep, _item_=oitem);
	%let rvalue=B C E; 				/* depends on the ... */
	%let rkey=&key2 &key1 &key3; 	/* order of appearance of the keys in list: KEY2 KEY1 KEY3 */
	/* rlist unchanged: A D */
	%let ritem=&key2.&op.B&sep.&key1.&op.C&sep.&key3.&op.E; /* KEY2=B,KEY1=C,KEY3=E */
	%if &nkey=&rkey and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) and %quote(&oitem)=%quote(&ritem) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&rkey,&rvalue) / Items: &ritem / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&ovalue) / Items: &oitem / List updated: &olist;

	%let list=A, B, K1=C, D, K2=E, K3=, F, K4=G;
	%put;
	%put (ix) Retrieve all (key,value) pairs from &list;
	%str_to_keyvalue(%quote(&list), _value_=ovalue, _key_=nkey, _str_=olist, _item_=oitem, sep=&sep);
	%let rvalue=C E _EMPTY_ G; 			
	%let rkey=K1 K2 K3 K4; 			
	%let rlist=A,B,D,F;	
	%let ritem=%quote(K1=C,K2=E,K3=,K4=G); 			
	%if &nkey=&rkey and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) and %quote(&oitem)=%quote(&ritem) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&rkey,&rvalue) / Items: &ritem / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&ovalue) / Items: &oitem / List updated: &olist;

	%let ivalue=C F G;
	%put;
	%put (x) Ibid, but imposing the list of values=&ivalue;
	%str_to_keyvalue(%quote(&list), value=&ivalue, _value_=ovalue, _key_=nkey, _str_=olist, _item_=oitem, sep=&sep);
	%let rvalue=C G; 			
	%let rkey=K1 K4; 			
	%let rlist=A,B,D,K2=E,K3=,F;	
	%let ritem=%quote(K1=C,K4=G); 			
	%if &nkey=&rkey and &ovalue=&rvalue and %quote(&olist)=%quote(&rlist) and %quote(&oitem)=%quote(&ritem) %then 	
		%put OK: TEST PASSED - Correct (key,value) pairs returned: (&rkey,&rvalue) / Items: &ritem / List updated: &rlist;
	%else 				
		%put ERROR: TEST FAILED - Wrong (key,value) pairs returned: (&nkey,&ovalue) / Items: &oitem / List updated: &olist;

	%put;
%mend _example_str_to_keyvalue;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_str_to_keyvalue;
*/

/** \endcond */
