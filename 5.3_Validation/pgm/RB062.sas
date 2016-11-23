
%macro RB062;
PROC SQL;
 CREATE TABLE WORK.R62_1 AS SELECT DISTINCT R62.RB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_1" AS Check_code,
	 RB062_N AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN Var_1 > 0  THEN "CONVENTION: There should be no value for RB062 for that year as it doesn't correspond to the last wave in the file(Var_1: Nbr of RB062 filled)"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
	WHERE DB075=. AND RB110=. AND RB100=. AND RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_1 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_2 AS SELECT DISTINCT R62.RB010 AS Year,
 	 R62.DB075 AS Rot_grp,
	 R62.RB100 AS S_pers_co_res,
	 R62.RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_2" AS Check_code,
	 RB062_N AS Var_1,
	 Y1_DB075.RB010 AS Var_2,
	 (CASE  WHEN (Var_1 > 0 AND Y1_DB075.RB010 = &RYYYY) 
			THEN "ERROR: RB062 should be empty (Var_1 Nbr of weights) for that rotational group as there are no 2-year trajectories(Var_2: first year in the survey) "
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (R62.DB075 = Y1_DB075.DB075)
	WHERE R62.DB075 ne . AND R62.RB110=. AND R62.RB100=. AND R62.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_2 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_3 AS SELECT DISTINCT R62.RB010 AS Year,
 	 R62.DB075 AS Rot_grp,
	 R62.RB100 AS S_pers_co_res,
	 R62.RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_3" AS Check_code,
	 RB062_NMiss AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN Var_1 <> Var_2  THEN "CONVENTION: The number of missing values (Var_1) should be equal to the number of values for RB060 (Var_2) for that year and for that rotational group, as it doesn't correspond to the last wave in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
 	INNER JOIN WORK.R60 AS R60 ON ((R62.RB010 = R60.RB010) AND (R62.DB075 = R60.DB075) AND (R62.RB100 = R60.RB100) AND (R62.RB110 = R60.RB110))
	WHERE R62.DB075 ne . AND R62.RB110=. AND R62.RB100=. AND R62.RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_3 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_4 AS SELECT DISTINCT R62.RB010 AS Year,
 	 R62.DB075 AS Rot_grp,
	 R62.RB100 AS S_pers_co_res,
	 R62.RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_4" AS Check_code,
	 RB062_N AS Var_1,
	 RB060_N AS Var_2,
	 (CASE  WHEN Var_1 <> Var_2  THEN "ERROR: The number of (non-missing) values for RB062 (Var_1) should be equal to the one for RB060 (Var_2), as it corresponds to the last year in the file"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
 	INNER JOIN WORK.R60 AS R60 ON ((R62.RB010 = R60.RB010) AND (R62.DB075 = R60.DB075) AND (R62.RB100 = R60.RB100) AND (R62.RB110 = R60.RB110))
	left join work.Y1_DB075 AS D75 on (R62.DB075=D75.DB075)
	WHERE R62.DB075 ne . AND R62.RB110=. AND R62.RB100=. AND R62.RB010 = &RYYYY AND D75.RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_4 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_5 AS SELECT DISTINCT R62.RB010 AS Year,
 	 R62.DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_5" AS Check_code,
	 RB062_NMiss AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN Var_1 > 0  THEN "ERROR: The number of missing values (Var_1) should be 0 for that rotational group as there are 2-year trajectories"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
	left join work.Y1_DB075 AS D75 on (R62.DB075=D75.DB075)
	WHERE R62.DB075 ne . AND RB110=. AND RB100=. AND R62.RB010 = &RYYYY AND D75.RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_5 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_6 AS SELECT DISTINCT R62.RB010 AS Year,
 	 R62.DB075 AS Rot_grp,
	 R62.RB100 AS S_pers_co_res,
	 R62.RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_6" AS Check_code,
	 RB062_0_N AS Var_1,
	 RB060_0_N AS Var_2,
	 (CASE  WHEN Var_1 < Var_2  THEN "ERROR: The number of zero values for RB062 (Var_1) should be greater or equal to the one for RB060 (Var_2), for the last year in the file"  ELSE "OK" END ) AS PROBLEM 
 FROM WORK.R62 AS R62
 INNER JOIN WORK.R60 AS R60 ON ((R62.RB010 = R60.RB010) AND (R62.DB075 = R60.DB075) AND (R62.RB100 = R60.RB100) AND (R62.RB110 = R60.RB110))
left join work.Y1_DB075 AS D75 on (R62.DB075=D75.DB075)
WHERE R62.DB075 ne . AND R62.RB110=. AND R62.RB100=. AND R62.RB010 = &RYYYY AND D75.RB010 ne &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_6 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_8 AS SELECT DISTINCT R62.RB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_8" AS Check_code,
	 sum(0,RB062_Sum) AS Var_1,
	 Cr_RB050_Sum AS Var_2,
	 (CASE  WHEN (CALCULATED Var_1 < 0.9 * Var_2) OR (CALCULATED Var_1 > 1.03 * Var_2)  
			THEN "WARNING: Sum of the weights for RB062 all rotational groups together (Var_1) must be close to (-10% to +3%) the population size (from SILC cross-sectional)(Var_2), for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
  	INNER JOIN WORK.C_POP_NUMBER AS C_POP_NUMBER ON (R62.RB010 = C_POP_NUMBER.RB010)
	WHERE DB075 =. AND RB110=. AND RB100=. AND R62.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_8 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_9 AS SELECT DISTINCT R62.RB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_9" AS Check_code,
	 sum(RB062_Sum,0) AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN CALCULATED Var_1 = 0  THEN "ERROR: Sum of the weights for members with RB110=1 or 2 (VAR_1) should be greater than 0 for the last year in the file"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
	WHERE DB075=. AND RB110 in (1,2) AND RB100=. AND RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_9 (WHERE=(PROBLEM ne "OK")) force;
/*
PROC SQL;
 CREATE TABLE WORK.R62_10 AS SELECT DISTINCT R62.RB010 AS Year,
 	 R62.DB075 AS Rot_grp,
	 R62.RB100 AS S_pers_co_res,
	 R62.RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_10" AS Check_code,
	 sum(INT(RB062_Sum),0) AS Var_1,
	 sum(INT(RB060_Sum),0) AS Var_2,
	 (CASE  WHEN INT(RB062_Sum) > INT(RB060_Sum)  THEN "ERROR: Sum of the weights for members with RB110=1 or 2 (Var_1) should be less or equal than the one for RB060 (Var_2) for the last year in the file"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
 	INNER JOIN WORK.R60 AS R60 ON ((R62.RB010 = R60.RB010) AND (R62.DB075 = R60.DB075) AND (R62.RB100 = R60.RB100) AND (R62.RB110 = R60.RB110))
	WHERE R62.DB075 =. AND R62.RB110 in (1,2) AND R62.RB100=. AND R62.RB010 = &yy2;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_10 (WHERE=(PROBLEM ne "OK")) force;
*/
PROC SQL;
CREATE TABLE WORK.R62_11 AS SELECT DISTINCT R62.RB010 AS Year,
 	 R62.DB075 AS Rot_grp,
	 R62.RB100 AS S_pers_co_res,
	 12 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_11" AS Check_code,
	 SUM(sum(RB062_Sum,0)) AS Var_1,
%if &ss = r %then %do;
	 SUM(sum(RB060_Sum,0)/(&N_DB075 + 1)) AS Var_2,
%end;
%else %do;
	 SUM((sum(RB060_Sum,0)/&N_DB075)) AS Var_2,
%end;
	 (CASE  WHEN (CALCULATED Var_1 < (0.9 * CALCULATED Var_2)) OR (CALCULATED Var_1 > (1.015 * CALCULATED Var_2))  
			THEN "WARNING: Sum of the weights for members with RB110=1 or 2 (Var_1) should be close to and smaller than Sum of (RB060 / Nbr of rotational groups)(Var_2) (in the interval: -10%,+1.5%), for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
	FROM WORK.R62 AS R62
 	INNER JOIN WORK.R60 AS R60 ON ((R62.RB010 = R60.RB010) AND (R62.DB075 = R60.DB075) AND (R62.RB100 = R60.RB100) AND (R62.RB110 = R60.RB110))
	WHERE R62.DB075 =. AND R62.RB110 in (1,2) AND R62.RB100=. AND R62.RB010 = &RYYYY
	GROUP BY R62.RB010;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_11 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_12 AS SELECT DISTINCT R62.RB010 AS Year,
 	 DB075 AS Rot_grp,
	 RB100 AS S_pers_co_res,
	 RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_12" AS Check_code,
	 sum(RB062_Sum,0) AS Var_1,
	 . AS Var_2,
	 (CASE  WHEN Calculated Var_1 > 0  THEN "CONVENTION: All members with RB110=3 or 4 or 5 or 6 or 7 should have a zero weight for the last year in the file (Var_1 Sum of RB062)"  ELSE "OK" END ) AS PROBLEM 
 	FROM WORK.R62 AS R62
	WHERE DB075=. AND RB110 in (3,4,5,6,7) AND RB100=. AND RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_12 (WHERE=(PROBLEM ne "OK")) force;

PROC SQL;
 CREATE TABLE WORK.R62_14 AS SELECT DISTINCT R62.RB010 AS Year,
 	 R62.DB075 AS Rot_grp,
	 R62.RB100 AS S_pers_co_res,
	 R62.RB110 AS Mbr_status,
	 "RB062" AS Weight,
	 "R62_14" AS Check_code,
	 sum(RB062_Sum,0) AS Var_1,
%if &ss = r %then %do;
	 (sum(RB060_Sum,0)/(&N_DB075 + 1)) AS Var_2,
%end;
%else %do;
	 (sum(RB060_Sum,0)/&N_DB075) AS Var_2,
%end;	 
	 (CASE  WHEN (CALCULATED Var_1 < (0.95 * CALCULATED Var_2) OR (CALCULATED Var_1 > (1.05 * CALCULATED Var_2)))  
			THEN "ERROR: Sum of the weights (Var_1) should be around (+-5%) the one for RB060 / Nbr of rotational groups(Var_2), for the last year in the file"
			ELSE "OK" END ) AS PROBLEM 
	FROM WORK.R62 AS R62
 	INNER JOIN WORK.R60 AS R60 ON ((R62.RB010 = R60.RB010) AND (R62.DB075 = R60.DB075) AND (R62.RB100 = R60.RB100) AND (R62.RB110 = R60.RB110))
	WHERE R62.DB075=. AND R62.RB110=. AND R62.RB100=. AND R62.RB010 = &RYYYY;
QUIT;
proc append base=work.WEIGHT_Pb data=WORK.R62_14 (WHERE=(PROBLEM ne "OK")) force;

%mend RB062;
%RB062;





