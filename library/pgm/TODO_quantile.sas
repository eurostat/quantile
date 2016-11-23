/** \cond */
/** 
## quantile {#sas_quantile}
Generate `name`, `label` and `test` parameter used for quantile calculation

	%quantile(year, country, weight, file, inc, qtile);

### Arguments
* `year` : ;
* `country` : ;
* `weight` : weight variable;
* `inc` : income variable to consider;
* `qtile` : ;

### Returns
* `file` : dataset with `qtil`e calculation sorted by `year`, `country`, and `qtile`.

### Example
*/ 

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
*/


%macro quantile(/* input */ year, country, weight, file, inc, qtile);
	%local text1 label test cond;

	%let cond=%quote(&file..&inc < OUTW);
	%quantile_attribute(&qtile, &cond, _name_=name, _label_=label, _test_=test);

	PROC UNIVARIATE DATA=WORK.&file NOPRINT;
	  	VAR &inc;
	  	CLASS &country;
	  	CLASS &year;
	  	WEIGHT &weight; 
	  	*OUTPUT OUT=WORK.OUTW PCTLPRE=P_ PCTLPTS=5 TO 95 BY 5;
	  	*OUTPUT OUT=WORK.OUTW PCTLPRE=P_ PCTLPTS=1 to 5 by 1 PCTLPTS=5 TO 95 BY 5 PCTLPTS=95 TO 100 BY 1;
	  	OUTPUT OUT=WORK.OUTW PCTLPRE=P_ PCTLPTS=1 to 100 BY 1;
	RUN; 

	PROC TABULATE
	DATA=WORK.OUTW;
		*format COUNTRY $COUNTRYf.;
	VAR P_1 P_2 P_3 P_4 P_5 P_6 P_7 P_8 P_9 P_10 P_11 P_12 P_13 P_14 P_15 P_16 
	    P_17 P_18 P_19 P_20 P_21 P_22 P_23 P_24 P_25 P_26 P_27 P_28 P_29 P_30 
		P_31 P_32 P_33 P_34 P_35 P_36 P_37 P_38 P_39 P_40
	    P_41 P_42 P_43 P_44 P_45 P_46 P_47 P_48 P_49 P_50
	    P_51 P_52 P_53 P_54 P_55 P_56 P_57 P_58 P_59 P_60 
		P_61 P_62 P_63 P_64 P_65 P_66 P_67 P_68 P_69 P_70 
		P_71 P_72 P_73 P_74 P_75 P_76 P_77 P_78 P_79 P_80
	    P_81 P_82 P_83 P_84 P_85 P_86 P_87 P_88 P_89 P_90
	    P_91 P_92 P_93 P_94 P_95 P_96 P_97 P_98 P_98 P_99 P_100;
		CLASS &country /	ORDER=FORMATTED ;
		TABLE /* Row Dimension */
	&COUNTRY={LABEL=''}*
	  Sum={LABEL=''},
	/* Column Dimension */ 
	ALL={LABEL="&name BOUNDARIES FOR &inc"}*
	  &label
	/* Table Options */
	/ BOX={LABEL="YEAR 20&year" } 		;
	RUN;

	PROC SQL;
	  	CREATE TABLE WORK.&file.1 AS
	  	SELECT &file..*, 
		&test,
		(CASE WHEN CALCULATED &name is missing THEN -1 ELSE 1 END) AS &text1._F
	  	FROM WORK.&file INNER JOIN WORK.OUTW ON (&file..&year = OUTW.&year) AND (&file..&country = OUTW.&country);
	QUIT;

	/* Selected the first and last 5 percentiles  */
	%if &name=PERCENTILE %then %do;
		data &file.1;set &file.1;
	   		if &percentile not in ('1','2','3','4','5','95',
			'96','97','98','99','100')
			then delete;
		run;
	%end;
	proc sort data=&file.1; by &year &country &qtile; run;

%mend quantile;

%macro _example_quantile; 
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let qtile=decile;
	%_dstest35;

	%quantile(time, geo, RB050a, _dstest35, EQ_INC20, &qtile);

	%work_clean(_dstest35);
%mend _example_quantile; 
/*_example_quantile;*/
