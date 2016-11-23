/** 
## label_zip {#sas_label_zip}
Zip items from a start and end item list following inclusion/exclusion rules so as to correspond to 
the formatted categories of a single label.

	%let cat=%label_zip(start, end, sexcl=, eexcl=, type=, sep=%str( ));

### Arguments
* `start` : (list of) starting item(s), _i.e._ the lower bound of values to consider in the categories
	of a label;
* `end` : (list of) ending item(s), _i.e._ the upper bound of category; must be the same length as 
	`start` above; the items in `end` are possibly equals to those in `start` when a single value is 
	to be considered;
* `sexcl` : (_option_) list of boolean flag(s) (`Y/N`) set to exclude items from the starting list;
	when the item in i-th position in `sexcl` is set to `Y`, then the item in the same position in 
	`start` will be excluded from the label (_i.e._ regarded as lower bound); when set, must be the 
	same length as `start` above; default: not set, as if it was set to `N` for all items in `start`;
* `eexcl` : (_option_) ibid for excluding items of the ending list from the categories associated to
	the label; default: not set, as if it was set to `N` for all items in `end`;
* `type` : (_option_) flag set to the type of the considered lists, _i.e._ either numeric (`N`) or 
	char (`C`); default: 'N', _i.e._ the lists are processed as if they were of NUMERIC type;
* `sep` : (_option_) character/string separator in input list; default: `%%str( )`.
 
### Returns
`cat` : concatenated list (_i.e._, comma-separated whenever the length of input `start` and `end` 
	lists is >1) of items zipped from `start` and `end`; when considering lists of length 1, say it
	otherwise: `start=s` and `end=e`, then the zipping rule writes:
		* `s` if `s=e`, or
		* `s-e` if `s<>e` and `sexcl=N, eexcl=N`, or
		* `s<-e` if `s<>e` and `sexcl=Y, eexcl=N`, or
		* `s-<e` if `s<>e` and `sexcl=N, eexcl=Y`, or
		* `s<-<e` if `s<>e` and `sexcl=Y, eexcl=Y`,

	if the label if of type 'N'. This can be easily extended for labels of type 'C', and extrapolated
	for lists of length >1 so as to be read like a category label.

### Examples
Given two NUMERIC start/end lists and the corresponding exclusion rules:

	%let start= 1  2  4     3  8;
	%let end=   1  2  HIGH  5  10;
	%let sexcl= N  N  Y     Y  N;
	%let eexcl= N  N  N     Y  N;

it is possible to retrieve the categorisation of the derived label using:

	%let cat=%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl);

which returns `cat=1, 2, 4<-HIGH, 3<-<5, 8-10`.	In the case of a CHAR lists, we can run:

	%let start=000 OTHER 1 A B;
	%let end=&start;
	%let cat=%label_zip(&start, &end, type=C);		

which returns `cat=`"000", "OTHER", "1", "A", "B".

Run macro `%%_example_label_zip` for more examples.

### Notes
1. This can be used to define the unique categorization associated to a single label. Say it otherwise,
given the format `myformat` below, with one label `A` only, stored in a table `TMP`:

	PROC FORMAT library=WORK.formats cntlout=TMP;	
  		VALUE myformat 
			1-3, 5, 10<-HIGH = "A";
	run;
It is then possible to retrieve the categorisation of `A` since the following commands:

	%let start=; %let end=; %let sexcl=; %let eexcl;
	%var_to_list(TMP, START, _varlst_=start);
	%var_to_list(TMP, END, _varlst_=end);
	%var_to_list(TMP, SEXCL, _varlst_=sexcl);
	%var_to_list(TMP, EEXCL, _varlst_=eexcl);
	%let list=%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl);		
will return `list=1-3, 5, 10<-HIGH`. 
2. Note the following possible use of `%%list_` based macros:

	   %let labels=%list_append(
				%list_append(
					%list_sequence(start=1, end=36, step=5), 
					%list_sequence(start=5, end=40, step=5), 
					zip=%str(-)
					), 
				%list_quote(
					%list_append(
						%list_ones(%list_length(&start), item=Y), 
						%list_append(&start, &end, zip=%str(_)),
						zip=_EMPTY_
						),
					rep=_BLANK_
					), 
				zip=%str(=)
				);
which returns `labels=`1-5="Y1_5" 6-10="Y6_10" 11-15="Y11_15" 16-20="Y16_20" 21-25="Y21_25" 26-30="Y26_30" 31-35="Y31_35" 36-40="Y36_40".

### References
Smiley, C.A. (1999): ["A fast format macro – How to quickly create a format by specifying the endpoints"](http://www2.sas.com/proceedings/sugi24/Coders/p096-24.pdf).

### See also
[%list_append](@ref sas_list_append), [PROC FORMAT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473464.htm).
*/ /** \cond */

