

%macro continuous_Diff(var,ftyp,wgt);

/**********************************************************/
/*check if &var exist into the &yy datasets                */
/***********************************************************/
data _null_;
dset=open("silc.&ss&cc&yy.&ftyp");
call symput ('chk',varnum(dset,"&var"));
run; 

/**********************************************************/
/*check if &var exist into the &y1 datasets                */
/***********************************************************/
data _null_;
dset=open("silcprev.&s1&cc&y1.&ftyp");
call symput ('chk1',varnum(dset,"&var"));
run; 

%if  (&chk > 0 and &chk1 > 0) %then %do; /* check if both tables contains the variable*/

	%if &ftyp=h %then %do;
		
		/*********************************************************/
		/*create SILC data in proper shape and with no missing    */
		/***********************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILC AS SELECT 
			 &ss&cc&yy.&ftyp..&ftyp.B020 AS COUNTRY FORMAT=$2.,
			 &ss&cc&yy.&ftyp..&var,
			 &ss&cc&yy.d.&wgt AS WEIGHT FORMAT=8.5
		 FROM silc.&ss&cc&yy.&ftyp
		 INNER JOIN silc.&ss&cc&yy.d ON (&ss&cc&yy.h.HB020 = &ss&cc&yy.d.DB020) AND (&ss&cc&yy.h.HB030 = &ss&cc&yy.d.DB030)
		 WHERE &ss&cc&yy.&ftyp..&var NOT IS MISSING AND &ss&cc&yy.&ftyp..&var >0 AND &ftyp.B010 = &RYYYY;
		
		 SELECT DISTINCT count(&var) as N into :Nbr FROM WORK.SILC;
		QUIT;
		
		/**************************************************************/
		/*create SILC Y-1 data in proper shape and with no missing   */
		/*****************************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILCPREV AS SELECT
			 &s1&cc&y1.&ftyp..&ftyp.B020 AS COUNTRY FORMAT=$2.,
			 &s1&cc&y1.&ftyp..&var FORMAT=2.,
			 &s1&cc&y1.d.&wgt AS WEIGHT FORMAT=8.5
		 FROM silcprev.&s1&cc&y1.&ftyp
		 INNER JOIN silcprev.&s1&cc&y1.d ON (&s1&cc&y1.h.HB020 = &s1&cc&y1.d.DB020) AND (&s1&cc&y1.h.HB030 = &s1&cc&y1.d.DB030)
		 WHERE &s1&cc&y1.&ftyp..&var NOT IS MISSING AND &s1&cc&y1.&ftyp..&var >0  AND &ftyp.B010 = 20&y1;
		 	
		 SELECT DISTINCT count(&var) as N1 into :Nbr1 FROM WORK.SILCPREV;
		QUIT;
	%end;
	%else %do;
		/*********************************************************/
		/*create SILC data in proper shape and with no missing    */
		/***********************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILC AS SELECT 
			 &ss&cc&yy.&ftyp..&ftyp.B020 AS COUNTRY FORMAT=$2.,
			 &ss&cc&yy.&ftyp..&var,
			 &ss&cc&yy.&ftyp..&wgt AS WEIGHT FORMAT=8.5
		 FROM silc.&ss&cc&yy.&ftyp
		 WHERE &ss&cc&yy.&ftyp..&var NOT IS MISSING AND &ss&cc&yy.&ftyp..&var >0  AND &ftyp.B010 = &RYYYY;
		
		 SELECT DISTINCT count(&var) as N into :Nbr FROM WORK.SILC;
		QUIT;
		
		/**************************************************************/
		/*create SILC Y-1 data in proper shape and with no missing   */
		/*****************************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILCPREV AS SELECT
			 &s1&cc&y1.&ftyp..&ftyp.B020 AS COUNTRY FORMAT=$2.,
			 &s1&cc&y1.&ftyp..&var FORMAT=2.,
			 &s1&cc&y1.&ftyp..&wgt AS WEIGHT FORMAT=8.5
		 FROM silcprev.&s1&cc&y1.&ftyp
		 WHERE &s1&cc&y1.&ftyp..&var NOT IS MISSING AND &s1&cc&y1.&ftyp..&var >0  AND &ftyp.B010 = 20&y1;
		 	
		 SELECT DISTINCT count(&var) as N1 into :Nbr1 FROM WORK.SILCPREV;
		QUIT;
	%end;

	%if &Nbr>0 and &Nbr1>0 %then %do; /* check if both tables contain data*/

		/***********************************************************/
		/*create YY summary table with percentiles*/
		/*************************************************************/

		PROC MEANS DATA=WORK.SILC
			FW=12
			PRINTALLTYPES
			CHARTYPE
			QMETHOD=OS
			VARDEF=DF
		 NONOBS 	
				
				MEDIAN ;
			VAR &var;
			WEIGHT WEIGHT;
			ID COUNTRY;

		OUTPUT 	OUT=WORK.SILC_MEANS(LABEL="Summary Statistics for WORK.SILC")
			
			
				MEDIAN()= 
			
				n()=N
			

			/ AUTONAME AUTOLABEL INHERIT
			;
		RUN;


		/*********************************************************/
		/*create SILC  flag data in proper shape   */
		/***********************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILC_F AS SELECT 
			 &ss&cc&yy.&ftyp..&ftyp.B020 AS COUNTRY FORMAT=$2.,
			 &ss&cc&yy.&ftyp..&var._F FORMAT=2.,
			 1 as val
		 FROM silc.&ss&cc&yy.&ftyp
		 	WHERE &ftyp.B010 = &RYYYY;
		QUIT;


		/***********************************************************/
		/*create summary table with % of  SILC %var._F modalities*/
		/*************************************************************/

		PROC TABULATE
		DATA=WORK.SILC_F

			OUT=WORK.ST_SILC_F(LABEL="Summary Tables  for SILC &var._F");
			VAR val;
			CLASS &var._F /	ORDER=UNFORMATTED MISSING;
			CLASS COUNTRY /	ORDER=UNFORMATTED MISSING;
			TABLE 
		/* Row Dimension */
		COUNTRY,
		/* Column Dimension */
		&var._F*
		  (RowPctN N) 		;
		RUN;

		

		/***********************************************************/
		/*create Y1 summary table with percentiles*/
		/***********************************************************/

		PROC MEANS DATA=WORK.SILCPREV
			FW=12
			PRINTALLTYPES
			CHARTYPE
			QMETHOD=OS
			VARDEF=DF
		 NONOBS 	
				
				MEDIAN	;
			VAR &var;
			WEIGHT WEIGHT;
			ID COUNTRY;
		OUTPUT 	OUT=WORK.SILCPREV_MEANS(LABEL="Summary Statistics for WORK.SILC")
			
				
				MEDIAN()=
				n()=N 

			/ AUTONAME AUTOLABEL INHERIT
			;
		RUN;

		/*********************************************************/
		/*create SILC Y-1 flag data in proper shape   */
		/***********************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILCPREV_F AS SELECT 
			 &s1&cc&y1.&ftyp..&ftyp.B020 AS COUNTRY FORMAT=$2.,
			 &s1&cc&y1.&ftyp..&var._F FORMAT=2.,
			 1 as val
		 FROM silcprev.&s1&cc&y1.&ftyp
			WHERE &ftyp.B010 = 20&y1;
		QUIT;


		/***********************************************************/
		/*create summary table with % of  SILC %var._F modalities*/
		/*************************************************************/

		PROC TABULATE
		DATA=WORK.SILCPREV_F

			OUT=WORK.ST_SILCPREV_F(LABEL="Summary Tables  for SILC &var._F");
			VAR val;
			CLASS &var._F /	ORDER=UNFORMATTED MISSING;
			CLASS COUNTRY /	ORDER=UNFORMATTED MISSING;
			TABLE 
		/* Row Dimension */
		COUNTRY,
		/* Column Dimension */
		&var._F*
		  (RowPctN N) 		;
		RUN;


		/*********************************************************************************/
		/*      joint SILC and SILCPREV data and filter when differences are over the threshold*/
		/***********************************************************************************/
		%macro percentile(perc);
			PROC SQL;
			 CREATE TABLE WORK.SILC_SILCPREV_&perc AS SELECT 
				 SILC_MEANS.COUNTRY FORMAT=$2.,
			 	 ("&var") as VARIABLE format=$6.,
				 ("&perc") as PERCENTILE format=$6.,
				(CASE  WHEN SILC_MEANS.&var._&perc = 0 THEN 0 
					ELSE (100 * ((SILC_MEANS.&var._&perc - (SILCPREV_MEANS.&var._&perc/&rate))/(SILCPREV_MEANS.&var._&perc/&rate))) END )
					AS VAL_diff_percent FORMAT=4.0,
				 (SILC_MEANS.&var._&perc) as SILC_&yy._value FORMAT= 12.,
				 (SILCPREV_MEANS.&var._&perc/&rate) as SILC_&y1._value FORMAT= 12.,
				SILC_MEANS.N as N_obs_&yy,
				 SILCPREV_MEANS.N as N_obs_&y1,
				 (100*(SILC_MEANS.N - SILCPREV_MEANS.N)/SILCPREV_MEANS.N) as N_Obs_diff_percent FORMAT=4.0
				
			 FROM WORK.SILC_MEANS AS SILC_MEANS
				  LEFT JOIN WORK.SILCPREV_MEANS AS SILCPREV_MEANS ON (SILC_MEANS.COUNTRY = SILCPREV_MEANS.COUNTRY)
				WHERE (CALCULATED VAL_diff_percent >= &th or CALCULATED VAL_diff_percent <= -&th) AND MIN(SILCPREV_MEANS.N, SILC_MEANS.N)>100 ;
			QUIT;

			/*append all the pb in the following table*/
			proc append base=work.cont_diff data=WORK.SILC_SILCPREV_&perc force;

		%mend percentile;


		
		%percentile(MEDIAN);
		
		/*********************************************************************************/
		/*      joint SILC and SILCPREV FLAG data and filter when differences are over the threshold*/
		/***********************************************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILC_SILCPREV_F AS SELECT 
			 ST_SILC_F.COUNTRY FORMAT=$2.,
		 	 ("&var._F") as VARIABLE,
			 (ST_SILC_F.&var._F) as MODALITY,
			( ST_SILC_F.PctN_01 - ST_SILCPREV_F.PctN_01) as VAL_diff_percent FORMAT=4.0,
			 ST_SILC_F.PctN_01 AS SILC_&yy._percent FORMAT=4.1,
			 ST_SILCPREV_F.PctN_01 AS SILC_&y1._percent FORMAT=4.1,
			ST_SILC_F.N  as N_obs_&yy,
			 ST_SILCPREV_F.N as N_obs_&y1,
			(100*(ST_SILC_F.N - ST_SILCPREV_F.N)/ST_SILC_F.N) as N_Obs_diff_percent FORMAT=4.0
		 FROM WORK.ST_SILC_F AS ST_SILC_F
			  LEFT JOIN WORK.ST_SILCPREV_F AS ST_SILCPREV_F ON (ST_SILC_F.COUNTRY = ST_SILCPREV_F.COUNTRY) AND (ST_SILC_F.&var._F = ST_SILCPREV_F.&var._F)
			WHERE (CALCULATED VAL_diff_percent >= &th or CALCULATED VAL_diff_percent <= -&th) AND MIN( ST_SILC_F.N, ST_SILCPREV_F.N)>100;
		QUIT;

		proc append base=work.discrete_diff data=WORK.SILC_SILCPREV_F force;
	%end;
%end;
%mend continuous_Diff;
/*
%continuous_Diff(rb080,r,RB050);
%continuous_Diff(rl010,r,RL070);
*/
%continuous_Diff(hy010,h,DB090);
%continuous_Diff(hy020,h,DB090);
%continuous_Diff(hy022,h,DB090);
%continuous_Diff(hy023,h,DB090);
%continuous_Diff(hy030N,h,DB090);
%continuous_Diff(hy040N,h,DB090);
%continuous_Diff(hy050N,h,DB090);
%continuous_Diff(hy060N,h,DB090);
%continuous_Diff(hy070N,h,DB090);
%continuous_Diff(hy080N,h,DB090);
%continuous_Diff(hy081N,h,DB090);
%continuous_Diff(hy090N,h,DB090);
%continuous_Diff(hy100N,h,DB090);
%continuous_Diff(hy110N,h,DB090);
%continuous_Diff(hy120N,h,DB090);
%continuous_Diff(hy130N,h,DB090);
%continuous_Diff(hy131N,h,DB090);
%continuous_Diff(hy140N,h,DB090);
%continuous_Diff(hy145N,h,DB090);
%continuous_Diff(hy170N,h,DB090);
%continuous_Diff(hy030G,h,DB090);
%continuous_Diff(hy040G,h,DB090);
%continuous_Diff(hy050G,h,DB090);
%continuous_Diff(hy060G,h,DB090);
%continuous_Diff(hy070G,h,DB090);
%continuous_Diff(hy080G,h,DB090);
%continuous_Diff(hy081G,h,DB090);
%continuous_Diff(hy090G,h,DB090);
%continuous_Diff(hy100G,h,DB090);
%continuous_Diff(hy110G,h,DB090);
%continuous_Diff(hy120G,h,DB090);
%continuous_Diff(hy130G,h,DB090);
%continuous_Diff(hy131G,h,DB090);
%continuous_Diff(hy140G,h,DB090);
%continuous_Diff(hy170G,h,DB090);

