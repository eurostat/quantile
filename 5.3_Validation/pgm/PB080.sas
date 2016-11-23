PROC SORT
	DATA=WORK.P80(KEEP=PB080_N PB080_0_N PB080_Sum PB080_NMiss PB010 DB075 RB100 RB110)
	OUT=WORK.P80_sort;
	BY DB075 RB100 RB110;
RUN;

PROC TRANSPOSE DATA=WORK.P80_sort
	OUT=P80_trans(LABEL="Transposed WORK.P80")
	PREFIX=Y
	NAME=Source
	LABEL=Label;
	BY DB075 RB100 RB110;
	ID PB010;
	VAR PB080_N PB080_0_N PB080_Sum PB080_NMiss;
RUN; QUIT;

%macro sel_ctr;

	%if (&cc=dk OR &cc=fi OR &cc=is OR &cc=nl OR &cc=no OR &cc=se OR &cc=si) %then %do;
		PROC SQL;
		 CREATE TABLE WORK.P80_2 AS SELECT DISTINCT P80.PB010 AS Year,
		 	 P80.DB075 AS Rot_grp,
			 P80.RB100 AS S_pers_co_res,
			 P80.RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_2" AS Check_code,
			 PB080_Sum AS Var_1,
			 Y1_DB075.RB010 AS Var_2,
			 (CASE  WHEN (Var_1 > 0 AND Var_2 = &RYYYY) 
					THEN "CONVENTION: PB080 should = 0 (Var_1 Sum of weights) for that rotational group as there are no 2-year trajectories(Var_2: first year in the survey) "
					ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
		 	INNER JOIN WORK.Y1_DB075 AS Y1_DB075 ON (P80.DB075 = Y1_DB075.DB075)
			WHERE P80.DB075 ne . AND P80.RB110=. AND P80.RB100=. AND P80.PB010 = &RYYYY;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_2 (WHERE=(PROBLEM ne "OK")) force;
		
		PROC SQL;
		 CREATE TABLE WORK.P80_4 AS SELECT DISTINCT P80.PB010 AS Year,
		 	 DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_4" AS Check_code,
			 PB080_NMiss AS Var_1,
			 . AS Var_2,
			 (CASE  WHEN PB080_NMiss > 0  THEN "ERROR: There should be no missing weights (Var_1: Nbr of missing weights)"  ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
			WHERE DB075 ne . AND RB110=. AND RB100= 1;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_4 (WHERE=(PROBLEM ne "OK")) force;

		PROC SQL;
		 CREATE TABLE WORK.P80_5 AS SELECT P80.PB010 AS Year,
		 	 P80.DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_5" AS Check_code,
			 PB080_N AS Var_1,
			 . AS Var_2,
			(CASE WHEN RB110 ne 1 THEN
					"ERROR: RB110 (Mbr_status) should equal 1 for everyone in the considered rotational group in the first year of interview (Var_1 Nbr of cases)"
				 ELSE "OK" END) AS PROBLEM	 
		 	FROM WORK.P80 AS P80,
			  WORK.Y1_DB075 AS Y1_DB075
		 	WHERE (P80.PB010 = Y1_DB075.RB010 AND P80.DB075 = Y1_DB075.DB075) AND
		 	   (P80.RB100= 1  AND P80.RB110 ne . );
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_5 (WHERE=(PROBLEM ne "OK")) force;

		PROC SQL;
		 CREATE TABLE WORK.P80_6 AS SELECT DISTINCT PB010 AS Year,
		 	 DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_6" AS Check_code,
			 PB080_N AS Var_1,
			 . AS Var_2,
			 (CASE  WHEN PB080_N = 0  THEN "ERROR: The sample size in the considered rotational group (Var_1) should be greater than zero for each year after the first year of interview"
					ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
			WHERE DB075 ne . AND RB110=. AND RB100= 1;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_6 (WHERE=(PROBLEM ne "OK")) force;


		%macro P80_7(y,y1);
			PROC SQL;
			 CREATE TABLE WORK.P80_7 AS SELECT
			 	 &y1 AS Year,
			 	 DB075 AS Rot_grp,
				 RB100 AS S_pers_co_res,
				 RB110 AS Mbr_status,
				 "PB080" AS Weight,
				 "P80_7" AS Check_code,
				 trans.Y&y1 AS Var_1,
				 trans.Y&y AS Var_2,
				(CASE WHEN trans.Y&y < trans.Y&y1 THEN 
				 	"WARNING: The sample size in a rotational group (Var_1) should normally decrease since previous year (&y Var_2) (increase can rarely happen due to new household members)"
				 	ELSE "OK" END) AS PROBLEM
			FROM WORK.P80_trans AS trans
			WHERE DB075 ne . AND RB100= 1 AND RB110=. AND Y&y not is missing AND Y&y1 not is missing   AND Source='PB080_N';
			QUIT;
			proc append base=work.WEIGHT_Pb data=WORK.P80_7 (WHERE=(PROBLEM ne "OK")) force;
		%mend P80_7;
		%P80_7(&y_3,&y_2);
		%P80_7(&y_2,&y_1);
		%P80_7(&y_1,&RYYYY);

		%macro P80_8(y,y1);
			PROC SQL;
			 CREATE TABLE WORK.P80_8 AS SELECT
			 	 &y1 AS Year,
			 	 trans.DB075 AS Rot_grp,
				 RB100 AS S_pers_co_res,
				 RB110 AS Mbr_status,
				 "PB080" AS Weight,
				 "P80_8" AS Check_code,
				 trans.Y&y1 AS Var_1,
				 trans.Y&y AS Var_2,
				(CASE WHEN (Y1_DB075.RB010 = &y) AND ((trans.Y&y - trans.Y&y1)> 0.3*trans.Y&y )  THEN 
				 	"WARNING: The sample size in a rotational group (Var_1) should not decrease too much (max 30%) between 1st and 2nd wave (&y Var_2) "
					WHEN (Y1_DB075.RB010 > &y) AND ((trans.Y&y - trans.Y&y1)> 0.2*trans.Y&y )  THEN 
				 	"WARNING: The sample size in a rotational group (Var_1) should not decrease too much (max 20%) since previous year (&y Var_2) "
				 	ELSE "OK" END) AS PROBLEM
				FROM WORK.P80_trans AS trans, WORK.Y1_DB075
				WHERE (trans.DB075 = Y1_DB075.DB075) AND trans.DB075 ne . AND RB110=. AND RB100= 1 AND Y&y not is missing AND Y&y1 not is missing  AND Source='PB080_N';
			QUIT;
			proc append base=work.WEIGHT_Pb data=WORK.P80_8 (WHERE=(PROBLEM ne "OK")) force;
		%mend P80_8;
		%P80_8(&y_3,&y_2);
		%P80_8(&y_2,&y_1);
		%P80_8(&y_1,&RYYYY);

		PROC SQL;
		 CREATE TABLE WORK.P80_9 AS SELECT DISTINCT P80.PB010 AS Year,
		 	 P80.DB075 AS Rot_grp FORMAT DB075f.,
			 P80.RB100 AS S_pers_co_res,
			 P80.RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_9" AS Check_code,
			 PB080_N AS Var_1,
			 (PB050_N*1/3) AS Var_2,
			 (CASE  WHEN (PB080_N < (PB050_N/3 ) OR (PB080_N > 2*PB050_N/3))  
					THEN "WARNING: The sample size in a rotational group (Var_1) should be between 1/3 and  2/3 of one of PB050 (Var_2= 1/3 PB050_N)"
					ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
		  	INNER JOIN WORK.P50 AS P50 ON (P80.PB010 = P50.PB010) AND (P80.DB075 = P50.DB075) AND (P80.RB100 = P50.RB100)
		  							AND (P80.RB110 = P50.RB110)
			WHERE P80.DB075 ne . AND P80.RB110=. AND P80.RB100= .;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_9 (WHERE=(PROBLEM ne "OK")) force;
/*
		%macro P80_10(y,y1);
			PROC SQL;
			 CREATE TABLE WORK.P80_10 AS SELECT
			 	 &y1 AS Year,
			 	 DB075 AS Rot_grp,
				 RB100 AS S_pers_co_res,
				 RB110 AS Mbr_status,
				 "PB080" AS Weight,
				 "P80_10" AS Check_code,
				 sum(trans.Y&y1,0) AS Var_1,
				 sum(trans.Y&y,0) AS Var_2,
				(CASE WHEN ((1.015*trans.Y&y) < trans.Y&y1) THEN 
				 	"WARNING: Sum of the weights in a rotational group (Var_1) should normally decrease since previous year (&y Var_2) (as the longitudinal population)"
				 	ELSE "OK" END) AS PROBLEM
				FROM WORK.P80_trans AS trans
				WHERE DB075 ne . AND RB110=. AND RB100= 1 AND Y&y not is missing AND Y&y1 not is missing  AND Source='PB080_Sum';
			QUIT;
			proc append base=work.WEIGHT_Pb data=WORK.P80_10 (WHERE=(PROBLEM ne "OK")) force;
		%mend P80_10;
		%P80_10(&y_3,&y_2);
		%P80_10(&y_2,&y_1);
		%P80_10(&y_1,&yy2);
*/
		%macro P80_11(y,y1);
			PROC SQL;
			 CREATE TABLE WORK.P80_11 AS SELECT
			 	 &y1 AS Year,
			 	 DB075 AS Rot_grp,
				 RB100 AS S_pers_co_res,
				 RB110 AS Mbr_status,
				 "PB080" AS Weight,
				 "P80_11" AS Check_code,
				 sum(trans.Y&y1,0) AS Var_1,
				 sum(trans.Y&y,0) AS Var_2,
				(CASE WHEN ((trans.Y&y - trans.Y&y1)> 0.1*trans.Y&y )  THEN 
				 	"WARNING: Sum of the weights in a rotational group (Var_1) should not decrease too much (max 10%) since previous year (&y Var_2) "
				 	ELSE "OK" END) AS PROBLEM
				FROM WORK.P80_trans AS trans
				WHERE DB075 ne . AND RB110=. AND RB100=. AND Y&y not is missing AND Y&y1 not is missing
					 AND Source='PB080_Sum';
			QUIT;
			proc append base=work.WEIGHT_Pb data=WORK.P80_11 (WHERE=(PROBLEM ne "OK")) force;
		%mend P80_11;
		%P80_11(&y_3,&y_2);
		%P80_11(&y_2,&y_1);
		%P80_11(&y_1,&RYYYY);

		PROC SQL;
		 CREATE TABLE WORK.P80_12 AS SELECT DISTINCT P80.PB010 AS Year,
		 	 P80.DB075 AS Rot_grp FORMAT DB075f.,
			 P80.RB100 AS S_pers_co_res,
			 P80.RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_12" AS Check_code,
			 sum(PB080_Sum,0) AS Var_1,
			 sum(PB050_Sum,0) AS Var_2,
	             (CASE  WHEN (PB080_Sum < 0.95*PB050_Sum) OR (PB080_Sum > 1.05*PB050_Sum)  
	                        THEN "WARNING: Sum of weights in a rotational group (Var_1) should be close (+-5%) to the one of PB050 (Var_2)"
	                        ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
		  	INNER JOIN WORK.P50 AS P50 ON (P80.PB010 = P50.PB010) AND (P80.DB075 = P50.DB075) AND (P80.RB100 = P50.RB100)
		  							AND (P80.RB110 = P50.RB110)
			WHERE P80.DB075 ne . AND P80.RB110=. AND P80.RB100= .;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_12 (WHERE=(PROBLEM ne "OK")) force;

		PROC SQL;
		 CREATE TABLE WORK.P80_13 AS SELECT P80.PB010 AS Year,
		 	 P80.DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_13" AS Check_code,
			 PB080_0_N AS Var_1,
			 . AS Var_2,
			(CASE WHEN PB080_0_N >0 THEN
					"ERROR: There should be no zero weight in the first year of interview (Var_1 Number of zero weights)"
				 ELSE "OK" END) AS PROBLEM	 
		 	FROM WORK.P80 AS P80,
			  WORK.Y1_DB075 AS Y1_DB075
		 	WHERE (P80.PB010 = Y1_DB075.RB010 AND P80.DB075 = Y1_DB075.DB075) AND
		 	   (P80.RB100= 1  AND P80.RB110=. AND Y1_DB075.RB010 ne &RYYYY);
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_13 (WHERE=(PROBLEM ne "OK")) force;

		PROC SQL;
		 CREATE TABLE WORK.P80_14 AS SELECT DISTINCT P80.PB010 AS Year,
		 	 DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_14" AS Check_code,
			 PB080_0_N AS Var_1,
			 (0.5*PB080_N) AS Var_2,
			 (CASE  WHEN (PB080_0_N > 0.5*PB080_N)  
					THEN "WARNING: The number of zero weights (Var_1) should be smaller than 1/2 of the sample size (Var_2) for the considered rotational group and the considered year"
					ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
			WHERE DB075 ne . AND RB110=. AND RB100= 1;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_14 (WHERE=(PROBLEM ne "OK")) force;

		PROC SQL;
		 CREATE TABLE WORK.P80_15 AS SELECT P80.PB010 AS Year,
		 	 P80.DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_15" AS Check_code,
			 PB080_0_N AS Var_1,
			 . AS Var_2,
			(CASE WHEN PB080_0_N >0  THEN
					"ERROR: There should be no zero weight in the 2nd year of interview (Var_1 Number of zero weights)for members with RB110=1 or 2"
				 ELSE "OK" END) AS PROBLEM	 
		 	FROM WORK.P80 AS P80,
			  WORK.Y1_DB075 AS Y1_DB075
		 	WHERE (P80.PB010 = Y1_DB075.Y2 AND P80.DB075 = Y1_DB075.DB075 AND
		 	   P80.RB100= 1  AND P80.RB110 in (1,2) );
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_15 (WHERE=(PROBLEM ne "OK")) force;

		PROC SQL;
		 CREATE TABLE WORK.P80_17 AS SELECT DISTINCT PB010 AS Year,
		 	 DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_17" AS Check_code,
			 PB080_N AS Var_1,
			 . AS Var_2,
			 (CASE  WHEN PB080_N > 0  THEN "ERROR: There should be no weight value for coresident (Var_1: Nbr of cases)"
					ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
			WHERE DB075 ne . AND RB110 ne . AND RB100=2;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_17 (WHERE=(PROBLEM ne "OK")) force;

		PROC SQL;
		 CREATE TABLE WORK.P80_18 AS SELECT DISTINCT P80.PB010 AS Year,
		 	 P80.DB075 AS Rot_grp FORMAT DB075f.,
			 P80.RB100 AS S_pers_co_res,
			 P80.RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_18" AS Check_code,
			 PB080_NMiss AS Var_1,
			 (PB050_N) AS Var_2,
			 (CASE  WHEN (PB080_NMiss ne PB050_N)  
					THEN "ERROR: The number of missing values (Var_1) should be equal to the number of (non-missing) values for PB050 (Var_2) for that year"
					ELSE "OK" END ) AS PROBLEM 
		 FROM WORK.P80 AS P80
		  INNER JOIN WORK.P50 AS P50 ON (P80.PB010 = P50.PB010) AND (P80.DB075 = P50.DB075) AND (P80.RB100 = P50.RB100)
		  							AND (P80.RB110 = P50.RB110)
		WHERE P80.DB075 ne . AND P80.RB110=. AND P80.RB100= 2;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_18 (WHERE=(PROBLEM ne "OK")) force;

	%end;

	%else %do;

		PROC SQL;
		 CREATE TABLE WORK.P80_1 AS SELECT DISTINCT PB010 AS Year,
		 	 DB075 AS Rot_grp,
			 RB100 AS S_pers_co_res,
			 RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_1" AS Check_code,
			 PB080_N AS Var_1,
			 . AS Var_2,
			 (CASE  WHEN PB080_N > 0  THEN "ERROR: No weight value for non register country (Var_1: Nbr of cases)"
					ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
			WHERE DB075= . AND RB110 = . AND RB100= .;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_1 (WHERE=(PROBLEM ne "OK")) force;

		PROC SQL;
		 CREATE TABLE WORK.P80_3 AS SELECT DISTINCT P80.PB010 AS Year,
		 	 P80.DB075 AS Rot_grp FORMAT DB075f.,
			 P80.RB100 AS S_pers_co_res,
			 P80.RB110 AS Mbr_status,
			 "PB080" AS Weight,
			 "P80_3" AS Check_code,
			 PB080_NMiss AS Var_1,
			 PB050_N AS Var_2,
			 (CASE  WHEN (PB080_NMiss ne PB050_N)  
					THEN "ERROR: The number of missing values (Var_1) should be equal to the number of (non-missing) values for PB050 (Var_2) for that year"
					ELSE "OK" END ) AS PROBLEM 
		 	FROM WORK.P80 AS P80
		  	INNER JOIN WORK.P50 AS P50 ON (P80.PB010 = P50.PB010) AND (P80.DB075 = P50.DB075) AND (P80.RB100 = P50.RB100)
		  							AND (P80.RB110 = P50.RB110)
			WHERE P80.DB075 = . AND P80.RB110=. AND P80.RB100= .;
		QUIT;
		proc append base=work.WEIGHT_Pb data=WORK.P80_3 (WHERE=(PROBLEM ne "OK")) force;

	%end;

%mend sel_ctr;
%sel_ctr;

proc sql;
create table work.summary as select
	Year,
	Rot_grp AS DB075 FORMAT DB075f.,
	S_pers_co_res AS RB100 FORMAT RB100f.,
	Mbr_status AS RB110  FORMAT RB110f.,
	Weight,
	Check_code,
	Var_1 FORMAT Valf.,
	Var_2 FORMAT Valf.,
	PROBLEM
FROM work.WEIGHT_Pb;
QUIT;

proc export data=work.summary
 outfile="&eusilc/&cc/&ss&yy/&ss&cc&yy._WEIGHT_Pb_&sysdate..csv"
   dbms=csv
   replace;
run;
