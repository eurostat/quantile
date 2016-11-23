
%macro discrete_Diff(var,ftyp,wgt);


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
			 &ss&cc&yy.&ftyp..&var FORMAT=2.1,
			 &ss&cc&yy.d.&wgt AS WEIGHT FORMAT=8.5
		 FROM silc.&ss&cc&yy.&ftyp
		 INNER JOIN silc.&ss&cc&yy.d ON (&ss&cc&yy.h.HB010 = &ss&cc&yy.d.DB010) AND (&ss&cc&yy.h.HB020 = &ss&cc&yy.d.DB020) AND (&ss&cc&yy.h.HB030 = &ss&cc&yy.d.DB030)
		 WHERE &ss&cc&yy.&ftyp..&var NOT IS MISSING AND &ftyp.B010 = &RYYYY;
		
		 SELECT DISTINCT count(&var) as N into :Nbr FROM WORK.SILC;
		QUIT;
		
		/**************************************************************/
		/*create SILC Y-1 data in proper shape and with no missing   */
		/*****************************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILCPREV AS SELECT
			 &s1&cc&y1.&ftyp..&ftyp.B020 AS COUNTRY FORMAT=$2.,
			 &s1&cc&y1.&ftyp..&var FORMAT=2.1,
			 &s1&cc&y1.d.&wgt AS WEIGHT FORMAT=8.5
		 FROM silcprev.&s1&cc&y1.&ftyp
		 INNER JOIN silcprev.&s1&cc&y1.d ON (&ss&cc&y1.h.HB010 = &ss&cc&y1.d.DB010) AND (&s1&cc&y1.h.HB020 = &s1&cc&y1.d.DB020) AND (&s1&cc&y1.h.HB030 = &s1&cc&y1.d.DB030)
		 WHERE &s1&cc&y1.&ftyp..&var NOT IS MISSING AND &ftyp.B010 = 20&y1;
		 	
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
			 &ss&cc&yy.&ftyp..&var FORMAT=2.,
			 &ss&cc&yy.&ftyp..&wgt AS WEIGHT FORMAT=8.5
		 FROM silc.&ss&cc&yy.&ftyp
		 WHERE &ss&cc&yy.&ftyp..&var NOT IS MISSING AND &ftyp.B010 = &RYYYY;
		
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
		 WHERE &s1&cc&y1.&ftyp..&var NOT IS MISSING AND &ftyp.B010 = 20&y1;
		 	
		 SELECT DISTINCT count(&var) as N1 into :Nbr1 FROM WORK.SILCPREV;
		QUIT;
	%end;
	%if &Nbr>0 and &Nbr1>0 %then %do; /* check if both tables contain data*/

		/***********************************************************/
		/*create summary table with % of  SILC %var modalities*/
		/*************************************************************/

		PROC TABULATE
			DATA=WORK.SILC
			OUT=WORK.ST_SILC(LABEL="Summary Tables  for SILC &var");
			VAR WEIGHT;
			CLASS &var /	ORDER=UNFORMATTED MISSING;
			CLASS COUNTRY /	ORDER=UNFORMATTED MISSING;
			TABLE 
		/* Row Dimension */
		COUNTRY,
		/* Column Dimension */
		&var*
		  WEIGHT*
		    (RowPctSum N)		;
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
		  (RowPctN N)		;
		RUN;

		

		/***********************************************************/
		/*create summary table with % of  SILC Y-1  modalities*/
		/***********************************************************/

		PROC TABULATE
			DATA=WORK.SILCPREV
			OUT=WORK.ST_SILCPREV(LABEL="Summary Tables  for SILCPREV ");
			VAR WEIGHT;
			CLASS &var /	ORDER=UNFORMATTED MISSING;
			CLASS COUNTRY /	ORDER=UNFORMATTED MISSING;
			TABLE 
		/* Row Dimension */
		COUNTRY,
		/* Column Dimension */
		&var*
		  WEIGHT*
		    (RowPctSum N)		;
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
		  (RowPctN N)		;
		RUN;

		/*********************************************************************************/
		/*      joint SILC and SILCPREV data and filter when differences are over the threshold*/
		/***********************************************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILC_SILCPREV AS SELECT 
			 ("&RCC") AS COUNTRY FORMAT=$2.,
		 	 ("&var") as VARIABLE FORMAT=$8.,
			 (CASE  
               WHEN ST_SILC.&var = .
               THEN ST_SILCPREV.&var
               ELSE ST_SILC.&var
            END) AS MODALITY,
			(SUM(0,ST_SILC.WEIGHT_PctSum_01) - SUM(0,ST_SILCPREV.WEIGHT_PctSum_01)) as VAL_diff_percent FORMAT=4.0,
			 SUM(0,ST_SILC.WEIGHT_PctSum_01) AS SILC_&yy._percent FORMAT=4.1,
			SUM(0,ST_SILCPREV.WEIGHT_PctSum_01) AS SILC_&y1._percent FORMAT=4.1,
			SUM(0,ST_SILC.WEIGHT_N) as N_obs_&yy,
			 SUM(0,ST_SILCPREV.WEIGHT_N) as N_obs_&y1,
			(SUM(0,ST_SILC.WEIGHT_N) - SUM(0,ST_SILCPREV.WEIGHT_N)) as N_Obs_diff FORMAT=4.0 
			
		 FROM WORK.ST_SILC AS ST_SILC
			  FULL JOIN WORK.ST_SILCPREV AS ST_SILCPREV ON (ST_SILC.COUNTRY = ST_SILCPREV.COUNTRY) AND (ST_SILC.&var = ST_SILCPREV.&var)
			WHERE (CALCULATED VAL_diff_percent >= &th or CALCULATED VAL_diff_percent <= -&th) AND (ST_SILC.WEIGHT_N > 100 OR ST_SILCPREV.WEIGHT_N > 100);
		QUIT;

		/*append all the pb in the following table*/
		proc append base=work.discrete_diff data=WORK.SILC_SILCPREV force;

		/*********************************************************************************/
		/*      joint SILC and SILCPREV FLAG data and filter when differences are over the threshold*/
		/***********************************************************************************/

		PROC SQL;
		 CREATE TABLE WORK.SILC_SILCPREV_F AS SELECT 
			 ST_SILC_F.COUNTRY FORMAT=$2.,
		 	 ("&var._F") as VARIABLE FORMAT=$8.,
			 (ST_SILC_F.&var._F) as MODALITY,
			( ST_SILC_F.PctN_01 - ST_SILCPREV_F.PctN_01) as VAL_diff_percent FORMAT=4.0,
			 ST_SILC_F.PctN_01 AS SILC_&yy._percent FORMAT=4.1,
			ST_SILCPREV_F.PctN_01 AS SILC_&y1._percent FORMAT=4.1,
			ST_SILC_F.N as N_obs_&yy,
			ST_SILCPREV_F.N as N_obs_&y1,
			(100*(ST_SILC_F.N - ST_SILCPREV_F.N)/ST_SILC_F.N) as N_Obs_diff_percent FORMAT=4.0

		 FROM WORK.ST_SILC_F AS ST_SILC_F
			  LEFT JOIN WORK.ST_SILCPREV_F AS ST_SILCPREV_F ON (ST_SILC_F.COUNTRY = ST_SILCPREV_F.COUNTRY) AND (ST_SILC_F.&var._F = ST_SILCPREV_F.&var._F)
			WHERE (CALCULATED VAL_diff_percent >= &th or CALCULATED VAL_diff_percent <= -&th) AND MIN( ST_SILC_F.N, ST_SILCPREV_F.N)>100;
		QUIT;

		proc append base=work.discrete_diff data=WORK.SILC_SILCPREV_F force;

	%end;
