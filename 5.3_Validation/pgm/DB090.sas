

*options notes source source2 mlogic mprint symbolgen;
%macro select1;
%if &RYYYY<2014 %then %do;

	PROC SORT
		DATA=WORK.D90(KEEP=DB090_N DB090_0_N DB090_Sum DB010 DB075)
		OUT=WORK.D90_sort;
		BY DB075;
	RUN;

	PROC TRANSPOSE DATA=WORK.D90_sort
		OUT=D90_trans(LABEL="Transposed WORK.D90")
		PREFIX=Y
		NAME=Source
		LABEL=Label;
		BY DB075;
		ID DB010;
		VAR DB090_N DB090_0_N DB090_Sum;
	RUN; QUIT;

	PROC SQL;
	 CREATE TABLE WORK.D90_2 AS SELECT DISTINCT D90.DB010 as Year,
	 	 DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB090" AS Weight,
		 "D90_2" AS Check_code,
		 sum(D90.DB090_Sum,0) AS Var_1,
		 C_HH_NUMBER.HH_number AS Var_2,
		 (CASE  WHEN ABS(C_HH_NUMBER.HH_number - D90.DB090_Sum ) > C_HH_NUMBER.HH_number * 0.1
				THEN "WARNING: Sum of the weights (Var_1) must be close (10%) to the household population size (Var_2)(from cross-sectional data)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D90 AS D90 
		  INNER JOIN WORK.C_HH_NUMBER AS C_HH_NUMBER ON (D90.DB010 = C_HH_NUMBER.DB010)
	 WHERE D90.DB075 =. ;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D90_2 (WHERE=(PROBLEM ne "OK")) force;

	%macro D90_3(y,y1);
	PROC SQL;
	 CREATE TABLE WORK.D90_3 AS SELECT
	 	 &y1 AS Year,
		 DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB090" AS Weight,
		 "D90_3" AS Check_code,
		 sum(trans.Y&y1,0) AS Var_1,
		 sum(trans.Y&y,0) AS Var_2,
		(CASE WHEN INT(trans.Y&y - trans.Y&y1)>0.03*trans.Y&y THEN 
		 	"WARNING: Significant change (> +-3%) of number of households(Var_1) compared to previous year (&y Var_2)"
		 	ELSE "OK" END) AS PROBLEM
	FROM WORK.D90_trans AS trans
	WHERE DB075=. AND Source='DB090_Sum';
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D90_3 (WHERE=(PROBLEM ne "OK")) force;
	%mend D90_3;
	%D90_3(&y_3,&y_2);
	%D90_3(&y_2,&y_1);
	%D90_3(&y_1,&yy2);

	PROC SQL;
	 CREATE TABLE WORK.D90_4 AS SELECT DISTINCT D90.DB010 AS Year,
	 	 DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB090" AS Weight,
		 "D90_4" AS Check_code,
		 DB090_NMiss AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN DB090_NMiss > 0  THEN "ERROR: There should be no missing weights (Var_1: Nbr of missing weights)"  ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D90 AS DB090
	WHERE DB075=.;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D90_4 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.D90_5 AS SELECT DISTINCT D90.DB010 AS Year,
	 	 DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB090" AS Weight,
		 "D90_5" AS Check_code,
		 DB090_0_N AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN DB090_0_N < 1  THEN
					"ERROR: The number of 0 weights (var_1) has to be greater than 0 (due to presence of non response / attrition)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D90 AS D90 
	 WHERE DB075=.;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D90_5 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.D90_6 AS SELECT DISTINCT D90.DB010 AS Year,
	 	 D90.DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB090" AS Weight,
		 "D90_6" AS Check_code,
		 DB090_0_N AS Var_1,
		 (DB090_N ) AS Var_2,
		
		 (CASE  WHEN Y1_DB075.RB010 = D90.DB010 AND  DB090_0_N > 0.6*DB090_N THEN
					"WARNING: The number of 0 weights (Var_1) is too high (>60% of the sample size (Var_2))(non response should normally be less that 60% the first wave)"
				WHEN Y1_DB075.RB010 < D90.DB010 AND  DB090_0_N > 0.4*DB090_N THEN
					"WARNING: The number of 0 weights (Var_1) is too high (>40% of the sample size (Var_2))(non response should normally be less that 40% after the first wave)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D90 AS D90, WORK.Y1_DB075
	WHERE Y1_DB075.DB075 = D90.DB075;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D90_6 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE work.D90_7 AS SELECT Y1_DB075.Y2 AS Year,
		 Y1_DB075.DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB090" AS Weight,
		 "D90_7" AS Check_code,
		 First_Y.DB090_0_N AS Var_1, 
		 Sec_Y.DB090_0_N AS Var_2,
		(CASE WHEN First_Y.DB090_0_N < Sec_Y.DB090_0_N THEN 
		 	"WARNING: The number of 0 weights from wave 2 (Var_2) should normally decrease compared to wave 1 (Var_1)"
		 	ELSE "OK" END) AS PROBLEM	 
	 FROM WORK.Y1_DB075 AS Y1_DB075,
		  WORK.D90 AS First_Y,
		  WORK.D90 AS Sec_Y
	 WHERE (Y1_DB075.DB075 = First_Y.DB075 AND Y1_DB075.RB010 = First_Y.DB010 AND Y1_DB075.DB075 = Sec_Y.DB075 AND Y1_DB075.Y2 = Sec_Y.DB010);
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D90_7 (WHERE=(PROBLEM ne "OK")) force;

	%macro D90_8(y,y1);
	PROC SQL;
	 CREATE TABLE WORK.D90_8 AS SELECT
	 	 &y1 AS Year,
		 trans.DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB090" AS Weight,
		 "D90_8" AS Check_code,
		 trans.Y&y1 AS Var_1,
		 trans.Y&y AS Var_2,
		(CASE WHEN (trans.Y&y not is missing AND trans.Y&y < trans.Y&y1) THEN 
		 	"WARNING: The number of sampled households by rotational group (Var_1) should normally not increase since previous year (&y Var_2) (increase can rarely happen due to split-off households)"
		 	ELSE "OK" END) AS PROBLEM
	FROM WORK.D90_trans AS trans
	WHERE DB075 not is missing AND Source='DB090_N';
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D90_8 (WHERE=(PROBLEM ne "OK")) force;
	%mend D90_8;
	%D90_8(&y_3,&y_2);
	%D90_8(&y_2,&y_1);
	%D90_8(&y_1,&yy2);

%end;

%mend select1;
%select1;

