/** 
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
*/ /** \cond */

%macro _egp_prompt(prompt_name=	/* Name of the prompt 									(OPT) */
				, ptype=		/* Type of the prompt 									(OPT) */
				, penclose=		/* Boolean flag set for 'Enclosed values with quotes' 	(OPT) */
				, pmultipl=		/* Boolean flag set for 'Multiple choices' prompt 		(OPT) */
				, psepar=		/* Specific separator 									(OPT) */
				, verb=no		/* Boolean flag set for verbose mode 					(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
 
	%if &ptype= %then 			%let ptype=NUMERIC;
	%else %do;
		%let ptype=%upcase(&ptype);
		%if "&ptype"="STRING" %then 			%let ptype=CHAR; 	/* legacy... */
		%else %if "&ptype"="FLOAT" %then 		%let ptype=NUMERIC;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&ptype, type=CHAR, set=CHAR NUMERIC DATE INTEGER) NE 0, mac=&_mac,		
				txt=%quote(!!! Wrong value for input PTYPE boolean parameter !!!)) %then
			%goto exit; 
	%end;

	%if &penclose= %then 			%let penclose=NO;
	%else %do;
		%let penclose=%upcase(&penclose);
		%if %error_handle(ErrorInputParameter, 
				%par_check(&penclose, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
				txt=%quote(!!! Wrong value for input PENCLOSE boolean parameter !!!)) %then
			%goto exit; 
	%end;

	%if &pmultipl= %then 			%let pmultipl=NO;
	%else %do;
		%let pmultipl=%upcase(&pmultipl);
		%if %error_handle(ErrorInputParameter, 
				%par_check(&pmultipl, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
				txt=%quote(!!! Wrong value for input PMULTIPL boolean parameter !!!)) %then
			%goto exit;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local go_parm
		type
		separator
		_WHEREORIGIN
		_lenWHEREORIGIN;

	%if %symexist(&prompt_name._count) %then %do; /* test if the prompt is a multiple choice */

		%if &&&prompt_name._count. > 0 %then %do;

			%let go_parm = 1;

			%if /* if prompt is not string then it is a numeric format */
				"&ptype"^="CHAR" 
					or
					/* if the selected values don't have to be enclosed then we use eg_whereparam 
					* in the numeric method */
					"&penclose"="NO" %then
				%let go_parm = 0;
			%if "&pmultipl"^="YES" %then 
				/* if the prompt is not a multiple choice then we don't have to make a list*/
				%let go_parm = 2;

			%if &go_parm =1 %then 						%let	type=S;
			%else %if &go_parm =0 %then					%let	type=N;
			/* test with the 2 parameters to know if the elements of the list are quoted or not*/
			/* if elements are quoted then parameter go_parm = 0 */ 

			%if &go_parm < 2 %then %do;
				%let wherep = %_eg_WhereParam( origin, &prompt_name, IN, TYPE=&type);

				%if %sysevalf(&psepar. = ) %then		%let separator=%quote( );
				%else									%let separator=%str(&psepar);
			   	%let wherep = %sysfunc(tranwrd(&wherep, %quote(,), &separator.));

				/* the "where condition" created by the macro looks like: "(origin IN (elt1, elt2, ... ))" 
				* we only need the list "elt1, elt2, ..."                                                   
				* so we need to extract the list from the where condition created by the macro         
				* note however for single selection, it looks like: "origin IN (elt1)" */
				%let _WHEREORIGIN=origin IN;
				%let _lenWHEREORIGIN=%length(&_WHEREORIGIN);
				
				/* method using length 
				%let position_in = %sysfunc(find(&wherep., &_WHEREORIGIN)) ; * calculate the position of the "in";
				%let length_in = %sysfunc(length(&wherep.)) ;     * calculate the length of the string; 			
				%let position_in=%eval(&position_in + &_lenWHEREORIGIN + 2); * 2=length of " (";
				%if &&&prompt_name._count. > 1 %then 	
					%let length_in=%eval(&length_in. - &position_in. - 1);	* 1=length of "))"-1;
				%else									
					%let length_in=%eval(&length_in. - &position_in.);	 	* 0=length of ")"-1;
				%let &prompt_name. = %sysfunc(substr(&wherep, &position_in, &length_in));
				*/

				/* method using replacement */
			   	%let wherep = %sysfunc(tranwrd(&wherep, %str(&_WHEREORIGIN), %quote()));
			   	%let wherep = %sysfunc(tranwrd(&wherep, %str(%(), %quote()));
			   	%let &prompt_name = %sysfunc(tranwrd(%bquote(&wherep), %str(%)), %quote()));

				/* compress the blanks */
				%if %sysevalf(&psepar. = ) %then
					%let &prompt_name = %sysfunc(compbl(%quote(&&&prompt_name)));
				%else 
					%let &prompt_name =%sysfunc(compress(%quote(&&&prompt_name)));
			 	/* %let &prompt_name =%cmpres(%trim(&&&prompt_name)) */

				%if &verb=yes %then 	%put &prompt_name.: &&&prompt_name. ;
			%end;

			%else %do;
				/* case of no multiple values */
				%if &verb=yes %then 	%put Prompt &prompt_name. is trimmed;
				%let &prompt_name = %cmpres(%trim(&&&prompt_name));
				/* %put Prompt &prompt_name. is not (re-)created (not a multiple selection prompt).  ;*/
			%end;

		%end;
		%else %if &&&prompt_name._count. = 0 %then %do;
			%if %symexist(&prompt_name._count) %then 
				/* case of no filters selected */
				%put No filter selected.;
			%if &verb=yes %then 	%put test existence: %symexist(&prompt_name._count);
			%goto exit;
		%end;

		/* Deletion of the PROMPT_NAMEn. macro values --- Begin */
		%if "&pmultipl"="YES" 
			and /* note that _CLIENTVERSION looks like: '7.100.1.2711' */
			%sysevalf(%sysfunc(substr(&_CLIENTVERSION,2,3)) <= 4.3) %then %do;

			/* creation of a table with PROMPT_NAMEn and PROMPT_NAME_count macro values */ 
			DATA supprmacro_&prompt_name.; 
				format supprmacro $100. ;
				%do j = 0 %to &&&prompt_name._count;
			  		supprmacro = upcase("&prompt_name.&j");
					output;
				%end;
				supprmacro = upcase("&prompt_name._count");
				output;
			run;

			/* deletion of the PROMPT_NAMEn and PROMPT_NAME_count macro values */
			DATA supprmacro_&prompt_name.;  
				SET supprmacro_&prompt_name.;
				/* test if the macro exists and supress it if yes */
				if symexist(supprmacro) then call symdel(supprmacro); 
			run;

			/* deletion of dataset to free space in the work */
			PROC DATASETS library = work nolist; 
				DELETE supprmacro_&prompt_name. ; 
			run;  
		%end;

    %end;
	%else %if "&pmultipl"="YES" %then %do;
		/* case of several program with this macro */
		%if &verb=yes %then 	%put Prompt &prompt_name. is not created or re-created (no need to).;
		%goto exit;
	%end;                                                                               
    %else %do;
		/* case of no multiple selection */
		%if &verb=yes %then 	%put Prompt &prompt_name. is trimmed;
		%let &prompt_name = %cmpres(%trim(&&&prompt_name));
		/*%put Prompt &prompt_name. is not created or re-created (not a multiple selection prompt).;*/
	%end;

	/* when working with prompts then text prompts are surrounded by control characters
	* (SOH, DC1, STX) and those are not interpreted well by the macro processor; the trick is 
	* to assign the value of the macro variable a second time, but using a call symputx 
	* statement */
	/*%let &prompt_name=%sysfunc(strip(&&&prompt_name));
data _NULL_;
	   call symputx('&prompt_name',strip("&idsn"));
	run;*/

	%exit:
%mend _egp_prompt;


%macro _example__egp_prompt;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put !!! &sysmacroname: Not yet implemented !!!;

	%put;
%mend _example__egp_prompt;

/** \endcond */

