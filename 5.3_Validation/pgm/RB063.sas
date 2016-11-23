%macro RB063;
PROC SQL;
 CREATE TABLE WORK.R63_1 AS SELECT DISTINCT R63.RB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_1" AS Check_code,
	 RB063_N AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN Var_1 > 0  THEN "CONVENTION: There should be no value for RB063 for that year as it doesn't correspond to the last wave in the file(Var_1: Nbr of RB063 filled)"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
	WHERE DB075=. AND RB110=. AND RB100=. AND RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_1 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_3 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_3" AS Check_code,
	 RB063_NMiss AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN Var_1 <> Var_2  THEN "CONVENTION: The number of missing values (Var_1) should be equal to the number of values for RB060 (Var_2) for that year and for that rotational group, as it doesn't correspond to the last wave in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.R60 AS R60 ON ((R63.RB010 = R60.RB010) AND (R63.DB075 = R60.DB075) AND (R63.RB100 = R60.RB100) AND (R63.RB110 = R60.RB110))
	WHERE R63.DB075 ne . AND R63.RB110=. AND R63.RB100=. AND R63.RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_3 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_4 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_4" AS Check_code,
	 RB063_N AS Var_1,
	 Y1_DB075.RB010 AS Var_2,
	 (CASE  WHEN (Var_1 > 0 AND (Y1_DB075.RB010 + 1) = &RYYYY) 
			THEN "ERROR: RB063 should be empty (Var_1 Nbr of weights) for that rotational group as there are no 3-year trajectories(Var_2: first year in the survey)"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
	WHERE R63.DB075 ne . AND R63.RB110=. AND R63.RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_4 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_6 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_6" AS Check_code,
	 RB063_NMiss AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN ((Var_1 <> Var_2) AND ((Y1_DB075.RB010 + 1) = &RYYYY)) 
			THEN "ERROR: The number of missing values (Var_1) should be equal to the number of values for RB060 (Var_2) for that rotational group as there are no 3-year trajectories"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R63.RB010 = R60.RB010) AND (R63.DB075 = R60.DB075) AND (R63.RB100 = R60.RB100) AND (R63.RB110 = R60.RB110))
	WHERE R63.DB075 ne . AND R63.RB110=. AND R63.RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_6 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_7 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_7" AS Check_code,
	 RB063_N AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN ((Var_1 <> Var_2) AND ((Y1_DB075.RB010 + 1) < &RYYYY)) 
			THEN "ERROR: The number of values (Var_1) should be equal to the number of values for RB060 (Var_2) for that rotational group as there are 3-year trajectories"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R63.RB010 = R60.RB010) AND (R63.DB075 = R60.DB075) AND (R63.RB100 = R60.RB100) AND (R63.RB110 = R60.RB110))
	WHERE R63.DB075 ne . AND R63.RB110=. AND R63.RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_7 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_8 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_8" AS Check_code,
	 RB063_NMiss AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN (Var_1 > 0 AND ((Y1_DB075.RB010 + 1) < &RYYYY)) 
			THEN "ERROR: The number of missing values (Var_1) should be 0 for that rotational group as there are 3-year trajectories"
			ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.R63 AS R63
	 INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
	 WHERE R63.DB075 ne . AND R63.RB110=. AND R63.RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_8 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_9 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_9" AS Check_code,
	 RB063_0_N AS Var_1,
	 RB060_0_N AS Var_2,
	 (CASE  WHEN (Var_1 < Var_2 AND ((Y1_DB075.RB010 + 1) < &RYYYY)) 
			THEN "ERROR: The number of zero values for RB063 (Var_1) should be greater or equal to the one for RB060 (Var_2),for rotational groups with 3-year trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R63.RB010 = R60.RB010) AND (R63.DB075 = R60.DB075) AND (R63.RB100 = R60.RB100) AND (R63.RB110 = R60.RB110))
	WHERE R63.DB075 ne . AND R63.RB110=. AND R63.RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_9 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_11 AS SELECT DISTINCT R63.RB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_11" AS Check_code,
	 sum(RB063_Sum,0) AS Var_1,
	 sum(Cr_RB050_Sum,0) AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 < 0.9 * CALCULATED Var_2) OR (CALCULATED Var_1 > 1.03 * CALCULATED Var_2)  
			THEN "WARNING: Sum of the weights for RB063 all rotational groups together (Var_1) must be close to (-10%, +3%) the population size (from SILC cross-sectional)(Var_2), for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
  	INNER JOIN WORK.C_POP_NUMBER AS C_POP_NUMBER ON (R63.RB010 = C_POP_NUMBER.RB010)
	WHERE DB075 =. AND RB110=. AND RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_11 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_12 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_12" AS Check_code,
	 sum(RB063_Sum,0) AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 <= 0 AND ((Y1_DB075.RB010 + 1) < &RYYYY)) 
			THEN "ERROR: Sum of the weights for members with RB110=1 or 2 (Var_1) should be greater than 0, for rotational groups with 3-year trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
	WHERE R63.DB075 ne . AND R63.RB110 in (1,2) AND R63.RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_12 (WHERE=(PROBLEM ne "OK")) force;
