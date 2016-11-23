%macro select3;

	PROC SORT
		DATA=WORK.R60(KEEP=RB060_N RB060_0_N RB060_Sum RB060_NMiss RB010 DB075 RB100 RB110)
		OUT=WORK.R60_sort;
		BY DB075 RB100 RB110;
	RUN;

	PROC TRANSPOSE DATA=WORK.R60_sort
		OUT=R60_trans(LABEL="Transposed WORK.R60")
		PREFIX=Y
		NAME=Source
		LABEL=Label;
		BY DB075 RB100 RB110;
		ID RB010;
		VAR RB060_N RB060_0_N RB060_Sum RB060_NMiss;
	RUN; QUIT;

%if &RYYYY > 2013 %then %do;
	PROC SQL;
	 CREATE TABLE WORK.R60_1 AS SELECT DISTINCT R60.RB010 AS Year,
	 	 R60.DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_1" AS Check_code,
		 RB060_NMiss AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN Var_1 > 0  THEN "ERROR: There should be no missing weights (Var_1: Nbr of missing weights)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.R60 AS R60
	 left join work.Y1_DB075 AS D75 on (R60.DB075=D75.DB075)
	WHERE R60.RB010 ne &RYYYY and R60.DB075 ne . AND RB110=. AND RB100=.;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_1 (WHERE=(PROBLEM ne "OK")) force;
/*
	PROC SQL;
	 CREATE TABLE WORK.R60_1 AS SELECT DISTINCT R60.RB010 AS Year,
	 	 R60.DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_1" AS Check_code,
		 RB060_Sum AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN Var_1 > 0  THEN "CONVENTION: RB060 should not be filled for the last rotational group (Var_1: Sum of RB060 weights)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.R60 AS R60
	 left join work.Y1_DB075 AS D75 on (R60.DB075=D75.DB075) and (R60.RB010 = D75.RB010)
	WHERE R60.RB010 = &RYYYY and R60.DB075 = D75.DB075 AND RB110=. AND RB100=. AND R60.DB075 ne .;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_1 (WHERE=(PROBLEM ne "OK")) force;
	*/
%end;
%else %do;

	PROC SQL;
	 CREATE TABLE WORK.R60_1 AS SELECT DISTINCT R60.RB010 AS Year,
	 	 DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_1" AS Check_code,
		 RB060_NMiss AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN Var_1 > 0  THEN "ERROR: There should be no missing weights (Var_1: Nbr of missing weights)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.R60 AS R60
	WHERE DB075=. AND RB110=. AND RB100=.;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_1 (WHERE=(PROBLEM ne "OK")) force;
