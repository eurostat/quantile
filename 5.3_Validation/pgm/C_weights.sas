		ODS HTML close;
		ods listing;
options notes nosource nosource2 nomlogic nomprint nosymbolgen;
*options notes source source2 mlogic mprint symbolgen;

PROC DATASETS lib=work kill nolist;
QUIT;

libname ssd "G_PING_RAWDB/&cc/&ss&yy";
filename ccfile "&G_PING_LIBCONFIG/country.csv"; *** country labels; 
filename report "&G_PING_RAWDB/&cc/&ss&yy/&ss&cc&yy..WEIGHTS.lst"; *assign report file; 

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
	ssl = "early-transmission";
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

/*--------------------------------------*/
libname lib "&G_PING_RAWDB/&cc/&ss&yy";

OPTIONS NONUMBER NODATE;
%LET LIBRARY=&G_PING_RAWDB/&cc/&ss&yy; /* folder (unquoted) where the output datasets should be placed */
LIBNAME OUT "&LIBRARY";

/**********************************************/
/* COUNTING THE OBSERVATIONS IN A SAS DATASET */
/**********************************************/

%MACRO COUNT_OBS(DATASET=);
  %GLOBAL COUNT;
  DATA _NULL_;
   SET &DATASET NOBS=NOBS;
   CALL SYMPUT('COUNT',PUT(NOBS,5.));
   STOP;
  RUN;
%MEND COUNT_OBS;

/*********************/
/* OUTLIER DETECTION */
/*********************/

%MACRO OUTLIERS(DATASET=,LIBRARY=,VARINT=,FACTOR=,ID=);
  *** Calculation of the quartiles;

  PROC UNIVARIATE DATA=&LIBRARY..&DATASET NOPRINT;
   VAR &VARINT;
   OUTPUT OUT=SORTIE(KEEP=P_25 P_50 P_75) PCTLPRE=P_ PCTLPTS=25 TO 100 BY 25;

  *** Determination of the outlying observations;

  PROC SQL;
   CREATE TABLE OUTLIERS_&VARINT AS
   SELECT A.*,
   CASE
     WHEN ((A.&VARINT - B.P_50)>=%SYSEVALF(&FACTOR)*(P_75-P_25) OR (A.&VARINT - B.P_50)<=-%SYSEVALF(&FACTOR)*(P_75-P_25)) 
     THEN 1
     ELSE 0
   END AS OUTLIER
   FROM &LIBRARY..&DATASET AS A, SORTIE AS B;
  QUIT;

  *** Editing the outlying observations;

  DATA OUTLIERS_&VARINT;
   SET OUTLIERS_&VARINT;
   IF OUTLIER=1;
  RUN;

  %COUNT_OBS(DATASET=OUTLIERS_&VARINT)

  DATA _NULL_;
   file report mod;
   PUT ' ';
   PUT "> &COUNT outliers have been detected in &VARINT";
  RUN;

PROC RANK DATA=OUTLIERS_&VARINT OUT=OUTL TIES=LOW DESCENDING;
	VAR &VARINT;
	RANKS rank;
 RUN;

PROC PRINTTO print=report;
 RUN;

PROC PRINT DATA=OUTL NOOBS LABEL;
   VAR %substr(&DATASET,1,1)B030 &VARINT; 
 where rank < 11; 
 RUN;

 PROC PRINTTO;
 RUN;

%MEND OUTLIERS;

%MACRO BXPLT(DATASET=,LIBRARY=,VARINT=,FACTOR=,ID=);

  DATA TEMP;
   SET &LIBRARY..&DATASET;
   X='_ALL_';
  RUN;

  *** Boxplots of the distribution;

   PROC BOXPLOT DATA=TEMP;
   PLOT &VARINT.*X/BOXSTYLE=SCHEMATICIDFAR;
   ID &ID;
  RUN;

%MEND BXPLT;

/*************************************/
/* SUMMARY STATISTICS ON THE WEIGHTS */
/*************************************/