%end;
%mend discrete_Diff;


%discrete_Diff(DB100,d,DB090);
%discrete_Diff(DB120,d,DB090);
%discrete_Diff(DB130,d,DB090);
%discrete_Diff(DB135,d,DB090);

%discrete_Diff(RB070,r,RB050);
%discrete_Diff(RB090,r,RB050);
%discrete_Diff(RB200,r,RB050);
%discrete_Diff(RB210,r,RB050);
%discrete_Diff(RB245,r,RB050);
%discrete_Diff(RB250,r,RB050);
%discrete_Diff(RB260,r,RB050);

%discrete_Diff(HS010,h,DB090);
%discrete_Diff(HS011,h,DB090);
%discrete_Diff(HS020,h,DB090);
%discrete_Diff(HS021,h,DB090);
%discrete_Diff(HS030,h,DB090);
%discrete_Diff(HS031,h,DB090);
%discrete_Diff(HS040,h,DB090);
%discrete_Diff(HS050,h,DB090);
%discrete_Diff(HS060,h,DB090);
%discrete_Diff(HS070,h,DB090);
%discrete_Diff(HS080,h,DB090);
%discrete_Diff(HS090,h,DB090);
%discrete_Diff(HS100,h,DB090);
%discrete_Diff(HS110,h,DB090);
%discrete_Diff(HS120,h,DB090);
%discrete_Diff(HS140,h,DB090);
%discrete_Diff(HS150,h,DB090);
%discrete_Diff(HS160,h,DB090);
%discrete_Diff(HS170,h,DB090);
%discrete_Diff(HS180,h,DB090);
%discrete_Diff(HS190,h,DB090);
%discrete_Diff(HH010,h,DB090);
%discrete_Diff(HH020,h,DB090);
%discrete_Diff(HH021,h,DB090);
%discrete_Diff(HH030,h,DB090);
%discrete_Diff(HH040,h,DB090);
%discrete_Diff(HH050,h,DB090);
%discrete_Diff(HH080,h,DB090);
%discrete_Diff(HH081,h,DB090);
%discrete_Diff(HH090,h,DB090);
%discrete_Diff(HH091,h,DB090);

