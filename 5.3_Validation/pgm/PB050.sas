PROC SORT
	DATA=WORK.P50(KEEP=PB050_N PB050_0_N PB050_Sum PB050_NMiss PB010 DB075 RB100 RB110)
	OUT=WORK.P50_sort;
	BY DB075 RB100 RB110;
RUN;

PROC TRANSPOSE DATA=WORK.P50_sort
	OUT=P50_trans(LABEL="Transposed WORK.P50")
	PREFIX=Y
	NAME=Source
	LABEL=Label;
	BY DB075 RB100 RB110;
	ID PB010;
	VAR PB050_N PB050_0_N PB050_Sum PB050_NMiss;
RUN; QUIT;
/*
PROC SQL;
 CREATE TABLE WORK.P50_1 AS SELECT DISTINCT P50.PB010 AS Year,
 	 P50.DB075 AS Rot_grp,
	 P50.RB100 AS S_pers_co_res,
	 P50.RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_1" AS Check_code,
	 PB050_Sum AS Var_1,
	 Y1_DB075.RB010 AS Var_2,
	 (CASE  WHEN (Var_1 > 0 AND Var_2 = &RYYYY) 
			THEN "CONVENTION: PB050 should = 0 (Var_1 Sum of weights) for that rotational group as there are no 2-year trajectories(Var_2: first year in the survey) "
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.P50 AS P50
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (P50.DB075 = Y1_DB075.DB075)
	WHERE P50.DB075 ne . AND P50.RB110=. AND P50.RB100=. AND P50.PB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_1 (WHERE=(PROBLEM ne "OK")) force;
*/
PROC SQL;
 CREATE TABLE WORK.P50_2 AS SELECT DISTINCT P50.PB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_2" AS Check_code,
	 PB050_NMiss AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN Var_1 > 0  THEN "ERROR: There should be no missing weights (Var_1: Nbr of missing weights)"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.P50 AS P50
	WHERE DB075=. AND RB110=. AND RB100=.;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_2 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.P50_3 AS SELECT P50.PB010 AS Year,
 	 P50.DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_3" AS Check_code,
	 PB050_N AS Var_1,
	 . AS Var_2,
	(CASE WHEN RB110 ne 1 THEN
			"ERROR: RB110 (Mbr_status) should equal 1 for everyone in the considered rotational group in the first year of interview (Var_1 Nbr of cases)"
		 ELSE "OK" END) AS PROBLEM	 
 	FROM WORK.P50 AS P50,
	  WORK.Y1_DB075 AS Y1_DB075
 	WHERE (P50.PB010 = Y1_DB075.RB010 AND P50.DB075 = Y1_DB075.DB075) AND
 	   (P50.RB100=.  AND P50.RB110 ne . );
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_3 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.P50_4 AS SELECT DISTINCT PB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_4" AS Check_code,
	 PB050_N AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN PB050_N = 0  THEN "ERROR: The sample size in the considered rotational group (Var_1) should be greater than zero for each year after the first year of interview"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.P50 AS P50
	WHERE DB075 ne . AND RB110=. AND RB100=.;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_4 (WHERE=(PROBLEM ne "OK")) force;

%macro P50_5(y,y1);
	PROC SQL;
	 CREATE TABLE WORK.P50_5 AS SELECT
	 	 &y1 AS Year,
	 	 DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "PB050" AS Weight,
		 "P50_5" AS Check_code,
		 trans.Y&y1 AS Var_1,
		 trans.Y&y AS Var_2,
		(CASE WHEN Var_2 < Var_1 THEN 
		 	"WARNING: The sample size in a rotational group (Var_1) should normally decrease since previous year (&y Var_2) (increase can rarely happen due to new household members)"
		 	ELSE "OK" END) AS PROBLEM
		FROM WORK.P50_trans AS trans
		WHERE DB075 ne . AND RB100=. AND RB110=. AND Y&y not is missing AND Y&y1 not is missing   AND Source='PB050_N';
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.P50_5 (WHERE=(PROBLEM ne "OK")) force;
%mend P50_5;
%P50_5(&y_3,&y_2);
%P50_5(&y_2,&y_1);
%P50_5(&y_1,&RYYYY);