%macro label_zip(start 		/* Lower bound of a category/range of a label 					(REQ) */
				, end		/* Upper bound of a category/range of a label 					(REQ) */
				, sexcl=	/* Boolean flag set to exclude start from the category/range 	(OPT) */
				, eexcl=	/* Boolean flag set to exclude end from the category/range 		(OPT) */
				, type=		/* Type of the label 											(OPT) */
				, sep=		/* character/string used as list separator 						(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	/* initialisation of the output list */
	%local zip;		
	%let zip=;

	/* some basic checkings/settings */
	%if %macro_isblank(type) %then 	%let type=N;
	%if %error_handle(ErrorInputParameter, 
			%par_check(&type, type=CHAR, set=N C) NE 0, mac=&_mac,	
			txt=!!! Parameter TYPE must be a character set to either N or C !!!) %then
		%goto exit;

	%if %upcase(&type)=C %then %do;
		%if %error_handle(ErrorInputParameter,
				&start NE &end, mac=&_mac,
				txt=!!! Input lists START and END must be identical with CHAR type !!!) %then
			%goto exit;
	%end;

	%if %macro_isblank(sep) %then 	%let sep=%str( );

	%local _i 			/* loop counter */
		s 				/* starting item */
		e 				/* ending item */
		ee 				/* end excluding item */
		se 				/* start excluding item */
		SYM_INCL_EXCL 	/* symbol for lower inclusion - upper exclusion */
		SYM_EXCL_INCL 	/* symbol for lower exclusion - upper inclusion */ 
		SYM_EXCL_EXCL 	/* symbol for lower exclusion - upper exclusion */
		SYM_INCL_INCL 	/* symbol for lower inclusion - upper inclusion */
		_lstart			/* length of start */
		_lend 			/* length of end */
		_lsexcl 		/* length of sexcl */
		_leexcl			/* length of eexcl */
		z;				/* temporary item of the output list */

	%let SYM_INCL_EXCL=-<;
	%let SYM_EXCL_EXCL=<-<;
	%let SYM_EXCL_INCL=<-;
	%let SYM_INCL_INCL=-;

	%let _lstart=%list_length(&start);
	%let _lend=%list_length(&end);

	/* further checkings */
	%if %error_handle(ErrorInputParameter,
			&_lstart NE &_lend, mac=&_mac,
			txt=!!! Input START and END lists must have same size !!!) %then
		%goto exit;

	%if %macro_isblank(sexcl)	%then 	%let sexcl=%list_ones(&_lstart, item=N);
	%let _lsexcl=%list_length(&sexcl);
	%if %macro_isblank(eexcl)	%then 	%let eexcl=%list_ones(&_lstart, item=N);
	%let _leexcl=%list_length(&eexcl);

	%if %error_handle(ErrorInputParameter,
			&_lstart NE &_lsexcl or &_lstart NE &_leexcl, mac=&_mac,
			txt=!!! Input lists SEXCL and EEXCL must have same size as START and END !!!) %then
		%goto exit;

	/* actually build the categories */
	%do _i=1 %to &_lstart;
		/* scan all values */
		%let s = %list_index(&start, &_i, sep=&sep);
		%let e = %list_index(&end, &_i, sep=&sep);
		%let se = %list_index(&sexcl, &_i, sep=&sep);
		%let ee = %list_index(&eexcl, &_i, sep=&sep);

		%if %error_handle(ErrorInputParameter,
				&s EQ &e and (%upcase("&se") EQ "Y" or %upcase("&ee") EQ "Y"), mac=&_mac,
				txt=! START=END item while SEXCL=Y or EEXCL=Y: item ignored !) %then
			%goto next;
		
		/* format depending on inclusion/exclusion of start/end values */
		%if "&s" EQ "&e" %then %do;
			%let z = &s;
		%end;	
		%else %if %upcase("&se") EQ "Y" %then %do;
			%if %upcase("&ee") EQ "Y" %then
				%let z = &s.&SYM_EXCL_EXCL.&e;
			%else 
				%let z = &s.&SYM_EXCL_INCL.&e;
		%end;
		%else %if %upcase("&ee") EQ "Y" %then %do;
			%let z = &s.&SYM_INCL_EXCL.&e;
		%end;
		%else %do;
			%let z = &s.&SYM_INCL_INCL.&e;
		%end;

		/* case of CHAR label */
		%if %upcase(&type)=C %then  	%let z="&z"; 

		/* append to the output list */
		%if %macro_isblank(zip)	%then 	%let zip=&z;
		%else							%let zip=&zip, &z;

		%next:
	%end;

	/* return the appended list */
	%exit:
	&zip
%mend label_zip;


%macro _example_label_zip;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local start end sexcl eexcl;

	%put;
	%let start=1 2 4 3;
	%let end=  1 2 4 5 6;
	%put (i) Crash test...;
	%if %macro_isblank(%label_zip(&start, &end)) %then	%put OK: TEST PASSED - Input error detected, empty result;
	%else 												%put ERROR: TEST FAILED - Input error not detected;

	%put;
	%let start=1 2 4 3;
	%let end=  1 2 4 5;
	%put (ii) Test start=&start and end=&end ...;
	%let res=1, 2, 4, 3-5;
	%if %quote(%label_zip(&start, &end))=%quote(&res) %then	
		%put OK: TEST PASSED - Formatted NUMERIC label returns &res;
	%else 													
		%put ERROR: TEST FAILED - Wrong formatted NUMERIC label returned;

	%put;
	%let sexcl=N N N N;
	%let eexcl=N N N N;
	%put (iii) Same test with additional sexcl=&sexcl and eexcl=&eexcl (no difference) ...;
	%if %quote(%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl))=%quote(&res) %then		
		%put OK: TEST PASSED - Formatted NUMERIC label returns &res;
	%else 										
		%put ERROR: TEST FAILED - Wrong formatted NUMERIC label returned;

	%put;
	%let sexcl=N N N Y;
	%let eexcl=N N N N;
	%put (iv) Same test with additional sexcl=&sexcl and eexcl=&eexcl ...;
	%let res=1, 2, 4, 3<-5;
	%if %quote(%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl))=%quote(&res) %then		
		%put OK: TEST PASSED - Formatted NUMERIC label returns &res;
	%else 										
		%put ERROR: TEST FAILED - Wrong formatted NUMERIC label returned;

	%put;
	%let sexcl=N N N Y;
	%let eexcl=N N N Y;
	%put (v) Same test with additional sexcl=&sexcl and eexcl=&eexcl ...;
	%let res=1, 2, 4, 3<-<5;
	%if %quote(%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl))=%quote(&res) %then		
		%put OK: TEST PASSED - Formatted NUMERIC label returns &res;
	%else 										
		%put ERROR: TEST FAILED - Wrong formatted NUMERIC label returned;

	%put;
	%let start=000 OTHER 1 A B;
	%let end=&start;
	%put (vi) Test with a CHAR label given by start=end=&start ...;
	%let res="000", "OTHER", "1", "A", "B";
	%if %quote(%label_zip(&start, &end, type=C))=%quote(&res) %then		
		%put OK: TEST PASSED - Formatted CHAR label returns &res;
	%else 										
		%put ERROR: TEST FAILED - Wrong formatted CHAR label returned;

	%put;
	%let start=1 LOW 4;
	%let end=  1 2   HIGH;
	%put (vii) New test with start=&start and end=&end ...;
	%let res=1, LOW-2, 4-HIGH;
	%if %quote(%label_zip(&start, &end))=%quote(&res) %then		
		%put OK: TEST PASSED - Formatted label returns &res;
	%else 										
		%put ERROR: TEST FAILED - Wrong formatted label returned;

	%put;
	%let sexcl=N N Y;
	%let eexcl=N Y N;
	%put (viii) Same test with additional sexcl=&sexcl and eexcl=&eexcl ...;
	%let res=1, LOW-<2, 4<-HIGH;
	%if %quote(%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl))=%quote(&res) %then		
		%put OK: TEST PASSED - Formatted label returns &res;
	%else 										
		%put ERROR: TEST FAILED - Wrong formatted label returned;

	%local dsn;
	%let dsn=TMP%upcase(&sysmacroname);

	%*work_clean;
	PROC FORMAT library=WORK.formats cntlout=&dsn;	
  		VALUE myformat
			1-3, 5, 10<-HIGH = "A"
			/* 0-2, 3-5, LOW-10 = "B" */
			;
	run;
	/* we can possibly view the content of the catalog:
		PROC CATALOG c = WORK.formats; CONTENTS stat;
		run;
	*/
	/* if we had more labels in the format "myformat", we would consider one label at once, e.g.: 
		%let where=%quote(FMTNAME="MYFORMAT" & LABEL="A");
		%ds_select(&dsn, START END SEXCL EEXCL, &dsn, where=&where);
	*/
	%ds_print(&dsn);

	%local start end sexcl eexcl;
	%var_to_list(&dsn, START, _varlst_=start);
	%var_to_list(&dsn, END, _varlst_=end);
	%var_to_list(&dsn, SEXCL, _varlst_=sexcl);
	%var_to_list(&dsn, EEXCL, _varlst_=eexcl);
	%put;
	%put (viii) Test derived from a label catalog...;
	%let res=1-3, 5, 10<-HIGH;
	%if %quote(%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl))=%quote(&res) %then		
		%put OK: TEST PASSED - Formatted label returns &res;
	%else 										
		%put ERROR: TEST FAILED - Wrong formatted label returned;

	%put;

	%work_clean(&dsn);
	%work_clean(formats);
%mend _example_label_zip;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_label_zip; 
*/

/** \endcond */
