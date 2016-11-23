/** 
## list_map {#sas_list_map}
Calculate the transform of a list given by a mapping table (similarly to a LookUp Transform, LUT).

	%list_map(map, list, _maplst_=, var=, casense=no, sep=%quote( ), lib=WORK);

### Arguments
* `map` : input mapping table, _i.e._ dataset storing the lookup correspondance;
* `list` : list of unformatted strings;
* `var` : (_option_) fields of the `map` table used as origin and destination (in this order)
	of the mapping; default: `var=1 2`, _i.e._ the first and second fields (in `varnum` order)
	are used as origin and destination respectively;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive comparison/matching; 
	default: `casense=no`, _i.e._ upper-case items in `list` and the origin variable are matched;
* `sep` : (_option_) character/string used as a separator in the input lists; default: `sep=%%quote( )`, 
	_i.e._ the input `list1` and `list2` are both blank-separated lists of items;
* `lib` : (_option_) input library where `map` is stored; default: `lib` is set	to `WORK`.
 
### Returns
`_maplst_` : name of the variable storing the output list built as the list of items obtained through
	the transform defined by the variables `var` of the table `map`, namely: assuming all elements
	in `list` can be found in the (unique) observations of the origin variable, the element in the `i`-th 
	position of the output list is the `j`-th element of the destination variable when `j` is the position
	of the `i`-th element of `list` in the origin variable. 

### Example
Given test dataset `_dstest32`:
geo | value
----|------
 BE |  0
 AT |  0.1
 BG |  0.2
 LU |  0.3
 FR |  0.4
 IT |  0.5
used as a mapping table, running the simple operation:

	%let list=FR LU BG;
	%let maplst=
	%list_map(_dstest32, &list, _maplst_=maplst, var=1 2);

returns: `maplst=0.4 0.3 0.2`.	

Run macro `%%_example_list_map` for more examples.

### Note
It is not checked that the values in the origin variable are unique. 

### See also
[%var_to_list](@ref sas_var_to_list), [%list_find](@ref sas_list_find), [%list_index](@ref sas_list_index),
[%ds_select](@ref sas_ds_select).
*/ /** \cond */

%macro list_map(map 			/* Input reference mapping table 								(REQ) */
        		, list 			/* List of blank-separated items 								(REQ) */
        		, _maplst_ 		/* Name of the macro variable storing the output list 			(REQ) */
        		, var= 			/* Fields used for origin and destination of the LUT transform 	(OPT) */
				, casense=no	/* Boolean flag set for case sensitive comparison 				(OPT) */
				, sep=			/* Character/string used as list separator 						(OPT) */
				, lib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
	
	%local 	_varlst; /* temporary used list of variables for conversion */

	/* deal with simple cases */
	%if %macro_isblank(list) %then 
		%goto exit;

	/* set come default values */
	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%if %macro_isblank(sep) %then 	%let sep=%quote( ); /* list separator */

	/* MAP: perform some checking and default settings on input/output */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&map, lib=&lib) NE 0, mac=&_mac,		
			txt=%quote(!!! Mapping table %upcase(&map) not found in library %upcase(&lib) !!!)) %then
		%goto exit;

	/* _MAPLST_: check/set */
	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_maplst_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _MAPLST_ not set !!!) %then
		%goto exit;

	/* VAR: check that the org/dest variables are correctly set */
	%if %macro_isblank(var) %then 
  	 	%let var=1 2;
	%else %if %error_handle(ErrorInputParameter, 
			%list_length(&var) NE 2, mac=&_mac,		
			txt=!!! Wrong size for input parameter VAR not set: must be 2 !!!) %then
		%goto exit;

	/* the following operation enables us to convert VAR into the variable name in the case it
	* is passed as an integer */
	%var_check(&map, &var, _varlst_=_varlst, lib=&lib);

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_varlst) EQ 1, mac=&_mac,		
			txt=%quote(!!! Field %upcase(&var) not found in dataset %upcase(&map) !!!)) %then
		%goto exit;

	/* update */
	%let var=&_varlst;

	/* CASENSE: check/set */
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&casense), type=CHAR, set=YES NO) NE 0,	
			txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* start the actual LUT transform */ 
	%local _i		/* loop increment */
		_dsn
		_org		/* origin of the lookup transform */
		_dest		/* destination */	
  		_item		/* temporary scanned element of the list */
		_pos		/* position of _item in origin list */
		_lut		/* temporary lut value */
	  	_lutlst;	/* final output list */
	%let _lutlst=;
	%let _dsn=TMP&_mac;

	/* prior selection filter of the table so as to avoid retrieving the entire list */
	%let where=%quote(%list_index(&var, 1) in %sql_list(&list));
	%ds_select(&map, &_dsn, where=&where, ilib=&lib);

	/* retrieve the origin/destination observations as lists from the MAP table */
	%var_to_list(&_dsn, %list_index(&var, 1), _varlst_=_org, sep=&sep);
	%var_to_list(&_dsn, %list_index(&var, 2), _varlst_=_dest, sep=&sep);

	%work_clean(&_dsn); /* get rid of the temporary table */

	/* loop over the element of the list so as to map them */
	%do _i=1 %to %list_length(&list, sep=&sep);
		%let _item=%scan(&list, &_i, &sep);
		%let _pos=%list_find(&_org, &_item, casense=&casense, sep=&sep);
		%if %error_handle(ErrorInputParameter, 
				%macro_isblank(_pos) EQ 1, mac=&_mac,		
				txt=! Element %upcase(&_item) not found in origin MAP table !, verb=warn) %then
			%goto next;
		/* update the output list with correspondance value */
		%let _lut=%list_index(&_dest, &_pos, sep=&sep);
		%let _lutlst=&_lutlst.&sep.&_lut;
		%next:
	%end;

	/* set the output */
	data _null_;
		call symput("&_maplst_","&_lutlst");
	run;

	%exit:
%mend list_map;

%macro _example_list_map;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local vars list lutlst olutlst;

	%_dstest32;

	%put;
	%let varlst=GEO VALUE;
	%let list=FR LU BG;
	%put (i) Use variables %upcase(vars) of _dstest32 in LUT transform of list=&list;
	%list_map(_dstest32, &list, _maplst_=lutlst, var=&varlst);
	%let olutlst=0.4 0.3 0.2;
	%if &lutlst EQ &olutlst %then 	%put OK: TEST PASSED - _dstest32-based LUT returns: %upcase(&olutlst);
	%else 							%put ERROR: TEST FAILED - Wrong result returned;

	%let varlst=1 2;
	%put;
	%put (ii) Same operation passing the origin/destination varnum position instead of their names;
	%list_map(_dstest32, &list, _maplst_=lutlst, var=&varlst);
	%if &lutlst EQ &olutlst %then 	%put OK: TEST PASSED - _dstest32-based LUT returns: %upcase(&olutlst);
	%else 							%put ERROR: TEST FAILED - Wrong result returned;

	%put;

	%work_clean(_dstest32);
%mend _example_list_map;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_map; 
*/

/** \endcond */

