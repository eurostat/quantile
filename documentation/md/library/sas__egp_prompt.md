## _egp_prompt {#sas__egp_prompt}
Re-create the list of choice(s) from the (multiple) choice(s) prompt in the client SAS EG project
(similar to SAS EG version prior to 4.1).

	%_egp_prompt(prompt_name=, ptype=, penclose=, pmultipl=, psepar=, verb=no);

### Arguments
* `prompt_name` : name of the prompt;                                                              
* `ptype` : (_option_) type of the prompt, _i.e._ `CHAR`, `INTEGER`, `NUMERIC`, `DATE`, etc...;                                
* `penclose` : (_option_) boolean flag (`yes/no`) set if the 'Enclosed values with quotes' 
	was selected in SAS/EG 4.1;                     
* `pmultipl` : (_option_) boolean flag (`yes/no`) if the prompt is a 'Multiple choices' prompt;                                          
* `psepar` : (_option_) specific separator, nothing if there is no specific separator; comma 
	is the default;
* `verb` : (_option_) boolean flag (`yes/no`) set for verbose mode; default: `verb=no`.

### Returns
In the macro variable whose named is passed through `prompt_name` (_i.e._, `&prompt_name`), the 
list of choices from the (multiple) choice(s) prompt.

### Notes
1. The macro `%%_egp_prompt`  uses SAS EG built-in macro `%%_eg_WhereParam`.
2. When working with SAS EG version>4.3 prompts, prompts (may they be numeric or char, multiple 
choices or not) are surrounded by control characters (SOH, DC1, STX) which are not interpreted 
well by the macro processor. A trick is then to apply to reassign the value of the macro variable 
using the `%%strip` macro.
3. This macro was originally implemented (with name `%%prompt_to_list`) by 
<a href="mailto:Sami.OKBI@ext.ec.europa.eu">S.Okbi</a>,  and also further incorporates comments 
from <a href="mailto:Olivier.DE-GRYSE@ext.ec.europa.eu">O.De Gryse</a> (SAS support team). 

### References
1. Sucher, K. (2010): ["Interactive and efficient macro programming with prompts in SAS Enterprise Guide 4.2"](http://support.sas.com/resources/papers/proceedings10/036-2010.pdf).
2. Hall, A. (2011): ["Creating reusable programs by using SAS Enterprise Guide prompt manager"](http://support.sas.com/resources/papers/proceedings11/309-2011.pdf).

### See also
[%_egp_geotime](@ref sas__egp_geotime), [%_egp_path](@ref sas__egp_path).
