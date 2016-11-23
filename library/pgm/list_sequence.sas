/** 
## list_sequence {#sas_list_sequence}
Generate a list of linearly spaced NUMERIC values as an arithmetic progression.

	%let seq=%list_sequence(len=, start=, step=, end=, sep=%quote( ));

### Arguments
* `len` : (_option_) lenght of the output generated list; it can be omitted if and only if all 
	other options below (_e.g._, `start`, `end` and `step`) are present, and then it is set to 
	`floor[(end - start)/ step + 1]`;
* `start` : (_option_) starting value of the generated list, _i.e._ the first element in the 
	output list will be `start`; default: `start=1`; when omitted, it is set to:
			+ `end - step * (len-1)` when all other options are present,
			+ `1` otherwise;
* `step` : (_option_) "step" between the items in the generated list, _i.e._ the difference/space 
	between two consecutive items in the output list will be equal to `step`; step must be non-zero; 
	when omitted, it is set to:
			+ `(end-start)/(len-1)` when all other options are present,
			+ `1` otherwise;
	further note that `step` is "forced" to 1 when `start` and `end` are passed, but `len` is not;
* `end` : (_option_) ending value of the generated list; note that depending on the other settings 
	(_e.g._, `len`, `start` and `step`), the last element in the output list will not necessary be 
	equal to `end`; when omitted, it is set to: `start + (len - 1) * step`;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` 
	is blank.
 
### Returns
`seq` : output arithmetic list of evenly spaced items of lenght `len` and of the form 
	`start start+step start+2*step ...`. 

### Examples
The following examples:

	%let seq1=%list_sequence(len=10);
	%let seq2=%list_sequence(len=10, start=10);
	%let seq3=%list_sequence(len=10, end=20, step=2);
	
return `seq1=1 2 3 4 5 6 7 8 9 10`, `seq2=10 12 13 14 15 16 17 18 19 20`, and 
`seq3=2 4 6 8 10 12 14 16 18 20`, respectively, while:

	%let seq4=%list_sequence(len=10, start=10, step=-1);
	%let seq5=%list_sequence(len=10, end=10, step=-1);

return `seq1=10 9 8 7 6 5 4 3 2 1` and `seq2=19 18 17 16 15 14 13 12 11 10`. Note also that:

	%let seq6=%list_sequence(start=1, end=20, step=3);

will return `seq1=1 4 7 10 13 16 19`, hence excluding 20 from the list.

Run macro `%%_example_list_sequence` for examples.

### Notes
1. When `step` is positive (resp. negative), the last element in the output list is the largest
value `start + i * step` that is less (resp. greater) than or equal to `end`.
2. This macro is obviously inspired by the [`linspace`](http://nl.mathworks.com/help/matlab/ref/linspace.html) 
and [`colon, :`](http://nl.mathworks.com/help/matlab/ref/colon.html) operators in Matlab, and 
[`xrange`](https://docs.python.org/2/library/functions.html#range) operator in Python. 

### See also
[%list_permutation](@ref sas_list_permutation), [%list_length](@ref sas_list_length), 
[%list_count](@ref sas_list_count).
*/ /** \cond */

%macro list_sequence(len=		/* Lenght of the output generated list 									(OPT) */
					, start=	/* Starting value of the output generated list 							(OPT) */
					, step=		/* Even space between the consecutive elements of the generated list 	(OPT) */
					, end=		/* Ending value of the output generated list 							(OPT) */
					, sep=		/* Character/string used as list separator 								(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(sep) %then 	%let sep=%quote( ); /* list separator */

	%local isbl_len /* boolean flag result of the 'blank' test of LEN variable */
		isbl_start 	/* ibid for START variable */
		isbl_end 	/* ibid for END variable */
		isbl_step	/* ibid for STEP variable */
		_i			/* increment number */	
		_list; 		/* list returned */

	/* set default output to empty */
	%let _list=;

	/* check all passed parameters */
	%let isbl_len=%macro_isblank(len);
	%let isbl_start=%macro_isblank(start);
	%let isbl_end=%macro_isblank(end);
	%let isbl_step=%macro_isblank(step);

	/* special case: START and END are passed, force STEP to 1 */
	%if &isbl_len EQ 1 and &isbl_step EQ 1 and &isbl_start EQ 0 &isbl_end EQ 0 %then %do;
		%let step=1;
	%end;	
	
	/* if LEN is not passed, all other parameters should be */
	%if %error_handle(ErrorInputParameter, 
			&isbl_len EQ 1 and %eval(&isbl_start + &isbl_end + &isbl_step) GT 1, mac=&_mac,		
			txt=%quote(!!! Parameters START, END and STEP need all to be set when LEN is not !!!)) %then
		%goto exit;

	/* check the setting of LEN when passed */
	%if &isbl_len NE 1 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&len, type=INTEGER, range=0) NE 0, mac=&_mac,		
				txt=!!! Wrong input %upcase(&len) value: must be INTEGER >0 !!!) %then
			%goto exit;
	%end;
	/* check the setting of START when passed */
	%if &isbl_start NE 1 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&start, type=NUMERIC) NE 0, mac=&_mac,		
				txt=!!! Wrong input %upcase(&start) value: must be NUMERIC !!!) %then
			%goto exit;
	%end;
	/* check the setting of END when passed */
	%if &isbl_end NE 1 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&end, type=NUMERIC) NE 0, mac=&_mac,		
				txt=!!! Wrong input %upcase(&end) value: must be NUMERIC !!!) %then
			%goto exit;
	%end;
	/* check the setting of STEP when passed */
	%if &isbl_step NE 1 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&step, type=NUMERIC, noset = 0) NE 0, mac=&_mac,		
				txt=!!! Wrong input %upcase(&step) value: must be NUMERIC non null !!!) %then
			%goto exit;
	%end;

	%if &isbl_step NE 1 and &isbl_start NE 1 and &isbl_end NE 1 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%sysevalf(&step < 0) and %sysevalf(&start < &end), mac=&_mac,		
				txt=!!! Wrong setting: START must be > END when STEP < 0 !!!) %then
			%goto exit;
	%end;

	/* set default values */
	%if &isbl_len EQ 0 %then %do;
		%if &isbl_step EQ 1 %then %do;
			%if &isbl_start EQ 1 or &isbl_end EQ 1 %then 	%let step=1;
			%else 											%let step=%sysevalf((&end - &start) / (&len - 1)); 
		%end; 
		%if &isbl_start EQ 1 %then %do;
			%if &isbl_end EQ 1 %then						%let start=1;
			%else 											%let start=%sysevalf(&end - &step * (&len - 1));
		%end; 
		%if &isbl_end EQ 1 %then 							%let end=%sysevalf(&start + (&len - 1) * &step); 	
	%end;
	%else /* %if &isbl_len EQ 1 %then */ %do;
		%let len= %sysevalf((&end - &start)/&step + 1, floor);
	%end;

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	/* build the sequence */
	%let _list=&start;
	%do _i=1 %to %eval(&len-1);
		%let _list=&_list.&sep.%sysevalf(&start + &_i * &step);
	%end;

	%exit:
	&_list
