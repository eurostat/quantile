

*options notes source source2 mlogic mprint symbolgen;

%macro select2;
%if &RYYYY>2013 %then %do;
	PROC SORT
		DATA=WORK.D95(KEEP=DB095_N DB095_0_N DB095_Sum DB010 DB075)
		OUT=WORK.D95_sort;
		BY DB075;
	RUN;

	PROC TRANSPOSE DATA=WORK.D95_sort
		OUT=D95_trans(LABEL="Transposed WORK.D95")
		PREFIX=Y
		NAME=Source
		LABEL=Label;
		BY DB075;
		ID DB010;
		VAR DB095_N DB095_0_N DB095_Sum;
	RUN; QUIT;

	PROC SQL;
	 CREATE TABLE WORK.D95_2 AS SELECT DISTINCT D95.DB010 as Year,
	 	 DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB095" AS Weight,
		 "D95_2" AS Check_code,
		 sum(D95.DB095_Sum,0) AS Var_1,
		 C_HH_NUMBER.HH_number AS Var_2,
		 (CASE  WHEN ABS(Var_2 - CALCULATED Var_1 ) > (CALCULATED Var_1 * 0.1)
				THEN "WARNING: Sum of the weights (Var_1) must be close (10%) to the household population size (Var_2)(Sum of DB090 from last year)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D95 AS D95 
		  INNER JOIN WORK.C_HH_NUMBER AS C_HH_NUMBER ON (D95.DB010 = C_HH_NUMBER.DB010)
	 WHERE D95.DB075 =. ;
	QUIT;

	proc append base=work.WEIGHT_Pb data=WORK.D95_2 (WHERE=(PROBLEM ne "OK")) force;

	%macro D95_3(y,y1);
	PROC SQL;
	 CREATE TABLE WORK.D95_3 AS SELECT
	 	 &y1 AS Year,
		 DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB095" AS Weight,
		 "D95_3" AS Check_code,
		 sum(trans.Y&y1,0) AS Var_1,
		 sum(trans.Y&y,0) AS Var_2,
		(CASE WHEN ABS(CALCULATED Var_2 - CALCULATED Var_1)> 0.03 * CALCULATED Var_2 THEN 
		 	"WARNING: Significant change (> +-3%) of number of households(Var_1) compared to previous year (&y Var_2)"
		 	ELSE "OK" END) AS PROBLEM
	FROM WORK.D95_trans AS trans
	WHERE DB075=. AND Source='DB095_Sum';
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D95_3 (WHERE=(PROBLEM ne "OK")) force;
	%mend D95_3;
	%D95_3(&y_3,&y_2);
	%D95_3(&y_2,&y_1);
	%D95_3(&y_1,&RYYYY);

	PROC SQL;
	 CREATE TABLE WORK.D95_4 AS SELECT DISTINCT D95.DB010 AS Year,
	 	 D95.DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB095" AS Weight,
		 "D95_4" AS Check_code,
		 DB095_NMiss AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN Var_1 > 0  THEN "ERROR: There should be no missing weights (Var_1: Nbr of missing weights)"  ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D95 AS D95
	 left join work.Y1_DB075 AS D75 on (D95.DB075=D75.DB075)
	WHERE D75.RB010 ne &RYYYY and D95.DB075 ne .; /*D75.RB010 ne &RYYYY eliminates the last rot grp*/
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D95_4 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.D95_5 AS SELECT DISTINCT D95.DB010 AS Year,
	 	 D95.DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB095" AS Weight,
		 "D95_5" AS Check_code,
		 sum(D95.DB095_Sum,0) AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN CALCULATED Var_1 > 0  THEN "ERROR: the sum of weight (Var_1) must be 0 as the last rotational group must not have DB095 weights"  ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D95 AS D95
	 left join work.Y1_DB075 AS D75 on (D95.DB075=D75.DB075)
	WHERE D75.RB010 = &RYYYY and D95.DB075 ne .; /*D75.RB010 = &RYYYY selects only the last rot grp*/
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D95_5 (WHERE=(PROBLEM ne "OK")) force;


	PROC SQL;
	 CREATE TABLE WORK.D95_6 AS SELECT DISTINCT D95.DB010 AS Year,
	 	 DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB095" AS Weight,
		 "D95_6" AS Check_code,
		 DB095_0_N AS Var_1,
		 . AS Var_2,
		 (CASE  WHEN Var_1 < 1  THEN
					"ERROR: The number of 0 weights (var_1) has to be greater than 0 (due to presence of non response / attrition)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D95 AS D95 
	 WHERE DB075=.;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D95_6 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE WORK.D95_7 AS SELECT DISTINCT D95.DB010 AS Year,
	 	 D95.DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB095" AS Weight,
		 "D95_7" AS Check_code,
		 DB095_0_N AS Var_1,
		 DB095_N AS Var_2,
		
		 (CASE  WHEN Y1_DB075.RB010 = D95.DB010 AND  Var_1 > 0.6 * Var_2 THEN
					"WARNING: The number of 0 weights (Var_1) is too high (>60% of the sample size (Var_2))(non response should normally be less that 60% the first wave)"
				WHEN Y1_DB075.RB010 < D95.DB010 AND  Var_1 > 0.4 * Var_2 THEN
					"WARNING: The number of 0 weights (Var_1) is too high (>40% of the sample size (Var_2))(non response should normally be less that 40% after the first wave)"
				ELSE "OK" END ) AS PROBLEM 
	 FROM WORK.D95 AS D95, WORK.Y1_DB075
	WHERE Y1_DB075.DB075 = D95.DB075;
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D95_7 (WHERE=(PROBLEM ne "OK")) force;

	PROC SQL;
	 CREATE TABLE work.D95_8 AS SELECT Y1_DB075.Y2 AS Year,
		 Y1_DB075.DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB095" AS Weight,
		 "D95_8" AS Check_code,
		 First_Y.DB095_0_N AS Var_1, 
		 Sec_Y.DB095_0_N AS Var_2,
		(CASE WHEN Var_1 < Var_2 THEN 
		 	"WARNING: The number of 0 weights from wave 2 (Var_2) should normally decrease compared to wave 1 (Var_1)"
		 	ELSE "OK" END) AS PROBLEM	 
	 FROM WORK.Y1_DB075 AS Y1_DB075,
		  WORK.D95 AS First_Y,
		  WORK.D95 AS Sec_Y
	 WHERE (Y1_DB075.DB075 = First_Y.DB075 AND Y1_DB075.RB010 = First_Y.DB010 AND Y1_DB075.DB075 = Sec_Y.DB075 AND Y1_DB075.Y2 = Sec_Y.DB010);
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D95_8 (WHERE=(PROBLEM ne "OK")) force;

	%macro D95_9(y,y1);
	PROC SQL;
	 CREATE TABLE WORK.D95_9 AS SELECT
	 	 &y1 AS Year,
		 trans.DB075 AS Rot_grp,
		 99 as S_pers_co_res,
		 99 AS Mbr_status,
		 "DB095" AS Weight,
		 "D95_9" AS Check_code,
		 trans.Y&y1 AS Var_1,
		 trans.Y&y AS Var_2,
		(CASE WHEN (Var_2 not is missing AND Var_2 < Var_1) THEN 
		 	"WARNING: The number of sampled households by rotational group (Var_1) should normally not increase since previous year (&y Var_2) (increase can rarely happen due to split-off households)"
		 	ELSE "OK" END) AS PROBLEM
	FROM WORK.D95_trans AS trans
	WHERE DB075 not is missing AND Source='DB095_N';
	QUIT;
	proc append base=work.WEIGHT_Pb data=WORK.D95_9 (WHERE=(PROBLEM ne "OK")) force;
	%mend D95_9;
	%D95_9(&y_3,&y_2);
	%D95_9(&y_2,&y_1);
	%D95_9(&y_1,&RYYYY);

%end;
%mend select2;
%select2;