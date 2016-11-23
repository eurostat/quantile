
/**********************************************************/
/* PART 1  CREATE main tables for FOR WEIGHT ASSESSMENT*/
/**********************************************************/

options nodate;
*options    notes source  source2 mlogic   mprint    symbolgen;
Title; Footnote;

data _null_;
      call symput("dat",put("&sysdate"d,yymmdd8.));
run;

libname lib "&G_PING_RAWDB/&cc./&ss&yy";
ODS HTML path="&G_PING_RAWDB/&cc./&ss&yy/" body="weights.html" style=EGdefault nogtitle;
TITLE;


%macro select0;
	PROC SQL;

%if &RYYYY>2013 %then %do;
	
	create table d as
	select DB010, DB020, DB030, DB090, DB095,
		(CASE DB075
			WHEN . THEN -1
			ELSE DB075
	 	END) as DB075
	from lib.&ss&cc&yy.d;
	create table d00 as
	select DB010, DB030,
		(CASE DB090
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as DB090_0  
	from d
	where calculated DB090_0 = 0;

	create table d95 as
	select DB010, DB030,
		(CASE DB095
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as DB095_0  
	from d
	where calculated DB095_0 = 0;

	create table dw as
	select d.*, DB090_0, DB095_0
	from d left join d00 on d.DB010 = d00.DB010 and d.DB030 = d00.DB030
			left join d95 on d.DB010 = d95.DB010 and d.DB030 = d95.DB030;

	create table r as
	select RB010, RB020, RB030, RB040, RB050, RB060, RB062, RB063, RB064, RB100, RB110 
	from lib.&ss&cc&yy.r;

	create table r50 as
	select RB010, RB030, RB040,
		(CASE RB050
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as RB050_0  
	from r
	where calculated RB050_0 = 0;

%end;
%else %do;
	create table d as
	select DB010, DB020, DB030, DB090, 
		(CASE DB075
			WHEN . THEN -1
			ELSE DB075
	 	END) as DB075
	from lib.l&cc&yy.d;
	create table d00 as
	select DB010, DB030,
		(CASE DB090
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as DB090_0  
	from d
	where calculated DB090_0 = 0;

	create table dw as
	select d.*, DB090_0
	from d left join d00 on d.DB010 = d00.DB010 and d.DB030 = d00.DB030;
 
	create table r as
	select RB010, RB020, RB030, RB040, RB060, RB062, RB063, RB064, RB100, RB110 
	from lib.&ss&cc&yy.r;

%end;
	create table r00 as
	select RB010, RB030, RB040,
		(CASE RB060
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as RB060_0  
	from r
	where calculated RB060_0 = 0;

	

	create table r02 as
	select RB010, RB030, RB040,
		(CASE RB062
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as RB062_0  
	from r
	where calculated RB062_0 = 0;

	create table r03 as
	select RB010, RB030, RB040,
		(CASE RB063
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as RB063_0  
	from r
	where calculated RB063_0 = 0;

	create table r04 as
	select RB010, RB030, RB040,
		(CASE RB064
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as RB064_0  
	from r
	where calculated RB064_0 = 0;

%if &RYYYY>2013 %then %do;
	create table rw as
	select r.*, RB060_0, RB062_0, RB063_0,RB064_0, RB050_0, DB075
	from r left join r00 on r.RB010 = r00.RB010 and r.RB030 = r00.RB030 and r.RB040 = r00.RB040
			left join r02 on r.RB010 = r02.RB010 and r.RB030 = r02.RB030 and r.RB040 = r02.RB040
			left join r03 on r.RB010 = r03.RB010 and r.RB030 = r03.RB030 and r.RB040 = r03.RB040
			left join r04 on r.RB010 = r04.RB010 and r.RB030 = r04.RB030 and r.RB040 = r04.RB040
			left join r50 on r.RB010 = r50.RB010 and r.RB030 = r50.RB030 and r.RB040 = r50.RB040
			left join d on r.RB010 = d.DB010 and r.RB040 = d.DB030;
%end;
%else %do;
	create table rw as
	select r.*, RB060_0, RB062_0, RB063_0,RB064_0, DB075
	from r left join r00 on r.RB010 = r00.RB010 and r.RB030 = r00.RB030 and r.RB040 = r00.RB040
			left join r02 on r.RB010 = r02.RB010 and r.RB030 = r02.RB030 and r.RB040 = r02.RB040
			left join r03 on r.RB010 = r03.RB010 and r.RB030 = r03.RB030 and r.RB040 = r03.RB040
			left join r04 on r.RB010 = r04.RB010 and r.RB030 = r04.RB030 and r.RB040 = r04.RB040
			left join d on r.RB010 = d.DB010 and r.RB040 = d.DB030;
%end;

	create table p as
	select PB010, PB020, PB030, phid, PB050, PB080
	from lib.&ss&cc&yy.p;

	create table p50 as
	select PB010, PB030, 
		(CASE PB050
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as PB050_0  
	from p
	where calculated PB050_0 = 0;

	create table p80 as
	select PB010, PB030, 
		(CASE PB080
			WHEN 0 THEN 0 
			ELSE 1
	 	END) as PB080_0  
	from p
	where calculated PB080_0 = 0;

	create table pw as
	select p.*, PB050_0, PB080_0, RB100, RB110, DB075
	from p left join p50 on p.PB010 = p50.PB010 and p.PB030 = p50.PB030 
			left join p80 on p.PB010 = p80.PB010 and p.PB030 = p80.PB030 
			left join r on p.PB010 = r.RB010 and p.PB030 = r.RB030 and p.phid = r.RB040
			left join d on p.PB010 = d.DB010 and p.phid = d.DB030;
	QUIT;


	Footnote H=2 "&ss._20&yy - &cc - &dat";

	PROC TABULATE data=dw out=D90;
		Label DB075='ROTATIONAL GROUP';	
		VAR DB090 DB090_0;
		CLASS DB010 /ORDER=UNFORMATTED MISSING;
		CLASS DB075;
		TABLE 
			(all="total"*{STYLE={BACKGROUND=#FFFF00}} DB075),
			DB010=""*(DB090=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) DB090_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="DB090" STYLE={FONT_SIZE=6}};
	RUN;

%if &RYYYY>2013 %then %do;

	PROC TABULATE data=dw out=D95;
		Label DB075='ROTATIONAL GROUP';	
		VAR DB095 DB095_0;
		CLASS DB010 /ORDER=UNFORMATTED MISSING;
		CLASS DB075;
		TABLE 
			(all="total"*{STYLE={BACKGROUND=#FFFF00}} DB075),
			DB010=""*(DB095=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) DB095_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="DB095" STYLE={FONT_SIZE=6}};
	RUN;

	PROC TABULATE data=rw out=R50;
		Label DB075='ROTATIONAL GROUP'
			RB100='SAMPLED / CORESIDENT'
			RB110='MEMBERSHIP STATUS';
		VAR RB050 RB050_0;
		CLASS RB010 /ORDER=UNFORMATTED MISSING;
		CLASS RB100;
		CLASS RB110;
		CLASS DB075;
		TABLE 
			(all="total" DB075)*(all="total" RB100)*(all="total"*{STYLE={BACKGROUND=#FFFF00}} RB110),
			RB010=""*(RB050=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) RB050_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="RB050" STYLE={FONT_SIZE=6}};
	RUN;

%end;

	PROC TABULATE data=rw out=R60;
		Label DB075='ROTATIONAL GROUP'
			RB100='SAMPLED / CORESIDENT'
			RB110='MEMBERSHIP STATUS';
		VAR RB060 RB060_0;
		CLASS RB010 /ORDER=UNFORMATTED MISSING;
		CLASS RB100;
		CLASS RB110;
		CLASS DB075;
		TABLE 
			(all="total" DB075)*(all="total" RB100)*(all="total"*{STYLE={BACKGROUND=#FFFF00}} RB110),
			RB010=""*(RB060=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) RB060_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="RB060" STYLE={FONT_SIZE=6}};
	RUN;

	

	PROC TABULATE data=rw out=R62;
		Label DB075='ROTATIONAL GROUP'
			RB100='SAMPLED / CORESIDENT'
			RB110='MEMBERSHIP STATUS';
		VAR RB062 RB062_0;
		CLASS RB010 /ORDER=UNFORMATTED MISSING;
		CLASS RB100;
		CLASS RB110;
		CLASS DB075;
		TABLE 
			(all="total" DB075)*(all="total" RB100)*(all="total"*{STYLE={BACKGROUND=#FFFF00}} RB110),
			RB010=""*(RB062=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) RB062_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="RB062" STYLE={FONT_SIZE=6}};
	RUN;

	PROC TABULATE data=rw out=R63;
		Label DB075='ROTATIONAL GROUP'
			RB100='SAMPLED / CORESIDENT'
			RB110='MEMBERSHIP STATUS';
		VAR RB063 RB063_0;
		CLASS RB010 /ORDER=UNFORMATTED MISSING;
		CLASS RB100;
		CLASS RB110;
		CLASS DB075;
		TABLE 
			(all="total" DB075)*(all="total" RB100)*(all="total"*{STYLE={BACKGROUND=#FFFF00}} RB110),
			RB010=""*(RB063=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) RB063_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="RB063" STYLE={FONT_SIZE=6}};
	RUN;

	PROC TABULATE data=rw out=R64;
		Label DB075='ROTATIONAL GROUP'
			RB100='SAMPLED / CORESIDENT'
			RB110='MEMBERSHIP STATUS';
		VAR RB064 RB064_0;
		CLASS RB010 /ORDER=UNFORMATTED MISSING;
		CLASS RB100;
		CLASS RB110;
		CLASS DB075;
		TABLE 
			(all="total" DB075)*(all="total" RB100)*(all="total"*{STYLE={BACKGROUND=#FFFF00}} RB110),
			RB010=""*(RB064=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) RB064_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="RB064" STYLE={FONT_SIZE=6}};
	RUN;

	PROC TABULATE data=pw out=P50;
		Label DB075='ROTATIONAL GROUP'
			RB100='SAMPLED / CORESIDENT'
			RB110='MEMBERSHIP STATUS';
		VAR PB050 PB050_0;
		CLASS PB010 /ORDER=UNFORMATTED MISSING;
		CLASS RB100;
		CLASS RB110;
		CLASS DB075;
		TABLE 
			(all="total" DB075)*(all="total" RB100)*(all="total"*{STYLE={BACKGROUND=#FFFF00}} RB110),
			PB010=""*(PB050=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) PB050_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="PB050" STYLE={FONT_SIZE=6}};
	RUN;

	PROC TABULATE data=pw out=P80;
		Label DB075='ROTATIONAL GROUP'
			RB100='SAMPLED / CORESIDENT'
			RB110='MEMBERSHIP STATUS';
		VAR PB080 PB080_0;
		CLASS PB010 /ORDER=UNFORMATTED MISSING;
		CLASS RB100;
		CLASS RB110;
		CLASS DB075;
		TABLE 
			(all="total" DB075)*(all="total" RB100)*(all="total"*{STYLE={BACKGROUND=#FFFF00}} RB110),
			PB010=""*(PB080=""*(N Sum Nmiss*{STYLE={FOREGROUND=#FF0000}}) PB080_0=""*N="0"*{STYLE={FOREGROUND=#0000FF}}) 
				/BOX={LABEL="PB080" STYLE={FONT_SIZE=6}};
	RUN;


/***************************************************************************/
/* PART 2  CREATE SIDE TABLES VARIABLES AND LIBRARIES FOR WEIGHT ASSESSMENT*/
/***************************************************************************/

/* create year variables 2 or 4 digits*/
%let y_1= %eval(&RYYYY -1);
%let y_01= %substr(&y_1,3,2);
%let y_2= %eval(&RYYYY -2);
%let y_02= %substr(&y_2,3,2);
%let y_3= %eval(&RYYYY -3);
%let y_03= %substr(&y_3,3,2);



/*initialise tables for computing number of household total population and error list*/

PROC SQL;
 CREATE TABLE work.C_HH_number
	(DB010 num(4),
	DB020 char(2),
	HH_number num);

 CREATE TABLE work.C_POP_number 
	(RB010 num(4),
	RB020 char(2),
	Cr_RB050_N num,
	Cr_RB050_Sum num);

Create table work.WEIGHT_Pb 
		(Year num(4),
		Rot_grp num,
		S_pers_co_res num,
		Mbr_status num,
		Weight char(8),
		Check_code char(8),
		Var_1 num,
		Var_2 num,
		PROBLEM char(256));
QUIT;



%macro per_y(y);

%if &cc= UK or &RYYYY < 2014 %then %do;
	/*create libraries for cross sectional data*/

	libname dat_c&yy "&G_PING_RAWDB/&cc/c&yy";
	libname dat_c&y_01 "&G_PING_RAWDB/&cc/c&y_01";
	libname dat_c&y_02 "&G_PING_RAWDB/&cc/c&y_02";
	libname dat_c&y_03 "&G_PING_RAWDB/&cc/c&y_03";

	/*fill the above tables from Xsectional data*/ 
	PROC SQL;
	 CREATE TABLE work.C_HH_number2 AS SELECT DISTINCT D.DB010,
		 D.DB020,
		 (SUM(D.DB090)) AS HH_number 
	 FROM dat_c&y..c&cc&y.D AS D
	 GROUP BY D.DB010;
	QUIT;

	DATA  work.C_HH_number;
	set work.C_HH_number
	    work.C_HH_number2; 
	run;  

	PROC SQL;
	 CREATE TABLE work.C_POP_number2 AS SELECT DISTINCT R.RB010,
		 R.RB020,
		 (COUNT(R.RB050)) AS Cr_RB050_N,
		 (SUM(R.RB050)) AS Cr_RB050_Sum
	 FROM dat_c&y..c&cc&y.R AS R
	 GROUP BY R.RB010;
	QUIT;

	DATA  work.C_POP_number;
	set work.C_POP_number
	    work.C_POP_number2; 
	run;  
%end;

%else %do;
	/*fill the above tables from regular data*/ 
	/*assign the number of HH/person from last year (&yy) from regular file to all the other years*/
	PROC SQL;
	 CREATE TABLE work.C_HH_number2 AS SELECT DISTINCT 
		 20&y as DB010,
		 D.DB020,
		 (SUM(D.DB090)) AS HH_number 
	 FROM lib.&ss&cc&yy.d AS D
	 WHERE D.DB010 = &RYYYY;
	QUIT;

	DATA  work.C_HH_number;
	set work.C_HH_number
	    work.C_HH_number2; 
	run;  

	PROC SQL;
	 CREATE TABLE work.C_POP_number2 AS SELECT DISTINCT 20&y as RB010,
		 R.RB020,
		 (COUNT(R.RB050)) AS Cr_RB050_N,
		 (SUM(R.RB050)) AS Cr_RB050_Sum
	 FROM lib.&ss&cc&yy.r AS R
	 WHERE R.RB010 = &RYYYY;
	QUIT;

	DATA  work.C_POP_number;
	set work.C_POP_number
	    work.C_POP_number2; 
	run;  
%end;
%mend;

%per_y(&yy);
%per_y(&y_01);
%per_y(&y_02);
%per_y(&y_03);

PROC SQL;

/*count number of rotational groups available for longitudinal (normally 3)*/
%if &RYYYY < 2014 OR &cc=UK %then %do;
	SELECT (COUNT(DISTINCT R62.DB075 )) as N_DB075 into :N_DB075 FROM WORK.R62 WHERE DB075 ne .;
%end;
%else %do;
	SELECT (COUNT(DISTINCT R62.DB075 )-1) as N_DB075 into :N_DB075 FROM WORK.R62 WHERE DB075 ne .;
%end;
/*create table with rotational group, 1st and 2nd year they appear in the data*/

 CREATE TABLE WORK.Y1_DB075 AS SELECT DISTINCT (MIN(R60.RB010)) AS RB010,
	 R60.DB075,
	 (MIN(R60.RB010)+1) AS Y2
 FROM WORK.R60 AS R60
 WHERE R60.DB075 NOT IS MISSING 
 GROUP BY R60.DB075;
QUIT;

PROC FORMAT;

/*RB100: sampled/coresident*/
	Value RB100f
	    1='1'
		2='2'
		99='N/A'
		.='TOTAL';

/*RB110: membership Status*/

	Value RB110f
	    1='1'
		2='2'
		3='3'
		4='4'
		5='5'
		6='6'
		7='7'
		12='1 or 2'
		99='N/A'
		.= 'TOTAL';

	Value DB075f
	    1='1'
		2='2'
		3='3'
		4='4'
		5='5'
		6='6'
		7='7'
		8='8'
		9='9'
		10='10'
		11='11'
		12='12'
		13='13'
		14='14'
		99='N/A'
		.= 'TOTAL';

/*Var_1 and Var_2*/
	Value Valf
		.='          N/A';
RUN;

ODS HTML CLOSE;
%mend select0;
%select0;