%mend list_sequence;


%macro _example_list_sequence;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local len olist;

	%put;
	%put (i) Test with dummy parameters: LEN=-1;
	%if %macro_isblank(%list_sequence(len=-1)) %then 	%put OK: TEST PASSED - Dummy test fails;
	%else 												%put ERROR: TEST FAILED - Dummy test passed;

	%put;
	%put (ii) Test with dummy parameters: START=5, END=10, STEP=-1;
	%if %macro_isblank(%list_sequence(start=5, end=10, step=-1)) %then 	%put OK: TEST PASSED - Dummy test fails;
	%else 																%put ERROR: TEST FAILED - Dummy test passed;

	%let len=10;
	%put;
	%put (iii) Create a simple sequence with LEN=&len and default parameters;
	%let olist=1 2 3 4 5 6 7 8 9 10;
	%if %quote(%list_sequence(len=&len))=%quote(&olist) %then 	%put OK: TEST PASSED - Correct list returned: &olist;
	%else 													%put ERROR: TEST FAILED - Wrong list returned;

	%let start=-5;
	%put;
	%put (iv) Create a similar sequence with a different START=&start;
	%let olist=-5 -4 -3 -2 -1 0 1 2 3 4;
	%if %quote(%list_sequence(len=&len, start=&start))=%quote(&olist) %then 	
		%put OK: TEST PASSED - Correct list returned: &olist;
	%else 													
		%put ERROR: TEST FAILED - Wrong list returned;

	%let end=20;
	%let step=1;
	%put;
	%put (v) Ibid with END=&end and STEP=&step while ignoring START;
	%let olist=11 12 13 14 15 16 17 18 19 20;
	%if %quote(%list_sequence(len=&len, end=&end, step=&step))=%quote(&olist) %then 	
		%put OK: TEST PASSED - Correct list returned: &olist;
	%else 													
		%put ERROR: TEST FAILED - Wrong list returned;

	%let step=-1;
	%put;
	%put (vi) Ibid with STEP=&step;
	%let olist=29 28 27 26 25 24 23 22 21 20;
	%if %quote(%list_sequence(len=&len, end=&end, step=&step))=%quote(&olist) %then 	
		%put OK: TEST PASSED - Correct list returned: &olist;
	%else 													
		%put ERROR: TEST FAILED - Wrong list returned;

	%let start=20;
	%put;
	%put (vii) Ibid, this time specifying START=&start while ignoring END;
	%let olist=20 19 18 17 16 15 14 13 12 11;
	%if %quote(%list_sequence(len=&len, start=&start, step=&step))=%quote(&olist) %then 	
		%put OK: TEST PASSED - Correct list returned: &olist;
	%else 													
		%put ERROR: TEST FAILED - Wrong list returned;

	%put;
	%let step=2;
	%let start=1;
	%put (viii) Create a sequence in between START=&start and END=&end by STEP=&step;
	%let olist=1 3 5 7 9 11 13 15 17 19; /* note that end is not reached */
	%if %quote(%list_sequence(step=&step, start=&start, end=&end))=%quote(&olist) %then 	
		%put OK: TEST PASSED - Correct list returned: &olist;
	%else 													
		%put ERROR: TEST FAILED - Wrong list returned;

	%put;
	%put (ix) Ibid, setting LEN=&len but ignoring STEP;
	%let olist=1 3.11111111111111 5.22222222222222 7.33333333333333 9.44444444444444 11.5555555555555 13.6666666666666 15.7777777777777 17.8888888888888 19.9999999999999;
	%if %quote(%list_sequence(len=&len, start=&start, end=&end))=%quote(&olist) %then 	
		%put OK: TEST PASSED - Correct list returned: &olist;
	%else 													
		%put ERROR: TEST FAILED - Wrong list returned;

	%put;
	%let len=11;
	%let start=0;
	%put (x) Create the sequence with LEN=&len both START=&start and END=&end this time;
	%let olist=0 2 4 6 8 10 12 14 16 18 20;
	%if %quote(%list_sequence(len=&len, start=&start, end=&end))=%quote(&olist) %then 	
		%put OK: TEST PASSED - Correct list returned: &olist;
	%else 													
		%put ERROR: TEST FAILED - Wrong list returned;

	%put;
%mend _example_list_sequence; 

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_sequence; 
*/

/** \endcond */
