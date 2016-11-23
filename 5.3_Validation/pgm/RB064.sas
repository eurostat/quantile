PROC SQL;
 CREATE TABLE WORK.R64_1 AS SELECT DISTINCT R64.RB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_1" AS Check_code,
	 RB064_N AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN RB064_N > 0  THEN "CONVENTION: There should be no value for RB064 for that year as it doesn't correspond to the last wave in the file(Var_1: Nbr of RB064 filled)"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
	WHERE DB075=. AND RB110=. AND RB100=. AND RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_1 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_3 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_3" AS Check_code,
	 RB064_NMiss AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN Var_1 <> Var_2 THEN "CONVENTION: The number of missing values (Var_1) should be equal to the number of values for RB060 (Var_2) for that year and for that rotational group,
												as it doesn't correspond to the last wave in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.R60 AS R60 ON ((R64.RB010 = R60.RB010) AND (R64.DB075 = R60.DB075) AND (R64.RB100 = R60.RB100) AND (R64.RB110 = R60.RB110))
	WHERE R64.DB075 ne . AND R64.RB110=. AND R64.RB100=. AND R64.RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_3 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_4 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_4" AS Check_code,
	 RB064_N AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN (Var_1 > 0 AND (Y1_DB075.RB010 + 2) = &RYYYY) 
			THEN "ERROR: There should be no value for RB064 (Var_1 Nbr of weights) for that rotational group as there are no 4-years trajectories"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
	WHERE R64.DB075 ne . AND R64.RB110=. AND R64.RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_4 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_6 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_6" AS Check_code,
	 RB064_NMiss AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN ((Var_1 <> Var_2) AND ((Y1_DB075.RB010 + 2) = &RYYYY)) 
			THEN "ERROR: The number of missing values (Var_1) should be equal to the number of values for RB060 (Var_2) for that rotational group as there are no 4-years trajectories"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R64.RB010 = R60.RB010) AND (R64.DB075 = R60.DB075) AND (R64.RB100 = R60.RB100) AND (R64.RB110 = R60.RB110))
	WHERE R64.DB075 ne . AND R64.RB110=. AND R64.RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_6 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_7 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_7" AS Check_code,
	 RB064_N AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN ((Var_1 <> Var_2) AND ((Y1_DB075.RB010 + 2) < &RYYYY)) 
			THEN "ERROR: The number of values (Var_1) should be equal to the number of values for RB060 (Var_2) for that rotational group as there are 4-years trajectories"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R64.RB010 = R60.RB010) AND (R64.DB075 = R60.DB075) AND (R64.RB100 = R60.RB100) AND (R64.RB110 = R60.RB110))
	WHERE R64.DB075 ne . AND R64.RB110=. AND R64.RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_7 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_8 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_8" AS Check_code,
	 RB064_NMiss AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN (Var_1 > 0 AND ((Y1_DB075.RB010 + 2) < &RYYYY)) 
			THEN "ERROR: The number of missing values (Var_1) should be 0 for that rotational group as there are 4-years trajectories"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
	WHERE R64.DB075 ne . AND R64.RB110=. AND R64.RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_8 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_9 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_9" AS Check_code,
	 RB064_0_N AS Var_1,
	 RB060_0_N AS Var_2,
	 (CASE  WHEN (Var_1 < Var_2 AND ((Y1_DB075.RB010 + 2) < &RYYYY)) 
			THEN "ERROR: The number of zero values for RB064 (Var_1) should be greater or equal to the one for RB060 (Var_2), for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R64.RB010 = R60.RB010) AND (R64.DB075 = R60.DB075) AND (R64.RB100 = R60.RB100) AND (R64.RB110 = R60.RB110))
	WHERE R64.DB075 ne . AND R64.RB110=. AND R64.RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_9 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_11 AS SELECT DISTINCT R64.RB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_11" AS Check_code,
	 sum(RB064_Sum,0) AS Var_1,
	 sum(Cr_RB050_Sum,0) AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 < 0.9 * CALCULATED Var_2) OR (CALCULATED Var_1 > 1.03 * CALCULATED Var_2)  
			THEN "WARNING: Sum of the weights for RB064 all rotational groups together (Var_1) must be close to (-10%) the population size (from SILC cross-sectional)(Var_2), for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
  	INNER JOIN WORK.C_POP_NUMBER AS C_POP_NUMBER ON (R64.RB010 = C_POP_NUMBER.RB010)
	WHERE DB075 =. AND RB110=. AND RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_11 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_12 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_12" AS Check_code,
	 sum(RB064_Sum,0) AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 <=0 AND ((Y1_DB075.RB010 + 2) < &RYYYY)) 
			THEN "ERROR: Sum of the weights for members with RB110=1 or 2 (Var_1) should be greater than 0, for rotational groups with 4-years trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
	WHERE R64.DB075 ne . AND R64.RB110 in (1,2) AND R64.RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_12 (WHERE=(PROBLEM ne "OK")) force;
