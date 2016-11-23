/** 
## var_compare {#sas_var_compare}
Compare variables of a given dataset.

	%var_compare(dsn, var, varc=, dsnc=, _ans_=, 
				typ=yes, len=no, fmt=no, vfmt=no, infmt=no, pos=no, lab=no, 
				lib=WORK, libc=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : a variable name whose properties are considered for comparison;
* `varc` : (_option_) a second variable to compare to the first one;
* `dsnc` : (_option_) a second dataset reference;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.
* `libc` : 
* `typ, lab, fmt, infmt, len, pos` : boolean flags (`yes/no`) set to define which attributes/properties 
	of the variables are considered for comparisong; they respectively represent the type, the label, 
	the format, the informat, the length and the position; by default, `typ=yes` while all others are 
	set to `no`.

### Returns

### Examples
Run macro `%%_example_var_compare` for more examples.

### See also
[%var_check](@ref sas_var_check), [%var_info](@ref sas_var_info), [%var_rename](@ref sas_var_rename), 
[%ds_order](@ref sas_ds_order), [%var_count](@ref sas_var_count),
[VARNUM](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148439.htm),
[VARTYPE](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148443.htm),
[VARLABEL](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148456.htm),
[VARFMT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148399.htm),
[VARLEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148433.htm),
[VARINFMT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148419.htm),
[VFORMAT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000245971.htm),
*/ /** \cond */

%macro var_compare(dsn 
				, var		/* Nessuno... (REQ) */
				, varc=
				, dsnc=
				, _ans_= 
				, pos=
				, typ=yes
				, lab=
				, fmt=
				, vfmt=
				, len=
				, infmt=
				, lib=
				, libc=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%if %macro_isblank(libc) %then 	%let libc=&lib;
	%if %macro_isblank(dsnc) %then 	%let dsnc=&dsn;
	%if %macro_isblank(varc) %then 	%let varc=&var;

	%local nvar;
	%let nvar=%list_length(&var);

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i
		_pos _cpos
		_typ _ctyp
		_lab _clab
		_fmt _cfmt
		_vfmt _cvfmt
		_infmt _cinfmt
		_ans _tmp
		_var _varc
		SEP;
	%let _ans=;
	%let SEP=%quote( );

	%do _i=1 %to &nvar;
		%let _var=%scan(&var, &_i);	
		%let _varc=%scan(&varc, &_i);

		%var_info(&dsn, &_var, _typ_=_typ, _pos_=_pos, _lab_=_lab, _fmt_=_fmt, _vfmt_=_vfmt, _len_=_len, _infmt_=_infmt,
			lib=&lib);
		%var_info(&dsnc, &_varc, _typ_=_ctyp, _pos_=_cpos, _lab_=_clab, _fmt_=_cfmt, _vfmt_=_cvfmt, _len_=_clen, _infmt_=_cinfmt, 
			lib=&libc);
		
		%let _tmp=0;
		%if %upcase("&typ")="YES" %then %do;
			%put &_typ COMPARED TO &_ctyp;
			%if &_typ^=&_ctyp %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&len")="YES" %then %do;
			%if &_len^=&_clen %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&fmt")="YES" %then %do;
			%if &_fmt^=&_cfmt %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&vfmt")="YES" %then %do;
			%if &_vfmt^=&_cvfmt %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&pos")="YES" %then %do;
			%if &_pos^=&_cpos %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&lab")="YES" %then %do;
			%if &_lab^=&_clab %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&infmt")="YES" %then %do;
			%if &_infmt^=&_cinfmt %then %let _tmp=1;
			%goto next;
		%end;
		%next:
		%let _ans=&_ans.&SEP.&_tmp;
	%end;

	%let _ans=%sysfunc(trim(&_ans));

	data _null_;
		call symput("&_ans_","&_ans");
	run;

	%exit:
%mend var_compare;


%macro _example_var_compare;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ans;

	%_dstest5;
	%_dstest6;
	%var_compare(a, _dstest5, dsnc=_dstest6, _ans_=ans);
	%put ans=&ans;

	%_dstest31;
	%var_numcast(_dstest31, unit, odsn=tmp, suff=_EMPTY_);

	%var_compare(unit, _dstest31, dsnc=tmp, _ans_=ans);
	%put ans=&ans;

	%work_clean(_dstest5, _dstest6, _dstest31, tmp);

%mend _example_var_compare;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_compare; 
*/

/** \endcond */

