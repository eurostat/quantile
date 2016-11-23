/** 
## macro_isblank {#sas_macro_isblank}
Check whether a macro variable is empty or not.

	%let res=%macro_isblank(var, verb=no);

### Arguments
`var` : name of a variable to evaluate the content of;
`verb` : (_option_) see [%error_handle](@ref sas_error_handle) arguments; default: `no`.

### Returns
`res` : evaluated boolean condition, either true (1) when the variable is blank/not set 
	(_i.e._ when `var` is for instance '', or "", or (), but also "    ", or ' ', ...), 
	or false (0) otherwise.

### Examples

	%let var = 0;
	%let res=%macro_isblank(var); 

returns `res=0`, while running:

	%let var = ;
	%let res=%macro_isblank(var); 

returns `res=1`. Ibid for the following example:

	%let parameter = ' ';
	%let res=%macro_isblank(parameter); 

which returns `res=1`.

Run macro `%%_example_macro_isblank` for more examples.

### Note
1. When using the macro `macro_isblank`, keep in mind the following (arbitrarily chosen) outputs: 
    * variables " ", ' ' and ( ) are considered as empty/blank variables, whatever the number of 'blanks' 
inside the string, _e.g._ "     " is also considered as empty/blank; 
    * on the contrary, single quotes (_i.e._, set to %%str(%") and %%str(%') respectively) are considered 
as NON empty/blank variables.
2. Let us further note that:
	
        %let ans=%macro_isblank();
will return `ans=1`. 

### Note
In the reference [below](#reference), the authors recommend the use of:
	
	%macro isBlank(param);
		%sysevalf(%superq(param)=,boolean)
	%mend isBlank;

while they also evaluate:

	%if &param eq %then ... 
	%if %bquote(&param)= %then ... 
	%if %nrbquote(&param)= %then ... 
	%if %superq(param)= %then ... 
	%if "&param" = "" %then ... 
	%if %length(&param) = 0 %then ... 
	%if %length(%qleft(%qtrim(&param))) = 0 %then ... 

### References
1. Carpenter, A.L. (1997): ["Resolving and using &&var&i macro variables"](http://www2.sas.com/proceedings/sugi22/CODERS/PAPER77.PDF).
2. Carpenter, A.L. (2005): ["Five ways to create macro variables: A short introduction to the macro language"](http://analytics.ncsu.edu/sesug/2005/HW03_05.PDF).
3. Philp, P. (2008): ["SAS MACRO: Beyond the basics"](http://www2.sas.com/proceedings/forum2008/045-2008.pdf).
4. Chang et al.(2009): ["Is this macro parameter blank?"](http://changchung.com/download/022-2009.pdf).
5. Wilson, S.A. (2011): ["The validator: A macro to validate parameters"](http://support.sas.com/resources/papers/proceedings11/015-2011.pdf).

### See also 
[%error_handle](@ref sas_error_handle),
[%SUPERQ](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a000206633.htm).
*/ /** \cond */

