/** 
## digits {#sas_digits}
Return the number of digits necessary to represent a NUMERIC value.

	%let digs=%digits(value);

### Argument
`value` : input numeric value to represent.

### Returns
`digs` : the number of digits (in base 10) necessary to represent the number `value`.

### Examples
The simple runs:

	%let dig1=%digits(10);
	%let dig2=%digits(999.4);

return `dig1=2` and `dig2=3` respectively.

Run macro `%%_example_digits` for more examples.

### Notes
1. In short, the macro simply returns:

        %sysevalf(%sysfunc(floor(%sysfunc(log(&value))/%sysfunc(log(10)) + 1)));
2. This macro can be useful to encode and/or (re)format variables in a table, _e.g._ by
finding the maximum value or the number of occurrences of the variables in the table.
*/ /** \cond */


%macro digits(value /* Numeric value whose digits are returned (REQ) */
			);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter,	
			%par_check(&value, type=NUMERIC) NE 0, mac=&_mac,
			txt=%quote(!!! Wrong input parameter %upcase(&value): must be NUMERIC !!!)) %then
		%goto exit;

	%sysevalf(%sysfunc(floor(%sysfunc(log(&value))/%sysfunc(log(10)) + 1)))

	%exit:
%mend digits;

%macro _example_digits;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (ii) Dummy test on non numeric parameter; 
	%if %macro_isblank(%digits(A)) %then 	%put OK: TEST PASSED - Macro fails for dummy input; 	
	%else 									%put ERROR: TEST PASSED - Macro passes for dummy input; 

	%local x;

	%let x=10;
	%put;
	%put (ii) Test number of digits required to represent &x;
	%if %digits(&x) = 2 %then 		%put OK: TEST PASSED - Number of digits returned: 2; 	
	%else 							%put ERROR: TEST PASSED - Wrong number of digits returned; 

	%let x=100;
	%put;
	%put (iii) Test number of digits required to represent &x;
	%if %digits(&x) = 3 %then 		%put OK: TEST PASSED - Number of digits returned: 3; 	
	%else 							%put ERROR: TEST PASSED - Wrong number of digits returned; 

	%let x=101;
	%put;
	%put (iv) Test number of digits required to represent &x;
	%if %digits(&x) = 3 %then 		%put OK: TEST PASSED - Number of digits returned: 3; 	
	%else 							%put ERROR: TEST PASSED - Wrong number of digits returned; 

	%let x=999;
	%put;
	%put (v) Test number of digits required to represent &x;
	%if %digits(&x) = 3 %then 		%put OK: TEST PASSED - Number of digits returned: 3; 	
	%else 							%put ERROR: TEST PASSED - Wrong number of digits returned; 

	%let x=999.999;
	%put;
	%put (v) Test number of digits required to represent &x;
	%if %digits(&x) = 3 %then 		%put OK: TEST PASSED - Number of digits returned: 3; 	
	%else 							%put ERROR: TEST PASSED - Wrong number of digits returned; 

	%let x=1000;
	%put;
	%put (vi) Test number of digits required to represent &x;
	%if %digits(&x) = 4 %then 		%put OK: TEST PASSED - Number of digits returned: 4; 	
	%else 							%put ERROR: TEST PASSED - Wrong number of digits returned; 

	%put;
%mend _example_digits;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_digits; 
*/
