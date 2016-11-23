/** 
## quantile_attribute {#sas_quantile_attribute}
Generate `name`, `label`, `code` and `test` attributes used for quantile calculation
and publication on Eurobase.

	%quantile_attribute(quantile, cond, _name_=, _label_=, _case_=, _code_=);

### Arguments
* `quantile` : definition of the desired quantile; it can be either `quartile/4/Q`
	(meaning: any of these 3), `quintile/5/QU`, `sextile/6/S`, `decile/10/D` or 
	`percentile/100/P`;
`cond` : condition to apply in the test; it should be a quoted string.

### Returns
* `_name_` : upper case desired quantile (_i.e._, either `QUARTILE`, `QUINTILE`, etc...);
* `_label_` : label;
* `_case_` : case;
* `_code_` : (_option_) code of the quantile (_e.g._, `P`, `D`, `S`, `Q` or `QU`).

### Examples
The following settings:

	%let name=; %let label=; %let case=; %let code=;
	%quantile_attribute(QUARTILE, %quote(file.inc < OUTW), 
						_name_=name, _label_=label, _code_=code, _case_=case);
	
returns the attributes:
* `name=QUARTILE`,
* `code=Q`,
* `label= (P_25={LABEL=QUARTILE 1}  *F=12.0
			P_50={LABEL=QUARTILE 2}  *F=12.0
 			P_75={LABEL=QUARTILE 3}  *F=12.0);`

* `case=(CASE 
		WHEN &file..&inc < OUTW.P_25 THEN 1 
		WHEN &file..&inc < OUTW.P_50 THEN 2 
		WHEN &file..&inc < OUTW.P_75 THEN 3 		
		ELSE 4 
		END ) AS QUARTILE;`

See `%%_example_quantile_attribute` for more examples.
*/ /** \cond */

%macro quantile_attribute(/*input*/  quantile, cond, 
							/*output*/ _name_=, _label_=, _case_=, _code_=);
						
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_name_) EQ 1 or %macro_isblank(_label_) EQ 1 or %macro_isblank(_case_) EQ 1,		
			txt=!!! Parameters _name_ _label_ and _case_ need all to be set !!!) %then 
		%goto exit;

	/* some default codes */
	%if %symexist(G_PING_QUARTILE_CODE) %then 	%let DEF_QUARTILE_CODE=&G_PING_QUARTILE_CODE;
	%else									%let DEF_QUARTILE_CODE=Q;
	%if %symexist(G_PING_QUINTILE_CODE) %then 	%let DEF_QUINTILE_CODE=&G_PING_QUINTILE_CODE;
	%else									%let DEF_QUINTILE_CODE=QU;
	%if %symexist(G_PING_SEXTILE_CODE) %then 	%let DEF_SEXTILE_CODE=&G_PING_SEXTILE_CODE;
	%else									%let DEF_SEXTILE_CODE=S;
	%if %symexist(G_PING_DECILE_CODE) %then 		%let DEF_DECILE_CODE=&G_PING_DECILE_CODE;
	%else									%let DEF_DECILE_CODE=D;
	%if %symexist(G_PING_PERCENTILE_CODE) %then 	%let DEF_PERCENTILE_CODE=&G_PING_PERCENTILE_CODE;
	%else									%let DEF_PERCENTILE_CODE=P;

	/* some local variables */
	%local _name _label _case _code;
	%let _case=;
	%let _label=;

	%local macname;
	%let macname=&sysmacroname; /* used for error handling */
	
	%local FORMAT;
	%let FORMAT=*F=12.0;

	/* check and reset the input parameter */
	%if &quantile=4 or %upcase(&quantile)=QUARTILE or %upcase(&quantile)=&DEF_QUARTILE_CODE %then %do;
		%let _code=&DEF_QUARTILE_CODE;
		%let _name=QUARTILE;
		%let step=25; %let nstep=4;
	%end;
	%else %if &quantile=5 or %upcase(&quantile)=QUINTILE or %upcase(&quantile)=&DEF_QUINTILE_CODE %then %do; 
		%let _code=&DEF_QUINTILE_CODE;
		%let _name=QUINTILE;
		%let step=20; %let nstep=5;
	%end;
	%else %if &quantile=6 or %upcase(&quantile)=SEXTILE or %upcase(&quantile)=&DEF_SEXTILE_CODE %then %do;
		%let _code=&DEF_SEXTILE_CODE;
		%let _name=SEXTILE;
		%let step=1; %let nstep=6;
	%end;
	%else %if &quantile=10 or %upcase(&quantile)=DECILE or %upcase(&quantile)=&DEF_DECILE_CODE %then %do; 
		%let _code=&DEF_DECILE_CODE;
		%let _name=DECILE;
		%let step=10; %let nstep=10;
	%end;
	%else %if &quantile=100 or %upcase(&quantile)=PERCENTILE or %upcase(&quantile)=&DEF_PERCENTILE_CODE %then %do; 
		%let _code=&DEF_PERCENTILE_CODE;
		%let _name=PERCENTILE;
		%let step=1; %let nstep=100;
	%end;

	/* run the final checking on input parameter */
	%if %error_handle(WrongInputArgument, 
					  &_code NE &DEF_QUARTILE_CODE and 
						&_code NE &DEF_QUINTILE_CODE and 
						&_code NE &DEF_SEXTILE_CODE and 
						&_code NE &DEF_DECILE_CODE and 
						&_code NE &DEF_PERCENTILE_CODE,
					  mac=&macname,
					  txt=!!! Unknown argument &_code !!!) %then 
		%goto exit;

	%local step istep nstep s;
	%do istep = 1 %to %eval(&nstep -1);
		%let s=%eval(&istep * &step);
		%let _label = &_label 
					  %quote(P_&s={LABEL=)%str(%')&_name &istep%str(%')%quote(} &FORMAT);
		%let _case = &_case 
					%quote(WHEN) %unquote(&cond)%quote(.P_&s THEN &istep);
	%end;
	
	%let _label=(&_label);
	%let _case=(CASE &_case ELSE &nstep END) AS &_name;

	/* results */
	data _null_;
		call symput("&_name_","&_name");
		call symput("&_label_","&_label");
		call symput("&_case_","&_case");
		%if not %macro_isblank(_code_) %then %do;
			call symput("&_code_","&_code");
		%end;
	run;

	%exit:
%mend quantile_attribute;

%macro _example_quantile_attribute;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local name case label code cond;
	%let cond=%quote(file.inc < OUTW);
	
	%put (i) Dummy example with missing output variables;
	%quantile_attribute(sextile, &cond, _code_=code);
	%if %macro_isblank(code) %then 	%put OK: TEST PASSED - Empty outputs when arguments are missing;
	%else 							%put ERROR: TEST FAILED - Non-empty outputs when arguments are missing;

	%put (ii) Dummy example with mismatched input parameter;
	%quantile_attribute(textile, &cond, _name_=name, _label_=label, _code_=code, _case_=case);
	%if %macro_isblank(code) %then 	%put OK: TEST PASSED - Empty outputs returned for dummy quantile "textile";
	%else 							%put ERROR: TEST FAILED - Non-empty outputs returned for dummy quantile "textile";

	%put (iii) Example with input sextile;
	%quantile_attribute(sextile, &cond, _name_=name, _label_=label, _code_=code, _case_=case);
	%if &code^=S %then 	%put ERROR: TEST FAILED - Wrong output code &code returned for input quantile "sextile";
	%else %do;
		%put        name=&name;
		%put  		label=&label;
		%put  		case=&case;
		%put;
		%put OK: TEST PASSED - Output code S returned for input quantile &name;
	%end;

	%put (iv) Example with input 4;
	%quantile_attribute(4, &cond, _name_=name, _label_=label, _code_=code, _case_=case);
	%if &code^=Q %then 	%put ERROR: TEST FAILED - Wrong output code &code returned for input quantile "4";
	%else %do;
		%put        name=&name;
		%put  		label=&label;
		%put  		case=&case;
		%put;
		%put OK: TEST PASSED - Output code Q returned for input quantile &name;
	%end;

	%put (v) Example with input...10;
	%quantile_attribute(10, &cond, _name_=name, _label_=label, _code_=code, _case_=case);
	%if &code^=D %then 	%put ERROR: TEST FAILED - Wrong output code &code returned for input quantile "10";
	%else %do;
		%put        name=&name;
		%put  		label=&label;
		%put  		case=&case;
		%put;
		%put OK: TEST PASSED - Output code D returned for input quantile &name;
	%end;

%mend _example_quantile_attribute;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
options NOQUOTELENMAX ;
%_example_quantile_attribute;  
*/

/** \endcond */