/*
PROC SQL;
 CREATE TABLE WORK.R63_13 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 12 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_13" AS Check_code,
	 SUM(sum(INT(RB063_Sum),0)) AS Var_1,
	 SUM(sum(INT(RB060_Sum),0)) AS Var_2,
	 (CASE  WHEN (INT(RB063_Sum) > INT(RB060_Sum) AND ((Y1_DB075.RB010 + 1) < &yy2)) 
			THEN "ERROR: Sum of the weights for members with RB110=1 or 2 (Var_1) should be less or equal than the one for RB060 (Var_2), for rotational groups with 3-year trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R63.RB010 = R60.RB010) AND (R63.DB075 = R60.DB075) AND (R63.RB100 = R60.RB100) AND (R63.RB110 = R60.RB110))
	WHERE R63.DB075 ne . AND R63.RB110 in (1,2) AND R63.RB100=. AND R63.RB010 = &yy2
	GROUP BY R63.DB075;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_13 (WHERE=(PROBLEM ne "OK")) force;
*/
PROC SQL;
 CREATE TABLE WORK.R63_14 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 12 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_14" AS Check_code,
	 SUM(INT(sum(RB063_Sum,0))) AS Var_1,
	 SUM(INT((sum(RB060_Sum,0)/(&N_DB075-1)))) AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 < (0.9 * CALCULATED Var_2)) OR (CALCULATED Var_1 > (1.015 * CALCULATED Var_2)) AND (Y1_DB075.RB010 + 1) < &RYYYY
			THEN "WARNING: Sum of weights for members with RB110=1 or 2 (Var_1) should be close (-10%,+1.5%)to RB060 divided by the number of rotational groups (Var_2) for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R63.RB010 = R60.RB010) AND (R63.DB075 = R60.DB075) AND (R63.RB100 = R60.RB100) AND (R63.RB110 = R60.RB110))
	WHERE R63.DB075 ne . AND R63.RB110 in (1,2) AND R63.RB100=. AND R63.RB010 = &RYYYY AND R63.RB063_N>0
	GROUP BY R63.DB075;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_14 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_15 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_15" AS Check_code,
	 sum(RB063_Sum,0) AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 > 0 AND ((Y1_DB075.RB010 + 1) < &RYYYY)) 
			THEN "CONVENTION: All members with RB110=3 or 4 or 5 or 6 or 7 should have a zero weight (Var_1: Sum of weights), for rotational groups with 3-year trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R63.DB075 = Y1_DB075.DB075)
	WHERE R63.DB075 ne . AND R63.RB110 in (3,4,5,6,7) AND R63.RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_15 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R63_17 AS SELECT DISTINCT R63.RB010 AS Year,
 	 R63.DB075 AS Rot_grp,
	 R63.RB100 AS S_pers_co_res,
	 R63.RB110 AS Mbr_status,
	 "RB063" AS Weight,
	 "R63_17" AS Check_code,
	 sum(RB063_Sum,0) AS Var_1,
%if &ss = r %then %do;
	 (sum(RB060_Sum,0)/(&N_DB075 + 1)) AS Var_2,
%end;
%else %do;
	 (sum(RB060_Sum,0)/&N_DB075) AS Var_2,
%end;
	 (CASE  WHEN (CALCULATED Var_1 < (0.95 * CALCULATED Var_2) OR (CALCULATED Var_1 > (1.05 * CALCULATED Var_2)))
			THEN "ERROR: Sum of the weights (Var_1) should be around (+-5%) the one for RB060 divided by the number of rotational groups (Var_2), for rotational groups with 3-year trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R63 AS R63
 	INNER JOIN WORK.R60 AS R60 ON ((R63.RB010 = R60.RB010) AND (R63.DB075 = R60.DB075) AND (R63.RB100 = R60.RB100) AND (R63.RB110 = R60.RB110))
	WHERE R63.DB075 = . AND R63.RB110=. AND R63.RB100=. AND R63.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R63_17 (WHERE=(PROBLEM ne "OK")) force;
%mend RB063;
%RB063;