%macro macro_isblank(____macro_isblank_parameter 	/* Input variable name to test 				(REQ) */
					, verb=no						/* Boolean flag to defined the verbose mode (OPT) */
					);
	/* note that we use this dummy name in order to ensure that no such name will ever
	 * be passed; indeed if you ever ran:
	 * 		%let ____macro_isblank_parameter=' ';
	 * 		%put %macro_isblank(____macro_isblank_parameter);
	 * the program will not work as expected (it returns 1 then)!!!
	 * We could put the following test: 
	 * 		%if %error_handle(WrongParameterisation, 
	 * 		&____macro_isblank_parameter EQ ____macro_isblank_parameter, 
	 * 		txt=!!! the name of the variable passed as an argument CANNOT BE '____macro_isblank_parameter' !!!) %then;
	 * 			%goto exit;
	 * to ensure everything goes well. However, considering that this is very unlikely, we avoid
	 * this additional test */
	%local ____ans	/* output answer */
		____var 		/* superq variable */
		____cond;		/* existence test */

	%if &____macro_isblank_parameter= %then %do;
		/* what happened here? most likely a blank/empty variable was passed as the output of 
		* another macro, then further evaluation of &____macro_isblank_parameter (through the
		* use of ampersands &&& or through the call to %superq) is at risk.
		* We therefore prevent that command below:	
		* 		%macro_isblank(%clist_unquote((""))) 
		* to generate an error.  We still return 1! 
		*/
		%let ____ans=1;
		%if &verb=yes %then 	%put !!! empty macro variable passed !!!;
		%goto quit;
	%end; 
	
	/* retrieve the variable 'underneath' */

	/* %let _var=&&&__macro_isblank_parameter; */
	%let ____var=%superq(&____macro_isblank_parameter); 

	%if %sysevalf(%superq(____var)=, boolean) %then %do;
		%let ____cond=1;
	%end;
	%else %if &____var EQ %str(%') 
			or &____var EQ %str(%") 
			or &____var EQ %str(%)) 
			or &____var EQ %str(%() %then %do; 
		/* we have problems in the use of compbl below otherwise */
		%let ____cond=0; /* that's our decision: this shall not be considered as empty */
	%end;
	%else %do;
		/* get rid of blanks; note, this will still leave one blank at least */
		%let ____var = %sysfunc(compbl(%quote(&____var))); 
		/* establish the definition of 'blank' variables */
		%let ____cond= %nrbquote(&____var) EQ %str(%'%') 
				or %nrbquote(&____var) EQ %str(%' %') /* because we may still have one blank at least */
				or %nrbquote(&____var) EQ %str(%"%") 
				or %nrbquote(&____var) EQ %str(%" %") /* ibid above */
				or %nrbquote(&____var) EQ %str(%(%))
				or %nrbquote(&____var) EQ %str(%( %)) /* ibid above */
				or %nrbquote(&____var) EQ
				;
	%end;

	/* run the the test */
	%let ____ans=%error_handle(EmptyMacroVariable, 
			&____cond, 
			txt=%bquote(!!! Macro variable &____macro_isblank_parameter needs to be set !!!), verb=&verb);

	%quit:
	&____ans

	%exit: /* not used */
%mend macro_isblank;

%macro _example_macro_isblank;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local var;
	
	%put;
	%put (o) Test empty variable;
	%if %macro_isblank() %then 		%put OK: TEST PASSED - empty variable: 1 returned;
	%else 							%put ERROR: TEST FAILED - empty variable: 0 returned;
	
	%let var=' ';
	%put;
	%put (i) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put OK: TEST PASSED - blank variable: 1 returned;
	%else 							%put ERROR: TEST FAILED - blank variable: 0 returned;

	%let var='  ';
	%put;
	%put (ii) Test variable var=&var and display an ERROR message;
	%if %macro_isblank(var, verb=yes) %then %put OK: TEST PASSED - blank variable: 1 returned;
	%else 									%put ERROR: TEST FAILED - blank variable: 0 returned;

	%let var=;
	%put;
	%put (iii) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put OK: TEST PASSED - blank variable: 1 returned;
	%else 							%put ERROR: TEST FAILED - blank variable: 0 returned;

	%let var="";
	%put;
	%put (iv) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put OK: TEST PASSED - blank variable: 1 returned;
	%else 							%put ERROR: TEST FAILED - blank variable: 0 returned;

	%let var=6;
	%put;
	%put (v) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put ERROR: TEST FAILED - numeric variable: 1 returned;
	%else 							%put OK: TEST PASSED - numeric variable: 0 returned;

	%let var=abc;
	%put;
	%put (vi) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put ERROR: TEST FAILED - char variable: 1 returned;
	%else 							%put OK: TEST PASSED - char variable: 0 returned;

	%let var=a " " 6;
	%put;
	%put (vii) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put ERROR: TEST FAILED - string variable: 1 returned;
	%else 							%put OK: TEST PASSED - string variable: 0 returned;

	%let var=%str(%');
	%put;
	%put (viii) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put ERROR: TEST FAILED - char variable: 1 returned;
	%else 							%put OK: TEST PASSED - char variable: 0 returned;

	%let var=%str(%");
	%put;
	%put (ix) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put ERROR: TEST FAILED - char variable: 1 returned;
	%else 							%put OK: TEST PASSED - char variable: 0 returned;

	%let var=();
	%put;
	%put (x) Test variable var=&var;
	%if %macro_isblank(var) %then 	%put OK: TEST PASSED - blank variable: 1 returned;
	%else 							%put ERROR: TEST FAILED - blank variable: 0 returned;

	%put;
%mend _example_macro_isblank;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_macro_isblank; 
*/

/** \endcond */
