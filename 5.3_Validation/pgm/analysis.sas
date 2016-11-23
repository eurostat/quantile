*options    notes source  source2 mlogic   mprint    symbolgen;

libname ssd "&G_PING_RAWDB/&cc/&ss&yy";
filename ccfile "&G_PING_CONFIG/country.csv"; *** country labels; 
filename report "&G_PING_RAWDB/&cc/&ss&yy/&ss&cc&yy..ANALYSIS.lst"; *assign report file; 


DATA _null_;
 infile ccfile MISSOVER DSD firstobs=1 TERMSTR=CRLF;
 format code $2.;
 format ccname $20.;
 input code ccname;
 if lowcase(code) = "&cc" then call symput("ccnam",compress(ccname));
RUN;
DATA _null_;
if "&ss" = "c" then do;
	ssl = "cross-sectional";
	years = "20&yy";
end;
if "&ss" = "e" then do;
	ssl = "early_transmission";
	years = "20&yy";
end;
if "&ss" = "r" then do;
	ssl = "regular-transmission";
	years = "20&yy";
end;
ucc = upcase("&cc");
file report;
	put "date = &sysdate";
	put "time = &systime";
	put "user = &sysuserid";
	put "-------------------------------------------------";
	put "survey = " ssl;
	put "year(s) = " years;
	put "country = " ucc "(&ccnam)";
	put "-------------------------------------------------";
RUN;


*1+2*sample size*;
DATA _null_;
   input cc $ hh_c hh_l p16_c p16_l hh_c_p hh_l_p p16_c_p p16_l_p;
   if cc = "&cc" then do;
		call symput("z1hh",hh_c);
		call symput("z116",p16_c);
		call symput("z2hh",hh_c_p);
		call symput("z216",p16_c_p);
	end;
   * tables I and II of doc65;
   datalines;
be   4750   3500   8750    6500    6500    5000   12000   9250 
bg   4500   3500   10000   7500    7500    5750   15750   12250
cz   4750   3500   10000   7500    7500    5750   15750   12250
dk   4250   3250   7250    5500    5500    4250   9500    7250 
de   8250   6000   14500   10500   11000   8000   19250   14000
ee   3500   2750   7750    5750    5750    4500   12750   9500 
el   4750   3500   10000   7250    7500    5500   15750   11500
es   6500   5000   16000   12250   12000   9250   29500   22750
fr   7250   5500   13500   10250   10250   7750   19000   14500
ie   3750   2750   8000    6000    6000    4500   12750   9750 
it   7250   5500   15500   11750   11750   8750   25000   18750
cy   3250   2500   7500    5500    5750    4250   13250   9250 
lv   3750   2750   8500    6500    6500    5000   14750   11750
lt   4000   3000   9000    6750    6750    5000   15250   11250
lu   3250   2500   6500    5000    5000    3750   10000   7500 
hu   4750   3500   10250   7750    7750    5750   16750   12750
mt   3000   2250   7000    5250    5250    4000   12250   9250 
nl   5000   3750   8750    6500    6500    5000   11500   8750 
at   4500   3250   8750    6250    6500    4750   12750   9250 
pl   6000   4500   15000   11250   11250   8500   28250   21250
pt   4500   3250   10500   7500    8000    5750   18750   13250
ro   5250   4000   12750   9500    12000   9250   29500   22750
si   3750   2750   9000    6750    6750    5000   16250   12250
sk   4250   3250   11000   8250    8250    6250   21250   15750
fi   4000   3000   6750    5000    5000    3750   8500    6250 
se   4500   3500   7500    5750    5750    4500   9500    7500 
uk   7500   5750   13750   10500   10250   8000   18750   14500
is   2250   1700   3750    2800    3000    2000   5000    3250 
no   3750   2750   6250    4650    4750    3500   8000    6000 
hr   4250   3250   9250    7000    5500    4250   9500    7250 
ch   4500   3250   8750    6250    6500    4750   12750   9250
tr   7750	5750   
mk   3750   3000   11500   8750
rs   4500   3500   
me   3250   2500   
xx	 0      0      0       0       0       0      0       0   
;
RUN;
%macro boucle;
PROC SQL;
 CREATE TABLE tmp1 AS SELECT DISTINCT (COUNT(DB135)) AS DB135_1
 FROM ssd.&ss&cc&yy.d
 WHERE DB135 = 1 AND DB010=&RYYYY;