%MACRO SUMMARY_STAT(DATASET=,LIBRARY=,VARINT=,GROUP=);
  DATA _NULL_;
  file report mod;
  PUT ' ';
  PUT ' ';
  PUT "SUMMARY STATISTICS ON &VARINT";
  RUN;
  %IF &GROUP = 1 %THEN %DO;
     PROC SORT DATA=&LIBRARY..&DATASET;
      BY DB075;
  %END;

  %IF &GROUP = 1 %THEN %DO;
     PROC MEANS DATA=&LIBRARY..&DATASET NOPRINT;
      VAR &VARINT;
      BY DB075;
      OUTPUT OUT=SORTIE(DROP=_TYPE_ _FREQ_) 
      N=N NMISS=NMISS MIN=MIN MEAN=MEAN MAX=MAX STD=STD SUM=SUM CV=CV;
  %END;

  %ELSE %DO;
     PROC MEANS DATA=&LIBRARY..&DATASET NOPRINT;
      VAR &VARINT;
      OUTPUT OUT=SORTIE(DROP=_TYPE_ _FREQ_) 
      N=N NMISS=NMISS MIN=MIN MEAN=MEAN MAX=MAX STD=STD SUM=SUM CV=CV;
  %END;

PROC PRINTTO print=report;
RUN;

PROC PRINT DATA=SORTIE NOOBS;
RUN;

PROC PRINTTO;
RUN;

DATA _NULL_;
   file report mod;
   SET SORTIE;
   PUT ' ';
   IF NMISS > 0 THEN PUT "> Some values of &VARINT are missing";
   IF MIN <= 0  THEN PUT "> Some values of &VARINT are negative or 0";
   IF CV >= &THRES THEN PUT "> The CV of &VARINT is higher than &THRES.%";
RUN;

%MEND SUMMARY_STAT;

/**************************/
/* INTEGRATED CALIBRATION */
/**************************/

%MACRO INTEG_CALIB;
  TITLE;

  PROC SQL;
   CREATE TABLE TEMP AS
   SELECT R.RB050/D.DB090 AS RATIO
   FROM R,D
   WHERE INT(R.RB030/100)=D.DB030;
  QUIT; 

  PROC MEANS DATA=TEMP NOPRINT;
   VAR RATIO;
   OUTPUT OUT=SORTIE MEAN=MEAN STD=STD;

  DATA SORTIE;
   file report mod;
   SET SORTIE;
   IF INT(MEAN)=1 AND INT(STD)=0 THEN PUT '> Yes'; ELSE PUT '> No';
   PUT "Mean(RB050/DB090) = " MEAN;
   PUT "Std(RB050/DB090) = " STD;
  RUN;

%MEND INTEG_CALIB;

/*******************************/
/* STATISTICS ON THE G-WEIGHTS */
/*******************************/

%MACRO ADJ;
  TITLE;

  PROC SQL;
   CREATE TABLE TEMP AS
   SELECT (DB090/DB080)*(MEAN(DB080)/MEAN(DB090)) AS GWEIGHT
   FROM D
   WHERE DB080>0 AND DB090>0;
  QUIT; 

  PROC MEANS DATA=TEMP N MIN MEAN MAX STD CV;
   VAR GWEIGHT;
   OUTPUT OUT=SORTIE CV=CV;

DATA _NULL_;
   file report mod;
   SET SORTIE;
   IF CV >= &THRES THEN PUT "> The CV of the G-weights is higher than &THRES.%";
   ELSE PUT "./.";
  RUN;

%MEND ADJ;

/*****************************************/
/* ADJUSTMENT FOR INDIVIDUAL NONRESPONSE */
/*****************************************/

%MACRO IND_NONREP;

  TITLE;

  PROC SQL;
   CREATE TABLE TEMP AS
   SELECT R.RB050/P.PB040 AS RATIO
   FROM R,P
   WHERE R.RB030=P.PB030;
  QUIT; 

  PROC MEANS DATA=TEMP NOPRINT;
   VAR RATIO;
   OUTPUT OUT=SORTIE MEAN=MEAN STD=STD;

  DATA SORTIE;
   file report mod;
   SET SORTIE;
   IF INT(MEAN)=1 AND INT(STD)=0 THEN PUT '> No'; ELSE PUT '> Yes';
   PUT "Mean(RB050/PB040) = " MEAN;
   PUT "Std(RB050/PB040) = " STD;
 RUN;

%MEND IND_NONREP;

/*****************************************************************************************/
/************************************* MAIN PROGRAM **************************************/
/*****************************************************************************************/

%MACRO START;

DATA REF;
 COUNTRY=UPCASE(PUT(SYMGET('CC'),2.));
 YEAR=20!!PUT(SYMGET('YY'),2.);
 WAVE=PUT(SYMGET('WW'),1.);
 SEL_RESP=UPCASE(PUT(SYMGET('SEL_RESP'),1.));
 FACTOR=PUT(SYMGET('FACTOR'),8.);
 THRES=PUT(SYMGET('THRES'),2.);
 OUTPUT;
