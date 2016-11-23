/** 
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
*/ /** \cond */

%macro error_handle(i_errcode 	/* String defining an error code 											(REQ) */
					, i_cond 	/* Condition/expressed evaluated to test whether there is an error or not 	(REQ) */
					, mac=		/* Name of the macro where the test is operated 							(OPT) */
					, txt=		/* Text to display with the error/warning message  							(OPT) */
					, verb=err	/* Flag used to define the display mode 									(OPT) */
					);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %symexist(G_PING_PROJECT) %then 	%let project=&G_PING_PROJECT;
	%else							%let project=EUSILC; /* our own default... */

	/* reset the (global) error variables */
	%let G_PING_ERROR_CODE=;
	%let G_PING_ERROR_MSG=;

	/* define the macro message */
	%if "&mac" ne "" %then 	%let mactxt=in &mac.%str( );
	%else 					%let mactxt=;

	%local mssg; /* intermediary message string */
	%let verb=%upcase(&verb);

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	/* evaluate the expression passed through COND */
	%if &i_cond %then %do;
	%*if %unquote(&i_cond) %then %do;
	   	%if &verb=ERR or &verb=YES or &verb=WARN %then %do;
		   	%put;
		   	%put --------------------------------------------------------------------------;
			%if &verb=ERR %then					%let mssg=ERROR;
			%else %if &verb=WARN %then 			%let mssg=WARNING;
			%else /* %if &verb=YES %then */		%let mssg=NOTE;			
			%put 	&mssg(&project): &i_errcode &mactxt (cond.: &i_cond);
		   	%if "&txt" ne "" %then %put &txt;
		   	%put --------------------------------------------------------------------------;
		   	%put;
	   	%end;
		%let G_PING_ERROR_CODE=&i_errcode;
	   	%let G_PING_ERROR_MSG=&txt;
	   	%if "&mac" ne "" %then 					%let G_PING_ERROR_MACRO=&mac;
		%else 									%let G_PING_ERROR_MACRO=UNKNOWN;
	   	1
	%end;
	%else %do;
	   	%if &verb=YES %then %do;
		   	%put;
	      	%put NOTE(&project): No &i_errcode &mactxt.(cond.: &i_cond);
		   	%put;
	   	%end;
	   	0
	%end;

%mend error_handle;

%macro _example_error_handle;
	%local var macname errcode verb;
	%let macname=&sysmacroname;
	%let verb=yes;
	%let errcode=ErrorDummy; /* why not... */

	%let var = 1;
	%let cond=&var NE 0;
	%let text=var:&var is not 0;
	%put;
	%put (i) test: &text;
	%if %error_handle(&errcode, &cond, mac=&macname, txt=&text, verb=&verb) %then 	
		%put OK: TEST PASSED - True condition (1<>0) tested: errcode 1;
	%else 														
		%put ERROR: TEST FAILED - True condition (1<>0) tested: errcode 0;

	%let var = 0;
	%let cond=&var NE 0;
	%let text=var:&var is not 0;
	%put;
	%put (ii) test: &text;
	%if %error_handle(&errcode, &cond, mac=&macname, txt=&text, verb=&verb) %then 	
		%put ERROR: TEST FAILED - False condition (0<>0) tested: errcode 1;
	%else 														
		%put OK: TEST PASSED - False condition (0<>0) tested: errcode 0;

	%let var=' ';
	%let cond=&var EQ ' ' or &var EQ " " or &var EQ;
	%let text=var:&var is empty;
	%put;
	%put (iii) test: &text;
	%if %error_handle(&errcode, &cond, txt=&text, verb=&verb) %then 	
		%put OK: TEST PASSED - True condition tested: errcode 1;
	%else 														
		%put ERROR: TEST FAILED - True condition tested: errcode 0;

	%put;
%mend _example_error_handle;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_error_handle; 
*/

/** \endcond */
