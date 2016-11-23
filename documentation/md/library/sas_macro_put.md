## macro_put {#sas_macro_put}
Display text from inside a macro.

	%macro_put(macro, txt=, debug=);

### Example
let us declare a dummy macro as:

	%macro dummy;
		%local _mac;
		%let _mac=&sysmacroname;
		%macro_put(&_mac, txt=A dummy text, debug=1);
	%mend;

then running the command:

	%dummy;

will display:

	--------------------------------------------------------------------------
	In macro DUMMY - A dummy text
	--------------------------------------------------------------------------

Run `%%_example_macro_put` for more examples.

### Notes
1. As stated, the macro `%%macro_put` shall be used inside another macro only.
2. Since this macro uses the macros `%%error_handle` and `%%macro_isblank`, these macros 
should not use any instance of `%%macro_put` so as to avoid recursion (like _"un espece 
de grand trou noir"_). 