QUIT;

DATA _null_;
file report mod;
set tmp1;
z1 = compress(&z1hh);
z2 = compress(&z2hh);
r1 = DB135_1 - z1;
put "==================================================="; 
put "1. Number of households";
put "   {DB135=1} >= sample size in framework regulation";
put "==================================================="; 
put "   N(DB135=1) = " DB135_1;
put "   Sample size I = " z1;
put "   Sample size II = " z2;
if DB135_1 < z1 then do;
	put "==> Household sample size not achieved";
	put "==> " DB135_1 "- " z1 "= " r1;
	end;
put " ";
RUN;

PROC SQL;
 CREATE TABLE tmp2 AS SELECT DISTINCT (COUNT(RB250)) AS RB250_11f
 FROM ssd.&ss&cc&yy.r
 %if &ss = r %then %do;
 	WHERE RB250 in (11,12,13) AND RB110 < 5 AND RB010=&RYYYY;
 %end;
 %else %do;
	WHERE RB250 in (11,12,13) AND RB010=&RYYYY;
 %end;
QUIT;

DATA _null_;
file report mod;
set tmp2;
z1 = compress(&z116);
z2 = compress(&z216);
r1 = RB250_11f - z1;
put "==============================================================="; 
put "2. Number of persons aged 16+";
put "   {RB250 in (11,12,13)} >= sample size in framework regulation";
put "==============================================================="; 
put "   N(RB250 in (11,12,13)) = " RB250_11f;
put "   Sample size I = " z1;
put "   Sample size II = " z2;
if RB250_11f < z1 then do;
	put "==> Persons aged 16+ sample size not achieved";
	put "==> " RB250_11f "- " z1 "= " r1;
	end;
put " ";
RUN;

*3+4*Non-response*;
PROC SQL;
 CREATE TABLE tmp3 AS SELECT DISTINCT (COUNT(DB010)) AS DB120_11f
 FROM ssd.&ss&cc&yy.d
 %if &ss = r or &ss = e %then %do;
 	WHERE (DB120 in (11,21,22) OR DB110 = 1) AND DB010=&RYYYY;
 %end;
 %else %do;
	WHERE (DB120 in (11,21,22)) AND DB010=&RYYYY;
 %end;
 
 CREATE TABLE tmp4 AS SELECT DISTINCT (COUNT(DB135)) AS DB135_1
 FROM ssd.&ss&cc&yy.d
 WHERE DB135 = 1 AND DB010=&RYYYY;
QUIT;

DATA _null_;
file report mod;
merge tmp3 tmp4;
format NRh 6.2;
NRh = (1-(DB135_1/DB120_11f))*100;
put "========================================================"; 
put "3. Household non-response rate";
put "   (1 - ({DB135=1} / {DB120 in (11,21,22)})) * 100 =< 40%";
put "========================================================"; 
put "   HH non-response rate = " Nrh;
if Nrh > 40 then do;
	put "==> Household non-response rate too high";
	put "==> N(DB120 in (11,21,22) = " DB120_11f "/ N(DB135=1) = " DB135_1;
	end;
put " ";
RUN;

PROC SQL;
 CREATE TABLE tmp5 AS SELECT DISTINCT (COUNT(RB245)) AS RB245_1f
 FROM ssd.&ss&cc&yy.r
 WHERE RB245 in (1,2,3) AND RB010=&RYYYY;
 CREATE TABLE tmp6 AS SELECT DISTINCT (COUNT(RB250)) AS RB250_11f
 FROM ssd.&ss&cc&yy.r
 %if &ss = r %then %do;
 	WHERE RB250 in (11,12,13) AND RB110 < 5 AND RB010=&RYYYY;
 %end;
 %else %do;
	WHERE RB250 in (11,12,13) AND RB010=&RYYYY;
 %end;
 