%discrete_Diff(PB130,p,PB040);
%discrete_Diff(PB150,p,PB040);
%discrete_Diff(PB190,p,PB040);
%discrete_Diff(PB200,p,PB040);
%discrete_Diff(PE010,p,PB040);
%discrete_Diff(PE020,p,PB040);
%discrete_Diff(PE040,p,PB040);
%discrete_Diff(PL030,p,PB040);
%discrete_Diff(PL031,p,PB040);
%discrete_Diff(PL035,p,PB040);
%discrete_Diff(PL015,p,PB040);
%discrete_Diff(PL020,p,PB040);
%discrete_Diff(PL025,p,PB040);
%discrete_Diff(PL040,p,PB040);
%discrete_Diff(PL050,p,PB040);
%discrete_Diff(PL051,p,PB040);
%discrete_Diff(PL070,p,PB040);
%discrete_Diff(PL072,p,PB040);
%discrete_Diff(PL073,p,PB040);
%discrete_Diff(PL074,p,PB040);
%discrete_Diff(PL075,p,PB040);
%discrete_Diff(PL076,p,PB040);
%discrete_Diff(PL080,p,PB040);
%discrete_Diff(PL085,p,PB040);
%discrete_Diff(PL086,p,PB040);
%discrete_Diff(PL087,p,PB040);
%discrete_Diff(PL088,p,PB040);
%discrete_Diff(PL089,p,PB040);
%discrete_Diff(PL090,p,PB040);
%discrete_Diff(PL120,p,PB040);
%discrete_Diff(PL130,p,PB040);
%discrete_Diff(PL140,p,PB040);
%discrete_Diff(PL150,p,PB040);
%discrete_Diff(PL160,p,PB040);
%discrete_Diff(PL170,p,PB040);
%discrete_Diff(PL180,p,PB040);
%discrete_Diff(PL190,p,PB040);
%discrete_Diff(PL200,p,PB040);
%discrete_Diff(PL210A,p,PB040);
%discrete_Diff(PL210B,p,PB040);
%discrete_Diff(PL210C,p,PB040);
%discrete_Diff(PL210D,p,PB040);
%discrete_Diff(PL210E,p,PB040);
%discrete_Diff(PL210F,p,PB040);
%discrete_Diff(PL210G,p,PB040);
%discrete_Diff(PL210H,p,PB040);
%discrete_Diff(PL210I,p,PB040);
%discrete_Diff(PL210J,p,PB040);
%discrete_Diff(PL210K,p,PB040);
%discrete_Diff(PL210L,p,PB040);
%discrete_Diff(PL211A,p,PB040);
%discrete_Diff(PL211B,p,PB040);
%discrete_Diff(PL211C,p,PB040);
%discrete_Diff(PL211D,p,PB040);
%discrete_Diff(PL211E,p,PB040);
%discrete_Diff(PL211F,p,PB040);
%discrete_Diff(PL211G,p,PB040);
%discrete_Diff(PL211H,p,PB040);
%discrete_Diff(PL211I,p,PB040);
%discrete_Diff(PL211J,p,PB040);
%discrete_Diff(PL211K,p,PB040);
%discrete_Diff(PL211L,p,PB040);
%discrete_Diff(PH010,p,PB040);
%discrete_Diff(PH020,p,PB040);
%discrete_Diff(PH030,p,PB040);
%discrete_Diff(PH040,p,PB040);
%discrete_Diff(PH050,p,PB040);
%discrete_Diff(PH060,p,PB040);
%discrete_Diff(PH070,p,PB040);