/** 
## var_info {#sas_var_info}
Return information regarding a given variable in a dataset, _e.g._ the type of the
variable, its (in)format, its length, ...

	%var_info(dsn, var, _typ_=, _lab_=, _fmt_=, _len_=, _pos_=, _infmt_=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : a field name whose information is provided;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
`_typ_, _lab_, _fmt_, _infmt_, _len_, _pos_` : names of the macro variables used to store the 
	output information about the variable in the dataset, respectively the type, the label, the 
	format, the informat, the length and the position of the variable.

### Examples
Let us consider the table `_dstest30`:
geo | value 
----|-------
 BE |  0    
 AT |  0.1  
 BG |  0.2  
 '' |  0.3 
 FR |  0.4  
 IT |  0.5 

then if we want to retrieve information about the variable `geo`, we use for instance:

	%let type=;
	%let len=;
	%let pos=;
	%let vfmt=;
	%var_info(_dstest30, value, _typ_=type, _len_=len, _pos_=pos, _vfmt_=vfmt);

which returns `pos=1, type=C, len=2, vfmt=BEST12`.

Run macro `%%_example_var_info` for more examples.

### See also
[%var_check](@ref sas_var_check), [%var_compare](@ref sas_var_compare), [%var_rename](@ref sas_var_rename), 
[%ds_order](@ref sas_ds_order), [%var_count](@ref sas_var_count),
[VARNUM](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148439.htm),
[VARTYPE](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148443.htm),
[VARLABEL](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148456.htm),
[VARFMT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148399.htm),
[VARLEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148433.htm),
[VARINFMT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148419.htm),
[VFORMAT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000245971.htm),
*/ /** \cond */

%macro var_info(dsn
				, var
				, _pos_=
				, _typ_=
				, _lab_ =
				, _fmt_=
				, _vfmt_=
				, _len_=
				, _infmt_=
				, lib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pos_) EQ 1 and %macro_isblank(_lab_) EQ 1
			and %macro_isblank(_typ_) EQ 1 and %macro_isblank(_len_) EQ 1
			and %macro_isblank(_fmt_) EQ 1 and %macro_isblank(_infmt_) EQ 1 
			and %macro_isblank(_vfmt_) EQ 1,		
			txt=%quote(!!! Missing parameters: _POS_, _LAB_, _TYP_, _LEN_, _FMT_, _INFMT_, or _VFMT_ !!!)) %then
		%goto exit;

	%if %macro_isblank(lib) %then 	%let lib=WORK;
	
	%if %error_handle(ErrorInputParameter, 
			%var_check(&dsn, &var, lib=&lib) EQ 1,		
			txt=!!! Field %upcase(&var) not found in dataset %upcase(&dsn) !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* method 1: through macro implementation 
	%let dsid=%sysfunc(open(&lib..&dsn, i, ,D));
	%if &dsid %then %do;
		%let pos=%sysfunc(varnum(&dsid,&var));
		%if "&_pos_"^="" %then %do;
			data _null_;
				call symput("&_pos_","&pos");
			run;
		%end;
		%if "&_type_"^="" %then %do;
	    	%let typ = %sysfunc(vartype(&dsid, &pos));
			data _null_;
				call symput("&_typ_","&typ");
			run;
		%end;
		%if "&_fmt_"^="" %then %do;
	    	%let fmt = %sysfunc(varfmt(&dsid, &pos));
			data _null_;
				call symput("&_fmt_","&fmt");
			run;
		%end;
		%if "&_len_"^="" %then %do;
			%let len = %sysfunc(varlen(&dsid, &pos));
			data _null_;
				call symput("&_len_","&len");
			run;
		%end;
		%if "&_infmt_"^="" %then %do;
			%let infmt = %sysfunc(varinfmt(&dsid, &pos));
			data _null_;
				call symput("&_infmt_","&infmt");
			run;
		%end;
      	%let rc=%sysfunc(close(&dsid));
   	%end;
	*/

	/* method 2: through a single data step */
	data _null_;
   		dsid = open("&lib..&dsn",'i', , 'D'); /* D:  two-level data set name */
		pos = varnum(dsid, "&var");
		%if not %macro_isblank(_pos_) %then %do;
			call symput("&_pos_",compress(pos,,'s'));
		%end;
		%if not %macro_isblank(_lab_) %then %do;
	    	lab = varlabel(dsid, pos);
			call symput("&_lab_",compress(lab,,'s'));
		%end;
		%if not %macro_isblank(_typ_) %then %do;
	    	typ = vartype(dsid, pos);
			call symput("&_typ_",compress(typ,,'s'));
		%end;
		%if not %macro_isblank(_fmt_) %then %do;
	    	fmt = varfmt(dsid, pos);
			call symput("&_fmt_",compress(fmt,,'s'));
		%end;
		%if not %macro_isblank(_len_) %then %do;
			len = varlen(dsid, pos);
			call symput("&_len_",compress(len,,'s'));
		%end;
		%if not %macro_isblank(_infmt_) %then %do;
			infmt = varinfmt(dsid, pos);
			call symput("&_infmt_",compress(infmt,,'s'));
		%end;
	    rc = close(dsid);		
	run;

	%if not %macro_isblank(_vfmt_) %then %do;
		data _null_;
			SET &lib..&dsn;
			vfmt = vformat(&var);
			call symput("&_vfmt_",compress(vfmt,,'s'));
		run;
	%end;

	%exit:
%mend var_info;

%macro _example_var_info;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local fmt infmt type pos len vfmt;

	%_dstest30;
	%*ds_print(_dstest30);

	%put;
	%put (i) Consider a dummy example where parameters are missing ...;
	%var_info(_dstest30, geo);
	%if &pos= and &type= and &len= and &fmt= and &infmt= and &vfmt= %then 		
		%put OK: TEST PASSED - Dummy test: nothing returned;
	%else 								
		%put ERROR: TEST FAILED - Dummy test: output returned;

	%put;
	%put (ii) In dataset _dstest30, consider the character variable GEO ...;
	%var_info(_dstest30, geo, _typ_=type, _fmt_=fmt, _len_=len, _pos_=pos, _infmt_=infmt, _vfmt_=vfmt);
	%if &pos=1 and &type=C and &len=2 and &fmt= and &infmt= and &vfmt=$2. %then 		
		%put OK: TEST PASSED - Test on GEO variable returns: pos=1, type=C, len=2, fmt=, infmt=, and vfmt=$2.;
	%else 								
		%put ERROR: TEST FAILED - Test on GEO variable returns: pos=&pos, type=&type, len=&len, fmt=&fmt, infmt=&infmt, and vfmt=&vfmt;

	%put;
	%put (iii) In dataset _dstest30, consider the numeric variable VALUE ...;
	%var_info(_dstest30, value, _typ_=type, _fmt_=fmt, _len_=len, _pos_=pos, _infmt_=infmt, _vfmt_=vfmt);
	%if &pos=2 and &type=N and &len=8 and &fmt= and &infmt= and &vfmt=BEST12. %then 		
		%put OK: TEST PASSED - Test on VALUE variable returns: pos=2, type=N, len=8, fmt=, infmt=, and vfmt=BEST12.;
	%else 								
		%put ERROR: TEST FAILED - Test on VALUE variable returns: pos=&pos, type=&type, len=&len, fmt=&fmt, infmt=&infmt, and vfmt=&vfmt;

	%work_clean(_dstest30);
%mend _example_var_info;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_info; 
*/

/** \endcond */