%end;

	PROC SQL;
	 CREATE TABLE WORK.R60_2 AS SELECT R60.RB010 AS Year,
	 	 R60.DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_2" AS Check_code,
		 . AS Var_1,
		 . AS Var_2,
		(CASE WHEN RB110 ne 1 THEN
				"ERROR: RB110 (Mbr_status) should equal 1 for everyone in the considered rotational group in the first year of interview"
			 ELSE "OK" END) AS PROBLEM	 
	 FROM WORK.R60 AS R60,
		  WORK.Y1_DB075 AS Y1_DB075
	 WHERE (R60.RB010 = Y1_DB075.RB010 AND R60.DB075 = Y1_DB075.DB075) AND
	 	   (R60.RB100=.  AND R60.RB110 ne . );
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_2 (WHERE=(PROBLEM ne "OK")) force;
/*
	PROC SQL;
	 CREATE TABLE WORK.R60_3 AS SELECT DISTINCT RB010 AS Year,
	 	 DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_3" AS Check_code,
		 RB060_N AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN RB060_N = 0  THEN "ERROR: The sample size in the considered rotational group (Var_1) should be greater than zero for each year after the first year of interview"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.R60 AS R60
	WHERE DB075 ne . AND RB110=. AND RB100=.;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_3 (WHERE=(PROBLEM ne "OK")) force;
*/
	%macro R60_4(y,y1);
		PROC SQL;
		 CREATE TABLE WORK.R60_4 AS SELECT
		 	 &y1 AS Year,
		 	 DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "RB060" AS Weight,
			 "R60_4" AS Check_code,
			 sum(trans.Y&y1,0) AS Var_1,
			 sum(trans.Y&y,0) AS Var_2,
			(CASE WHEN (CALCULATED Var_2*1.01) < CALCULATED Var_1 THEN 
			 	"WARNING: The sample size in a rotational group (Var_1) should normally decrease since previous year (&y Var_2) (increase can rarely happen due to new household members)"
			 	ELSE "OK" END) AS PROBLEM
			FROM WORK.R60_trans AS trans
			WHERE DB075 ne . AND RB100=. AND RB110=. AND Y&y not is missing AND Y&y1 not is missing   AND Source='RB060_N';
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.R60_4 (WHERE=(PROBLEM ne "OK")) force;
	%mend R60_4;
	%R60_4(&y_3,&y_2);
	%R60_4(&y_2,&y_1);
	%R60_4(&y_1,&RYYYY);

	%macro R60_5(y,y1);
		PROC SQL;
		 CREATE TABLE WORK.R60_5 AS SELECT
		 	 &y1 AS Year,
		 	 trans.DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "RB060" AS Weight,
			 "R60_5" AS Check_code,
			 trans.Y&y1 AS Var_1,
			 trans.Y&y AS Var_2,
			(CASE WHEN (Y1_DB075.RB010 = &y) AND ((Var_1 - Var_2)> 0.3 * Var_2 )  THEN 
			 	"WARNING: The sample size in a rotational group (Var_1) should not decrease too much (max 30%) between 1st and 2nd wave (&y Var_2) "
				WHEN (Y1_DB075.RB010 < &y) AND ((Var_1 - Var_2)> 0.2 * Var_2 )  THEN 
			 	"WARNING: The sample size in a rotational group (Var_1) should not decrease too much (max 20%) since previous year (&y Var_2) "
			 	ELSE "OK" END) AS PROBLEM
			FROM WORK.R60_trans AS trans, WORK.Y1_DB075
			WHERE (Y1_DB075.DB075 = trans.DB075) AND trans.DB075 ne . AND RB110=. AND RB100=. AND Y&y not is missing AND Y&y1 not is missing  AND Source='RB060_N';
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.R60_5 (WHERE=(PROBLEM ne "OK")) force;
	%mend R60_5;
	%R60_5(&y_3,&y_2);
	%R60_5(&y_2,&y_1);
	%R60_5(&y_1,&RYYYY);
	
	%macro R60_7(y,y1);
		PROC SQL;
		 CREATE TABLE WORK.R60_7 AS SELECT
		 	 &y1 AS Year,
		 	 DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "RB060" AS Weight,
			 "R60_7" AS Check_code,
			 sum(trans.Y&y1,0) AS Var_1,
			 sum(trans.Y&y,0) AS Var_2,
			(CASE WHEN 1.015 * CALCULATED Var_2 < CALCULATED Var_1 THEN 
			 	"WARNING: Sum of the weights in a rotational group (Var_1) should normally decrease since previous year (&y Var_2) (as the longitudinal population)"
			 	ELSE "OK" END) AS PROBLEM
			FROM WORK.R60_trans AS trans
			WHERE DB075 ne . AND RB110=. AND RB100=. AND Y&y not is missing AND Y&y1 not is missing  AND Source='RB060_Sum';
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.R60_7 (WHERE=(PROBLEM ne "OK")) force;
	%mend R60_7;
	%R60_7(&y_3,&y_2);
	%R60_7(&y_2,&y_1);
	%R60_7(&y_1,&RYYYY);

	%macro R60_8(y,y1);
		PROC SQL;
		 CREATE TABLE WORK.R60_8 AS SELECT
		 	 &y1 AS Year,
		 	 DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "RB060" AS Weight,
			 "R60_8" AS Check_code,
			 sum(trans.Y&y1,0) AS Var_1,
			 sum(trans.Y&y,0) AS Var_2,
			(CASE WHEN ((CALCULATED Var_2 - CALCULATED Var_1)> 0.1 * CALCULATED Var_2 )  THEN 
			 	"WARNING: Sum of the weights in a rotational group (Var_1) should not decrease too much (max 10%) since previous year (&y Var_2) "
			 	ELSE "OK" END) AS PROBLEM
			FROM WORK.R60_trans AS trans
			WHERE DB075 ne . AND RB110=. AND RB100=. AND Y&y not is missing AND Y&y1 not is missing
				 AND Source='RB060_Sum';
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.R60_8 (WHERE=(PROBLEM ne "OK")) force;
	%mend R60_8;
	%R60_8(&y_3,&y_2);
	%R60_8(&y_2,&y_1);
	%R60_8(&y_1,&RYYYY);

	PROC SQL;
	 CREATE TABLE WORK.R60_10 AS SELECT DISTINCT R60.RB010 AS Year,
	 	 R60.DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_10" AS Check_code,
		 sum(RB060_Sum,0) AS Var_1,
		 sum(Cr_RB050_Sum,0) AS Var_2,
		 (CASE  WHEN (CALCULATED Var_1 < 0.9 * CALCULATED Var_2) OR (CALCULATED Var_1 > 1.03 * CALCULATED Var_2)  
				THEN "WARNING: Sum of Weights in a rotational group (Var_1) should be close to and smaller than the SILC cross-sectional Sum Of weight (Var_2) (in the interval: -10%,+3%) "
				ELSE "OK" END ) AS PROBLEM 
	 	FROM WORK.R60 AS R60
	  	INNER JOIN WORK.C_POP_NUMBER AS C_POP_NUMBER ON (R60.RB010 = C_POP_NUMBER.RB010)
		left join work.Y1_DB075 AS D75 on (R60.DB075=D75.DB075)
		WHERE D75.RB010 ne &RYYYY AND R60.DB075 ne . AND RB110=. AND RB100=.; /*D75.RB010 ne &RYYYY eliminates the last rot grp*/
		
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_10 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.R60_11 AS SELECT R60.RB010 AS Year,
	 	 R60.DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_11" AS Check_code,
		 RB060_NMiss AS Var_1,
		 . AS Var_2,
		(CASE WHEN Var_1 > 0 THEN
				"ERROR: There should be no zero weight in the first year of interview (Var_1 Number of zero weights)"
			 ELSE "OK" END) AS PROBLEM	 
	 	FROM WORK.R60 AS R60,
		  WORK.Y1_DB075 AS Y1_DB075
	 	WHERE (R60.RB010 = Y1_DB075.RB010 AND R60.DB075 = Y1_DB075.DB075) AND
	 	   (R60.RB100=.  AND R60.RB110=. AND Y1_DB075.RB010 ne &RYYYY );
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_11 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.R60_12 AS SELECT DISTINCT R60.RB010 AS Year,
	 	 R60.DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_12" AS Check_code,
		 RB060_0_N AS Var_1,
		 (0.5*RB060_N) AS Var_2,
		 (CASE  WHEN (Var_1 > CALCULATED Var_2)  
				THEN "WARNING: The number of zero weights (Var_1) should be smaller than 1/2 of the sample size (Var_2) for the considered rotational group and the considered year"
				ELSE "OK" END ) AS PROBLEM 
	 	FROM WORK.R60 AS R60
		left join work.Y1_DB075 AS D75 on (R60.DB075=D75.DB075)
		WHERE R60.DB075 ne . AND D75.RB010 ne &RYYYY AND RB110=. AND RB100=.;
	QUIT;

	proc append base=work.WEIGHT_Pb data=WORK.R60_12 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.R60_13 AS SELECT R60.RB010 AS Year,
	 	 R60.DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_13" AS Check_code,
		 RB060_0_N AS Var_1,
		 . AS Var_2,
		(CASE WHEN Var_1 > 0 AND RB110 in (1,2) THEN
				"ERROR: There should be no zero weight in the 2nd year of interview (Var_1 Number of zero weights)for members with RB110=1 or 2"
			 ELSE "OK" END) AS PROBLEM	 
	 	FROM WORK.R60 AS R60,
		  WORK.Y1_DB075 AS Y1_DB075
	 	WHERE (R60.RB010 = Y1_DB075.Y2 AND R60.DB075 = Y1_DB075.DB075) AND
	 	   (R60.RB100=.  AND R60.RB110 ne . );
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_13 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.R60_15 AS SELECT RB010 AS Year,
	 	 DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_15" AS Check_code,
		 sum(RB060_Sum,0) AS Var_1,
		 . AS Var_2,
		(CASE WHEN CALCULATED Var_1 > 0 THEN
				"WARNING: Members with RB110=3 should receive a zero weight except if they are immigrants (Var_1 Sum of weights)"
			 ELSE "OK" END) AS PROBLEM	 
	 FROM WORK.R60 AS R60
	 WHERE (DB075 ne . AND RB100=. AND RB110=3 );
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_15 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.R60_17 AS SELECT RB010 AS Year,
	 	 DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_17" AS Check_code,
		 RB060_N AS Var_1,
		 sum(RB060_Sum,0) AS Var_2,
		(CASE WHEN (Var_1 > 0 AND CALCULATED Var_2 = 0 ) THEN
				"CONVENTION: Newly born (RB110=4) should receive the weight of their mother (Var_1 Nbr of Newborn, Var_2 Sum of Newborn weights)"
			 ELSE "OK" END) AS PROBLEM	 
	 FROM WORK.R60 AS R60
	 WHERE (DB075 ne . AND RB100=. AND RB110=4 );
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_17 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.R60_18 AS SELECT RB010 AS Year,
	 	 DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "RB060" AS Weight,
		 "R60_18" AS Check_code,
		 sum(RB060_Sum,0) AS Var_1,
		 . AS Var_2,
		(CASE WHEN (CALCULATED Var_1 > 0 ) THEN
				"CONVENTION: All members with RB110=5 or 6 or 7 should have a zero weight (Var_1 Sum of weights)"
			 ELSE "OK" END) AS PROBLEM	 
	 FROM WORK.R60 AS R60
	 WHERE (DB075 ne . AND RB100=. AND RB110 in (5,6,7) );
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.R60_18 (WHERE=(PROBLEM ne "OK")) force;

%mend select3;
%select3;
















