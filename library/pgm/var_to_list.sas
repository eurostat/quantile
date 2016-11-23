/**
## var_to_list {#sas_var_to_list}
Extract the values of a given variable in a dataset into an unformatted (_i.e._, unquoted 
and blank-separated) list.

	%var_to_list(dsn, var, _varlst_=, distinct=no, na_rm=yes, sep=%str( ), lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : either a field name, or the position of a field name in, in `dsn`, whose values (observations) 
	will be converted into a list;
* `distinct` : (_option_) boolean flag (`yes/no`) set to return in the list only distinct values
	from `var` variable; in practice, runs a SQL `SELECT DISTINCT` process prior to the values'
	extraction; default: `no`, _i.e._ all values are returned;
* `sep` : (_option_) character/string separator in output list; default: `%%str( )`, _i.e._ `sep` 
	is blank;
* `na_rm` : (_option_) boolean flag (`yes/no`) set to remove missing (NA) values from the observations;
	default: `na_rm=yes`, therefore all missing (`.` or ' ') values will be discarded in the output
	list;
* `lib` : (_option_) output library; default: `lib` is set	to `WORK`.

### Returns
`_varlst_` : name of the macro variable used to store the output list, _i.e._ the (blank-separated) list 
	of (possibly non-missing) observations in `var`.

### Examples
Let us consider the test dataset #28 in `WORK.dsn`:
geo | value 
----|-------
 AT |  1    
 '' |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  4 
then the following call to the macro:

	%let ctry=;
	%var_to_list(_dstest28, geo, _varlst_=ctry);
	%var_to_list(_dstest28,   1, _varlst_=ctry);
	
will both return: `ctry=AT BG FR IT`, while:

	%let val=;
	%var_to_list(_dstest28, value, distinct=yes, _varlst_=val);

will return: `val=1 2 3 4`, and:

	%var_to_list(_dstest28, value, distinct=yes, _varlst_=val, na_rm=no);
	%var_to_list(_dstest28,     2, distinct=yes, _varlst_=val, na_rm=no);

will both return: `val=1 . 2 3 . 4`.

Run macro `%%_example_var_to_list` for more examples.

### Note
1. In short, this macro runs, when `distinct=yes`, and `na_rm=yes`:

       PROC SQL noprint;
			SELECT DISTINCT	&_var 
			INTO: &_varlst_  SEPARATED BY "&sep" 
			FROM &lib..&dsn
			WHERE not missing(&_var);
		quit;
2. For empty variables (_i.e._ with no observation, or missing data while default `na_rm=no`), an empty 
list is returned. 
3. On data conversion, format and informat: 
	* <http://support.sas.com/publishing/pubcat/chaps/59498.pdf>,
	* <http://www.sys-seminar.com/EE/Files/Converting%20Numeric%20and%20Character%20Data.pdf>.

## References
1. Satchi, T. (2002): ["Using the magical keyword "INTO:" in PROC SQL"](http://www2.sas.com/proceedings/sugi27/p071-27.pdf).
2. Rozhetskin, D. (2010): ["Choosing the best way to store and manipulate lists in SAS"](http://www.wuss.org/proceedings10/coders/2972_9_COD-Rozhetskin.pdf).

### See also
[%list_to_var](@ref sas_list_to_var), [%var_to_clist](@ref sas_var_to_clist), [%var_count](@ref sas_var_count), 
[%var_info](@ref sas_var_info).
*/ /** \cond */