QUIT;

DATA _null_;
file report mod;
merge tmp5 tmp6;
format NRp 6.2;
NRp = (1-(RB250_11f/RB245_1f))*100;
put "================================================================="; 
put "4. Personal non-response rate";
put "   (1 - ({RB250 in (11,12,13)} / {RB245 in (1,2,3)})) * 100 =< 1%";
put "================================================================="; 
put "   Personal non-response rate = " Nrp;
if Nrp > 1 then do;
	put "==> Personal non-response rate too high";
	put "==> N(RB245 in (1,2,2)) = " RB245_1f "/ N(RB250 in (11,12,13)) = " RB250_11f;
	end;
put " ";
RUN;

 %if &ss ne e %then %do;
	*5*Interview Duration*;
	PROC SQL;
	 CREATE TABLE tmp7 AS SELECT DISTINCT HB010, HB030, HB100,
		(SUM(PB120)) AS sum_PB120,
	    (HB100 + CALCULATED sum_PB120) AS tot_hh
	 FROM ssd.&ss&cc&yy.h INNER JOIN ssd.&ss&cc&yy.p
	 ON ((int(PB030/100) = HB030) AND (HB010 = PB010))
	 WHERE HB010=&RYYYY
	 GROUP BY HB030 ;


	 CREATE TABLE tmp8 AS SELECT DISTINCT   
		 (MEAN(tot_hh)) AS hhmean
	 FROM tmp7;
	QUIT;

	DATA _null_;
	file report mod;
	set tmp8;
	format hhmean 3.0;
	put "================================="; 
	put "5. Average Interview Duration";
	put "   Mean({HB100+PB120}by HH) =< 60";
	put "================================="; 
	put "   Average Interview Duration (minutes) = " hhmean;
	if hhmean > 60 then do;
		put "==> Average Interview Duration over 60 minutes";
		end;
	put " ";
	RUN;

	*6*Proxy Interviews*;
	PROC SQL;
	 CREATE TABLE tmp9 AS SELECT DISTINCT (COUNT(RB250)) AS RB250_11f
	 FROM ssd.&ss&cc&yy.r
	 %if &ss = r %then %do;
	 	WHERE RB245 in (1,2) and RB250 in (11,12,13) AND RB110 < 5 AND RB010=&RYYYY;
	 %end;
	 %else %do;
		WHERE RB245 in (1,2) and RB250 in (11,12,13) AND RB010=&RYYYY;
	 %end;
	 
	 CREATE TABLE tmp10 AS SELECT DISTINCT (COUNT(RB260_F)) AS RB260_5
	 FROM ssd.&ss&cc&yy.r 
	 %if &ss = r %then %do;
	 	WHERE RB245 in (1,2) and RB260 > 5 and RB110 < 5 AND RB010=&RYYYY;
	 %end;
	 %else %if &ss ne r and &RYYYY >2013 %then %do;
		WHERE RB245 in (1,2) and RB260 > 5 AND RB010=&RYYYY;
	 %end;
	 %else %do;
		WHERE RB245 in (1,2) and RB260 = 5 AND RB010=&RYYYY;
	 %end;
	 
	QUIT;

	DATA _null_;
	file report mod;
	merge tmp9 tmp10;
	format prox 6.2;
	prox = 100 / RB250_11f * RB260_5;
	put "====================================================================="; 
	put "6. % Proxy Interviews";
	%if &RYYYY < 2014 %then %do;
		put "   100 / {RB245 in (1,2) and RB250 in (11,12,13)} * {RB260 = 5} =< 10";
	%end;
	%else %do;
		put "   100 / {RB245 in (1,2) and RB250 in (11,12,13)} * {RB260 > 5} =< 10";
	%end;
	put "====================================================================="; 
	put "   Proxy Interviews (%) = " prox;
	if prox > 10 then do;
		put "==> Number of proxy interviews to high";
		put "==> N(RB245 in (1,2) and RB250 in (11,12,13)) = " RB250_11f "/ N(RB260=5) = " RB260_5;
		end;
	put " ";
	RUN;
%end;
%mend boucle;
%boucle;