%continuous_Diff(hh060,h,DB090);
%continuous_Diff(hh061,h,DB090);
%continuous_Diff(hh070,h,DB090);

%continuous_Diff(PY010N,p,PB040);
%continuous_Diff(PY020N,p,PB040);
%continuous_Diff(PY021N,p,PB040);
%continuous_Diff(PY035N,p,PB040);
%continuous_Diff(PY050N,p,PB040);
%continuous_Diff(PY070N,p,PB040);
%continuous_Diff(PY080N,p,PB040);
%continuous_Diff(PY090N,p,PB040);
%continuous_Diff(PY100N,p,PB040);
%continuous_Diff(PY110N,p,PB040);
%continuous_Diff(PY120N,p,PB040);
%continuous_Diff(PY130N,p,PB040);
%continuous_Diff(PY140N,p,PB040);
%continuous_Diff(PY010G,p,PB040);
%continuous_Diff(PY020G,p,PB040);
%continuous_Diff(PY021G,p,PB040);
%continuous_Diff(PY030G,p,PB040);
%continuous_Diff(PY031G,p,PB040);
%continuous_Diff(PY035G,p,PB040);
%continuous_Diff(PY050G,p,PB040);
%continuous_Diff(PY070G,p,PB040);
%continuous_Diff(PY080G,p,PB040);
%continuous_Diff(PY090G,p,PB040);
%continuous_Diff(PY100G,p,PB040);
%continuous_Diff(PY110G,p,PB040);
%continuous_Diff(PY120G,p,PB040);
%continuous_Diff(PY130G,p,PB040);
%continuous_Diff(PY140G,p,PB040);
%continuous_Diff(PY030N,p,PB040);
%continuous_Diff(PY200G,p,PB040);