RUN;

*** Uploading of the datasets;

DATA D D1;
 SET LIB.&ss&CC&YY.D(keep=DB010 DB020 DB030 DB080 DB090 DB075 DB135);
 IF DB010 < &RYYYY THEN DELETE;
 OUTPUT D;
 IF DB135=1 THEN OUTPUT D1;
%if "&ss" = "r" %then %do;
	DATA R;
 	SET LIB.&ss&CC&YY.R(keep=RB010 RB020 RB030 RB050 RB110);
	IF RB010 < &RYYYY THEN DELETE;
 	IF RB110 > 4 THEN DELETE;
 %end;
 %else %do;
	DATA R;
 	SET LIB.&ss&CC&YY.R(keep=RB010 RB020 RB030 RB050);
 	IF RB010 < &RYYYY THEN DELETE;
%end;

DATA P P1;
 SET LIB.&ss&CC&YY.P(keep=PB010 PB020 PB030 PB040 PB060);
 IF PB010 < &RYYYY THEN DELETE;
 OUTPUT P;
 IF PB060>0 THEN OUTPUT P1;
RUN;

DATA RES;
 SET _NULL_;
RUN;

TITLE;

DATA _NULL_;
   file report mod;
   PUT ' ';
   PUT '*** 1. SUMMARY STATISTICS ON THE WEIGHTS ***';
RUN;

%IF &WW=1 %THEN %SUMMARY_STAT(DATASET=D,LIBRARY=WORK,VARINT=DB080,GROUP=0);
          %ELSE %SUMMARY_STAT(DATASET=D,LIBRARY=WORK,VARINT=DB080,GROUP=1);

%SUMMARY_STAT(DATASET=D1,LIBRARY=WORK,VARINT=DB090,GROUP=0;)

%OUTLIERS(DATASET=D1,LIBRARY=WORK,VARINT=DB090,FACTOR=&FACTOR,ID=DB030);

%SUMMARY_STAT(DATASET=R,LIBRARY=WORK,VARINT=RB050,GROUP=0);

%OUTLIERS(DATASET=R,LIBRARY=WORK,VARINT=RB050,FACTOR=&FACTOR,ID=RB030);

%SUMMARY_STAT(DATASET=P,LIBRARY=WORK,VARINT=PB040,GROUP=0);

%OUTLIERS(DATASET=P,LIBRARY=WORK,VARINT=PB040,FACTOR=&FACTOR,ID=PB030);

%IF %UPCASE(&SEL_RESP)=Y %THEN 
  %DO;
     %SUMMARY_STAT(DATASET=P1,LIBRARY=WORK,VARINT=PB060,GROUP=0)
     %OUTLIERS(DATASET=P1,LIBRARY=WORK,VARINT=PB060,FACTOR=&FACTOR,ID=PB030)
  %END;

  DATA _NULL_;
   file report mod;
   PUT ' ';
   PUT ' ';
   PUT '*** 2. INTEGRATED CALIBRATION ***';
  RUN;

%INTEG_CALIB;

  DATA _NULL_;
   file report mod;
   PUT ' ';
   PUT ' ';
   PUT '*** 3. STATISTICS ON THE G-WEIGHTS ***';
  RUN;

%ADJ;

  DATA _NULL_;
   file report mod;
   PUT ' ';
   PUT ' ';
   PUT '*** 4. ADJUSTMENT FOR INDIVIDUAL NONRESPONSE ***';
  RUN;

%IND_NONREP;

ods listing close;
ODS HTML(ID=EGHTML) FILE=EGHTML STYLE=EGDefault;

 TITLE '*** SUMMARY STATISTICS ON THE WEIGHTS ***';

 TITLE2 'OUTLIERS - BOXPLOTS';

%BXPLT(DATASET=D1,LIBRARY=WORK,VARINT=DB090,FACTOR=&FACTOR,ID=DB030);

%BXPLT(DATASET=R,LIBRARY=WORK,VARINT=RB050,FACTOR=&FACTOR,ID=RB030);

%BXPLT(DATASET=P,LIBRARY=WORK,VARINT=PB040,FACTOR=&FACTOR,ID=PB030);

%IF %UPCASE(&SEL_RESP)=Y %THEN 
  %DO;
     %BXPLT(DATASET=P1,LIBRARY=WORK,VARINT=PB060,FACTOR=&FACTOR,ID=PB030)
  %END;

%MEND START;

%START

PROC PRINTTO;

RUN;

ODS  _ALL_ CLOSE;