%macro P50_6(y,y1);
	PROC SQL;
	 CREATE TABLE WORK.P50_6 AS SELECT
	 	 &y1 AS Year,
	 	 trans.DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "PB050" AS Weight,
		 "P50_6" AS Check_code,
		 trans.Y&y1 AS Var_1,
		 trans.Y&y AS Var_2,
		(CASE WHEN (Y1_DB075.RB010 = &y) AND ((trans.Y&y - trans.Y&y1)> 0.3*trans.Y&y )  THEN 
		 	"WARNING: The sample size in a rotational group (Var_1) should not decrease too much (max 30%) between 1st and second wave (&y Var_2) "
			WHEN (Y1_DB075.RB010 > &y) AND ((trans.Y&y - trans.Y&y1)> 0.2*trans.Y&y )  THEN 
		 	"WARNING: The sample size in a rotational group (Var_1) should not decrease too much (max 20%) since previous year (&y Var_2) "
		 	ELSE "OK" END) AS PROBLEM
		FROM WORK.P50_trans AS trans, WORK.Y1_DB075
		WHERE (trans.DB075 = Y1_DB075.DB075) AND trans.DB075 ne . AND RB110=. AND RB100=. AND Y&y not is missing AND Y&y1 not is missing  AND Source='PB050_N';
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.P50_6 (WHERE=(PROBLEM ne "OK")) force;
%mend P50_6;
%P50_6(&y_3,&y_2);
%P50_6(&y_2,&y_1);
%P50_6(&y_1,&RYYYY);

PROC SQL;
 CREATE TABLE WORK.P50_7 AS SELECT DISTINCT P50.PB010 AS Year,
 	 P50.DB075 AS Rot_grp FORMAT DB075f.,
	 P50.RB100 AS S_pers_co_res,
	 P50.RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_7" AS Check_code,
	 PB050_N AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN ((PB050_N < 0.7*RB060_N ) OR (PB050_N > 0.9*RB060_N))  
			THEN "WARNING: The sample size in a rotational group (Var_1) should be in 70-90% of RB060 (Var_2) (like proportion of people aged 16+ in total population)"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.P50 AS P50
  	INNER JOIN WORK.R60 AS R60 ON (P50.PB010 = R60.RB010) AND (P50.DB075 = R60.DB075) AND (P50.RB100 = R60.RB100)
  							AND (P50.RB110 = R60.RB110)
	WHERE P50.DB075 ne . AND P50.RB110=. AND P50.RB100=.;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_7 (WHERE=(PROBLEM ne "OK")) force;

%macro P50_8(y,y1);
	PROC SQL;
	 CREATE TABLE WORK.P50_8 AS SELECT
	 	 &y1 AS Year,
	 	 DB075 AS Rot_grp,
		 RB100 AS S_pers_co_res,
		 RB110 AS Mbr_status,
		 "PB050" AS Weight,
		 "P50_8" AS Check_code,
		 sum(trans.Y&y1,0) AS Var_1,
		 sum(trans.Y&y,0) AS Var_2,
		(CASE WHEN ((trans.Y&y - trans.Y&y1)> 0.1*trans.Y&y )  THEN 
		 	"WARNING: Sum of the weights in a rotational group (Var_1) should not decrease too much (max 10%) since previous year (&y Var_2) "
		 	ELSE "OK" END) AS PROBLEM
		FROM WORK.P50_trans AS trans
		WHERE DB075 ne . AND RB110=. AND RB100=. AND Y&y not is missing AND Y&y1 not is missing
			 AND Source='PB050_Sum';
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.P50_8 (WHERE=(PROBLEM ne "OK")) force;
%mend P50_8;
%P50_8(&y_3,&y_2);
%P50_8(&y_2,&y_1);
%P50_8(&y_1,&RYYYY);