%macro var_to_list(dsn			/* Input dataset 														(REQ) */
				, var 			/* Name of the variable in the input dataset 							(REQ) */ 
			    , _varlst_=		/* Name of the output list of observations in input variable 			(REQ) */
				, distinct=no 	/* Distinct clause 														(OPT) */
				, na_rm=yes		/* Boolean flag set to remove missing (NA) values from the observations (OPT) */
				, sep=			/* Character/string used as list separator 								(OPT) */
				, lib=			/* Input library 														(OPT) */		
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* perform some checking and default settings */
	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_varlst_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _VARLST_ not set !!!) 
			or %error_handle(ErrorInputParameter, 
				%par_check(%upcase(&distinct &na_rm), type=CHAR, set=YES NO) NE 0 0, mac=&_mac,		
				txt=%quote(!!! Wrong parameter for boolean flag NA_RM/DISTINCT !!!)) %then
		%goto exit;

 	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%if %macro_isblank(sep) %then 	%let sep=%quote( ); /* list separator */

	/* perform some checking and default settings */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) NE 0, mac=&_mac,		
			txt=%quote(!!! Dataset %upcase(&dsn) not found in library %upcase(&lib) !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _ans		/* answer to existence test */
		_count 		/* count of non-missing values */
		_varlst		/* local variable used for output */ 
		_METHOD_;	/* dummy flag */
	%let _METHOD_=BEST; /* BEST; /* DUMMYandOBSOLETE */

	/* The following test is also done in the macro %ds_isempty used below, still we do
	* it here since it enables us to convert VAR into the variable name in the case it is passed
	* as an integer */
	%if %list_count(%par_check(&var, type=INTEGER), 0) >0 %then %do;
		%var_check(&dsn, &var, _varlst_=_varlst, lib=&lib);
		%if %error_handle(ErrorInputParameter, 
				%macro_isblank(_varlst) EQ 1, mac=&_mac,		
				txt=%quote(!!! Field %upcase(&var) not found in dataset %upcase(&dsn) !!!)) %then
			%goto exit;
		/*  update/reset */
		%let var=&_varlst; /* possibly unchanged */
	%end;

	/* test whether the dataset is empty since PROC SQL requires each of its tables to 
	* have at least 1 column */
	%ds_isempty(&dsn, var=&var, lib=&lib, _ans_=_ans);
	%if %error_handle(EmptyInputDataset, 
			&_ans EQ 1, mac=&_mac,		
			txt=%quote(!!! Dataset %upcase(&dsn) is empty !!!)) %then
		%goto exit;

	/* check that there are indeed observations: already done with %ds_isempty above
	%var_count(&dsn, &var, _count_=_count, lib=&lib);
	%if %eval(&_count) EQ 0 %then 
		%goto exit; */

	/* actual computation */
	%if &_METHOD_=BEST or %upcase(&na_rm)=NO %then %do;

		PROC SQL noprint;
			SELECT 
			%if %upcase("&distinct")="YES" %then %do;
				DISTINCT
			%end;
			&var 
			INTO :&_varlst_  SEPARATED BY "&sep" 
			FROM &lib..&dsn
			%if %upcase("&na_rm")="YES" %then %do;
				WHERE not missing(&var)
			%end;
			;
		quit;
		/*DATA _null_;
			call symput("&_varlst_","&_varlst");
		run;*/
	%end;

	%else %if &_METHOD_=DUMMYandOBSOLETE %then %do;
		%local _dsn 	/* temporary copy table */
			_slen 		/* output string length */
			_typ 		/* type variable returned by var_info */
			_fmt 		/* format variable returned by var_info */ 
			_vfmt 		/* vformat variable returned by var_info */ 
			_len 		/* length variable returned by var_info */ 
			num;		/* number of items */
		%let _dsn=TMP_%upcase(&sysmacroname);

		/* possibly return a list with distinct values only */
		%if %upcase(&distinct)=YES %then %do;
			PROC SQL noprint;
				CREATE TABLE &_dsn AS
				SELECT DISTINCT &var
				FROM &lib..&dsn
			quit;
			%let lib=WORK;
		%end;
		%else %do;
			%let _dsn=&dsn;
		%end;
	
		/* compute the length of the output list (seen as a string) */
		%var_info(&_dsn, &var, _typ_=_typ, _fmt_=_fmt, _vfmt_=_vfmt, _len_=_len, lib=&lib);

		%if %macro_isblank(_fmt) %then %do;
		/* %else %if &typ=N %then %do;
			%if "&_vfmt"^="" %then 	%let _fmt=&_vfmt;
			%else 					%let _fmt=best&_len..;
		%end; */
			%if &_typ=N %then 			%let _fmt=best&_len..;
			%else %if &_typ=C %then 	%let _fmt=$char&_len..;
		%end;

		/* calculate how many items in the list */
		%let num=%eval(&_count);
		/* then, since this will be stored as a string, we need at least:
		* - lenght of one field + 2 quotes ": _len+2
		* - multiplied by the number of observations: num
		* - added with the length of all comma + lenght of 2 parentheses : (num-1)+2
		* so that the _slen we compute is large enough */
		%let _slen=%eval(&num*(&_len+4));

		/* store the values in array then convert to a macro */
		DATA _null_;
			set &lib..&_dsn end=_last; /* hopefully _last won't be the name of any field... */
			array v(&num) $&_len;
			retain i (0);
			retain v;
			length varlst $&_slen;
			if  not missing(&var) then do;
				i = i + 1;
				v(i) = put(&var, &_fmt);
			end;
			if _last then do;
				varlst = v(1);
				do j = 2 to i-1;
					varlst = compbl(varlst)||trim(v(j))||"&sep";
				end;
				if i>1 then do;
					varlst = compbl(varlst)||trim(v(i));
				end;
				call symput("&_varlst_",compbl(varlst));
			end;
		run;

		%if %upcase(&distinct)=YES %then %do;
			%work_clean(&_dsn);
		%end;
	%end;

	%exit:
%mend var_to_list;

%macro _example_var_to_list;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dummy;
	%put;
	%put (i) Test an empty dataset: returns an error as well;
	%_dstest0;
	%var_to_list(_dstest0, a, _varlst_=dummy, lib=WORK);
	%if %macro_isblank(dummy) %then 	%put OK: TEST PASSED - Empty output and error returned for empty dataset _dstest0;
	%else 								%put ERROR: TEST FAILED - Non-empty output returned for empty dataset _dstest0;

	%put;
	%put (ii) Test a non-empty dataset with missing variable A;
	%_dstest1;
	%var_to_list(_dstest1, a, _varlst_=dummy, lib=WORK);
	%if %macro_isblank(dummy) %then 	%put OK: TEST PASSED - Empty output returned for empty dataset _dstest1;
	%else 								%put ERROR: TEST FAILED - Non-empty output returned for empty dataset _dstest1;

	%local val oval;
	%put;
	%put (iii) Retrieve the list of (NUMERIC) values stored in dataset #28 with missing (NUMERIC) values;
	%_dstest28;
	%*ds_print(_dstest28);
	%let oval=1 2 3 4;
	%var_to_list(_dstest28, value, _varlst_=val, lib=WORK);
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List of VALUE returned for _dstest28: &oval;
	%else 							%put ERROR: TEST FAILED - Wrong list of VALUE returned for _dstest28: &val;

	%local val oval;
	%put;
	%put (iv) Same operation on dataset #28, but also including missing observations using the option NA_RM;
	%_dstest28;
	%let oval=1 . 2 3 . 4;
	%var_to_list(_dstest28, value, _varlst_=val, na_rm=no, lib=WORK);
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List of (missing or not) VALUE returned for _dstest28: &oval;
	%else 							%put ERROR: TEST FAILED - Wrong list of (missing or not) VALUE returned for _dstest28: &val;

	%local val oval;
	%put;
	%put (v) Same operation passing this time var as a varnum position, instead of a field: varnum=2;
	%_dstest28;
	%var_to_list(_dstest28, 2, _varlst_=val, na_rm=no, lib=WORK);
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List of (missing or not) returned for varnum=2 in _dstest28: &oval;
	%else 							%put ERROR: TEST FAILED - Wrong list of (missing or not) for varnum=2 in _dstest28: &val;

	%local ctry octry;
	%put;
	%put (vi) Retrieve the list of (CHAR) GEO countries stored in dataset #29 with missing (char) values;
	%_dstest29;
	%*ds_print(_dstest29);
	%let octry=BE AT BG FR IT;
	%var_to_list(_dstest29, geo, _varlst_=ctry, lib=WORK);
	%if &ctry EQ &octry %then 		%put OK: TEST PASSED - GEO list returned for _dstest30: &octry;
	%else 							%put ERROR: TEST FAILED - Wrong GEO list returned for _dstest30: &ctry;

	%put;
	%put (vii) Retrieve the list of (NUMERIC) values stored in dataset #30;
	%_dstest30;
	%var_to_list(_dstest30, value, _varlst_=val, lib=WORK);
	%let oval=0 0.1 0.2 0.3 0.4 0.5;
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List of VALUE returned for _dstest30: &oval;
	%else 							%put ERROR: TEST FAILED - Wrong list of VALUE returned for _dstest30: &val;

	%put;
	%put (viii) Retrieve the list of distinct (NUMERIC) RB050A values stored in dataset #35;
	%_dstest35;
	%var_to_list(_dstest35, RB050a, _varlst_=val, distinct=yes, lib=WORK);
	%let oval=10 20;
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List of distinct VALUE returned for _dstest35: &oval;
	%else 							%put ERROR: TEST FAILED - Wrong list of distinct VALUE returned for _dstest35: &val;

	%put;
	%put (ix) Same operation passing this time var as a varnum position, instead of a field: varnum=2;
	%_dstest35;
	%var_to_list(_dstest35, 4, _varlst_=val, distinct=yes, lib=WORK);
	%if &val EQ &oval %then 		%put OK: TEST PASSED - List of distinct VALUE returned for _dstest35: &oval;
	%else 							%put ERROR: TEST FAILED - Wrong list of distinct VALUE returned for _dstest35: &val;

	%put;

	/* clean your shit... */
	%work_clean(_dstest0,_dstest1,_dstest28,_dstest29,_dstest30,_dstest35);
%mend _example_var_to_list;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_to_list; 
*/

/** \endcond */
