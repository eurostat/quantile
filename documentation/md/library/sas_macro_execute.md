## macro_execute {#sas_macro_execute}
Execute a macro with its arguments.

	%macro_execute(macro_name, macro_arguments... );
	%let ... =%macro_execute(macro_name, macro_arguments... );

### Arguments
* `macro_name` : name of the macro (whose existence will be checked) to run; if the macro does 
	not exist, do nothing;
* `macro_arguments...` : (_option_) whatever additional (positional or keyword) arguments taken 
	by the macro `%&macro_name`.

### Returns
... whatever the original macro `%&macro_name` returns.

### Note
The macro `%%macro_execute` does not test the actual existence of `macro_name`. 	
Therefore, this macro should be combined together with `%%macro_exist` prior to its use, _e.g._
to be ran as:

 	%macro_exist(&macro_name, _ans_=ans);
	%if %error_handle(ErrorInputParameter, &ans EQ 0, txt=!!! Input macro not found !!!) %then
		%goto exit;
	%else
		%macro_execute(&macro_name, &macro_arguments);

### See also
[%macro_exist](@ref sas_macro_exist), 
[CxMacro](http://www.sascommunity.org/wiki/Routine_CxMacro),
[CxInclud](http://www.sascommunity.org/wiki/Routine_CxInclude),
[CallMacr](http://www.sascommunity.org/wiki/Macro_CallMacr).