PROC SQL;
 CREATE TABLE WORK.P50_9 AS SELECT DISTINCT P50.PB010 AS Year,
 	 P50.DB075 AS Rot_grp FORMAT DB075f.,
	 P50.RB100 AS S_pers_co_res,
	 P50.RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_9" AS Check_code,
	 sum(PB050_Sum,0) AS Var_1,
	 sum(RB060_Sum,0) AS Var_2,
	 (CASE  WHEN ((PB050_Sum < 0.7*RB060_Sum ) OR (PB050_Sum > 0.9*RB060_Sum))  
			THEN "WARNING: Sum of weights in a rotational group (Var_1) should be in 70-90% of RB060 (Var_2) (like proportion of people aged 16+ in total population)"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.P50 AS P50
  	INNER JOIN WORK.R60 AS R60 ON (P50.PB010 = R60.RB010) AND (P50.DB075 = R60.DB075) AND (P50.RB100 = R60.RB100)
  							AND (P50.RB110 = R60.RB110)
	WHERE P50.DB075 ne . AND P50.RB110=. AND P50.RB100=.;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_9 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.P50_10 AS SELECT P50.PB010 AS Year,
 	 P50.DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_10" AS Check_code,
	 PB050_0_N AS Var_1,
	 PB050_N AS Var_2,
	(CASE WHEN PB050_0_N > (0.1*PB050_N) THEN
			"ERROR: The number of zero weight in the first year of interview should be quite limited (Var_1 Number of zero weights) (individual non response)"
		 ELSE "OK" END) AS PROBLEM	 
 	FROM WORK.P50 AS P50,
	  WORK.Y1_DB075 AS Y1_DB075
 	WHERE (P50.PB010 = Y1_DB075.RB010 AND P50.DB075 = Y1_DB075.DB075) AND
 	   (P50.RB100=.  AND P50.RB110=. ) AND P50.PB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_10 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.P50_11 AS SELECT DISTINCT P50.PB010 AS Year,
 	 P50.DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_11" AS Check_code,
	 PB050_0_N AS Var_1,
	 (0.5*PB050_N) AS Var_2,
	 (CASE  WHEN (PB050_0_N >= 0.5*PB050_N)  
			THEN "WARNING: The number of zero weights (Var_1) should be smaller than 1/2 of the sample size (Var_2) for the considered rotational group and the considered year"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.P50 AS P50
	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (P50.DB075 = Y1_DB075.DB075)
	WHERE P50.DB075 ne . AND RB110=. AND RB100=. AND Y1_DB075.RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_11 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.P50_12 AS SELECT P50.PB010 AS Year,
 	 P50.DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "PB050" AS Weight,
	 "P50_12" AS Check_code,
	 PB050_0_N AS Var_1,
	 PB050_N AS Var_2,
	 (CASE WHEN PB050_0_N > (0.1*PB050_N) THEN
			"ERROR: The number of zero weight in the second year of interview (Var_1) should be quite limited (smaller than 10% of the Sample size(Var_2)) (individual non response) for members with RB110=1 or 2"
		ELSE "OK" END) AS PROBLEM	 
 	FROM WORK.P50 AS P50,
	  WORK.Y1_DB075 AS Y1_DB075
 	WHERE (P50.PB010 = Y1_DB075.Y2 AND P50.DB075 = Y1_DB075.DB075) AND
 	   (P50.RB100=.  AND P50.RB110 in (1,2) );
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_12 (WHERE=(PROBLEM ne "OK")) force;

%macro sel_ctr;
	%if (&cc=dk OR &cc=fi OR &cc=is OR &cc=nl OR &cc=no OR &cc=se OR &cc=si) %then %do;
		PROC SQL;
		 CREATE TABLE WORK.P50_13 AS SELECT P50.PB010 AS Year,
		 	 P50.DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB050" AS Weight,
			 "P50_13" AS Check_code,
			 PB050_N AS Var_1,
			 PB050_0_N AS Var_2,
			 (CASE WHEN (PB050_0_N ne . AND PB050_0_N = PB050_N) THEN
					"WARNING: There should be some coresidents with non zero weight (Var_1 Number of coresidents and Var_2 Number of zero weights)"
				 ELSE "OK" END) AS PROBLEM	 
		 FROM WORK.P50 AS P50
		 WHERE (P50.RB100=2  AND P50.RB110=. AND DB075 ne . );
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P50_13 (WHERE=(PROBLEM ne "OK")) force;
	%end;
%mend sel_ctr;
%sel_ctr;

PROC SQL;
 CREATE TABLE WORK.P50_14 AS SELECT P50.PB010 AS Year,
       DB075 AS Rot_grp,
       RB100 AS S_pers_co_res,
       RB110 AS Mbr_status,
       "PB050" AS Weight,
       "P50_14" AS Check_code,
       sum(PB050_Sum,0) AS Var_1,
       . AS Var_2,
      (CASE WHEN PB050_Sum >0 THEN
                  "WARNING: Members with RB110=3 should receive a zero weight except if they are immigrants (Var_1 Sum of weights)"
             ELSE "OK" END) AS PROBLEM    
 	FROM WORK.P50 AS P50
 	WHERE (DB075 ne . AND RB100=. AND RB110=3 );
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_14 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.P50_15 AS SELECT P50.PB010 AS Year,
       P50.DB075 AS Rot_grp,
       P50.RB100 AS S_pers_co_res,
       P50.RB110 AS Mbr_status,
       "PB050" AS Weight,
       "P50_15" AS Check_code,
       ( PB050_0_N / PB050_N ) AS Var_1,
       ( RB060_0_N / RB060_N )  AS Var_2,
      (CASE WHEN (PB050_0_N/PB050_N < 0.8*(RB060_0_N/RB060_N)) OR (PB050_0_N/PB050_N > 1.2*(RB060_0_N/RB060_N))
            THEN "ERROR:the ratio number of zero weights / sample size for PB050 (Var_1) should be close (+-20%) to the ratio number of zero weights / sample size for RB060 (Var_2) "
             ELSE "OK" END) AS PROBLEM    
 	FROM WORK.P50 AS P50
  	INNER JOIN WORK.R60 AS R60 ON (P50.PB010 = R60.RB010) AND (P50.DB075 = R60.DB075) AND (P50.RB100 = R60.RB100)
  							AND (P50.RB110 = R60.RB110)
 	WHERE (P50.DB075 ne . AND P50.RB100=. AND P50.RB110=3 );
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.P50_15 (WHERE=(PROBLEM ne "OK")) force;

