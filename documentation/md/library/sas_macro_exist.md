## macro_exist {#sas_macro_exist}
Verify the existence of a given macro by searching into the set of pre-compiled macros as well
as the content of all autocall libraries.

	%macro_exist(macro_name, _ans_=);

### Argument
`macro_name` : name of the macro to check the existence of; the macro may already be compiled 
	or would be brought in via `autocall`.

### Returns:
`_ans_` : name of the variable storing the result of the test, _e.g._:
		+ 1 when the macro `%%macro_name` is found in the catalog macros compiled for the current 
			session (_e.g._, catalog `WORK.SASMACR` or `WORK.SASMAC1`, see note below),
		+ 2 when it is found in the catalog of pre-compiled macros (_e.g._, catalog `WORK.MSTORE`),
		+ 3 when it is found in set of autocall macros (_i.e._, set through `SASAUTOS`),
		+ 0 otherwise.

### Notes
1. **The macro `%%macro_exist` is  an adaptation of S. Bass's original `%%execute_macro.sas` 
macro, so as to keep only the existence testing**. Original source code (no disclaimer) is 
available at <https://github.com/scottbass/SAS/blob/master/Macro/execute_macro.sas>. 
2. Given a macro name, we determine if it would be executed if invoked:
	- first check to see if it's pre-compiled: if not in compiled form, then 
	- try to locate in the list of all sasautos directories.
See reference 2 below.
3. Note that, with SAS version 9.3, the SAS-supplied macro `%%sysmacexist` checks for the existence 
of a macro in `WORK.SASMACR` and `SOURCE.SASMACR` only.  However, on Linux, esp. in EG, compiled 
macros are saved to `WORK.SASMAC1` instead of `WORK.SASMACR`. For SAS versions prior to 9.3, we 
implemented our own search macro (see reference 3 below).
4. See also R. Langston `%%macro_exists.sas` macro that searches for pre-compiled macros and all
autocall libraries.

### References
1. Langston, R. (2013): ["A macro to verify a macro exists"](http://support.sas.com/resources/papers/proceedings13/339-2013.pdf).
2. Johnson, J. (2010): ["OBJECT_EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).
3. ["How to determine whether a macro exists within a SAS session"](http://support.sas.com/kb/36/360.html).

### See also
[%macro_execute](@ref sas_macro_execute),
[SYSMACEXIST](http://support.sas.com/documentation/cdl/en/mcrolref/62978/HTML/default/viewer.htm#n0xwysoo8i2j3kn13ls4thkn3xbp.htm).
