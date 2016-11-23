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
