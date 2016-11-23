## error_handle {#sas_error_handle}
Check for errors and set status code and messages

	%let err=%error_handle(i_errcode, i_cond, mac=, txt=, verb=no);

### Arguments
* `i_errcode` : error code unique to the calling macro;
* `i_cond` : condition - logical expression, will be evaluated and returned by the macro;
	when evaluated as true, status is set to error;
* `mac` : (_option_) name of macro where error condition occured; default: not used;
* `txt` : (_option_) error message, further information will be issued to the SAS log;
	default: no customised error message displayed;
* `verb` : (_option_) verbose mode - parameter (`yes/no/err/warn`) used to issue message to 
	the SAS log even if `i_cond` evaluates to false (`yes`), in case of error only (`err`)
	or none (`no`); default is `err`.

### Returns
`err` : evaluated condition `i_cond`, either:
		+ 1 (error detected, condition above `cond` is true),
		+ 0 (no error, condition above `cond` is false).

### Description
If the condition `i_cond` is true, a message is being issued to the SAS log and the 
following macro variables are assigned:
* `G_PING_ERROR_MACRO` (calling macro program where the error occurred) <- value of `mac` 
	or `UNKNOWN`,
* `G_PING_ERROR_CODE`(error code) <- value of `i_errcode`, 
* `G_PING_ERROR_MSG` <- value of `txt` (error message) or empty,

otherwise these macro variables are reset.
They should be defined as `global` elsewhere (_e.g._, when setting default environment 
variables).

The calling program should determine the name of the macro program currently running 
with the following line of code at the top of the program: 

	%local l_macname; 
	%let l_macname = &sysmacroname;

Do not use `&sysmacroname` as the value of macro parameter `G_PING_ERROR_MACRO` directly, 
because it will have a value of `error_handle` (_i.e._, name of this macro).

If `verb` has value `yes`, a message is being written to the SAS log even when `i_errcode` 
is not a true condition.

### Examples

	%let l_macname=&sysmacroname;
	%let var = 1;
	%let cond=&var NE 0;
	%let text=var is not 0;
	%let res=%error_handle(ErrorDummy, &cond, mac=&l_macname, txt=&text); 

returns `res=1` and displays the following error message:

	ERROR(EUSILC): ErrorDummy in macro _EXAMPLE_ERROR_HANDLE
	var is not 0

while evaluating the same condition on a different variable:

	%let var = 0;
	%let cond=&var NE 0;
	%let res=%error_handle(ErrorDummy, &cond, mac=&l_macname, txt=&text, &text, verb=yes); 

returns `res=0` and displays (because of the verbose mode) the following `OK` message:

	OK(EUSILC): No ErrorDummy in macro _EXAMPLE_ERROR_HANDLE (cond.: 0 NE 0)

Run macro `%%_example_error_handle` for more examples.

### Note
**This program is adapted from the macro `_handleError` distributed in `SASUnit` framework 
(the Unit testing framework for SAS programs, under GPL license...) into SPRING framework.**
For further information, refer to <https://sourceforge.net/p/sasunit/wiki/User%27s%20Guide/>

### Reference
Wilson, S.A. (2011): ["The validator: A macro to validate parameters"](http://support.sas.com/resources/papers/proceedings11/015-2011.pdf).
 
### See also
[%macro_isblank](@ref sas_macro_isblank).