/*
PROC SQL;
 CREATE TABLE WORK.R64_13 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 12 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_13" AS Check_code,
	 SUM(INT(sum(RB064_Sum,0))) AS Var_1,
	 SUM(INT(sum(RB060_Sum,0))) AS Var_2,
	 (CASE  WHEN SUM(INT(sum(RB064_Sum,0))) > SUM(INT(sum(RB060_Sum,0))) AND (Y1_DB075.RB010 + 2) < &RYYYY 
			THEN "ERROR: Sum of the weights for members with RB110=1 or 2 (Var_1) should be less or equal than the one for RB060 (Var_2), for rotational groups with 4-years trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R64.RB010 = R60.RB010) AND (R64.DB075 = R60.DB075) AND (R64.RB100 = R60.RB100) AND (R64.RB110 = R60.RB110))
	WHERE R64.DB075 ne . AND R64.RB110 in (1,2) AND R64.RB100=. AND R64.RB010 = &RYYYY AND R64.RB064_N>0
GROUP BY R64.DB075;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_13 (WHERE=(PROBLEM ne "OK")) force;
*/
PROC SQL;
 CREATE TABLE WORK.R64_14 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 12 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_14" AS Check_code,
	 SUM(INT(sum(RB064_Sum,0))) AS Var_1,
	 SUM(INT(sum(RB060_Sum,0))/(&N_DB075-2)) AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 < (0.9 * CALCULATED Var_2)) OR (CALCULATED Var_1 > (1.015 * CALCULATED Var_2)) AND (Y1_DB075.RB010 + 2) < &RYYYY 
			THEN "WARNING: Sum of the weights for members with RB110=1 or 2 (Var_1) should be close and smaller than the one for RB060 divided by the number of rotational groups (Var_2) (in the interval: -10%,+1.5%)"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R64.RB010 = R60.RB010) AND (R64.DB075 = R60.DB075) AND (R64.RB100 = R60.RB100) AND (R64.RB110 = R60.RB110))
	WHERE R64.DB075 ne . AND R64.RB110 in (1,2) AND R64.RB100=. AND R64.RB010 = &RYYYY AND R64.RB064_N>0
	GROUP BY R64.DB075;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_14 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_15 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_15" AS Check_code,
	 sum(RB064_Sum,0) AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 > 0 AND ((Y1_DB075.RB010 + 2) < &RYYYY)) 
			THEN "CONVENTION: All members with RB110=3 or 4 or 5 or 6 or 7 should have a zero weight (Var_1: Sum of weights), for rotational groups with 4-years trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
	WHERE R64.DB075 ne . AND R64.RB110 in (3,4,5,6,7) AND R64.RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_15 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R64_17 AS SELECT DISTINCT R64.RB010 AS Year,
 	 R64.DB075 AS Rot_grp,
	 R64.RB100 AS S_pers_co_res,
	 R64.RB110 AS Mbr_status,
	 "RB064" AS Weight,
	 "R64_17" AS Check_code,
	 sum(RB064_Sum,0) AS Var_1,
	 (sum(RB060_Sum,0)/(&N_DB075-2)) AS Var_2,
	 (CASE  WHEN ((CALCULATED Var_1 < (0.95 * CALCULATED Var_2) OR (CALCULATED Var_1 > (1.05 * CALCULATED Var_2))) AND ((Y1_DB075.RB010 + 2) < &RYYYY)) 
			THEN "WARNING: Sum of the weights (Var_1) should be around (+-5%) the one for RB060 divided by the number of rotational groups (Var_2), for rotational groups with 4-years trajectories, for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R64 AS R64
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R64.DB075 = Y1_DB075.DB075)
 	INNER JOIN WORK.R60 AS R60 ON ((R64.RB010 = R60.RB010) AND (R64.DB075 = R60.DB075) AND (R64.RB100 = R60.RB100) AND (R64.RB110 = R60.RB110))
	WHERE R64.DB075 ne . AND R64.RB110=. AND R64.RB100=. AND R64.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R64_17 (WHERE=(PROBLEM ne "OK")) force;

