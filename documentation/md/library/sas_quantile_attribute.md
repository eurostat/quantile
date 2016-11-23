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
