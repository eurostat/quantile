%let yy=%substr(&year,3,2);

Data tmp.log;
	Format date ddmmyys10.;
   	Format time time5.;
	Length user $8;
	length report $80;
	  date = "&sysdate"d;	
	  time = "&systime"t;	
	  user = "&sysuserid";
      report = "*** init ***";
Run;

PROC SQL;
CREATE TABLE tmp.rate_ppp 
	(YEAR num,
	 COUNTRY char(2),
	 RATE num ,
	 CURRENCY char(3),
	 PPP num);
INSERT into tmp.rate_ppp 
    values(&year, "&cntr", &rate, "", &ppp);
QUIT;

PROC SQL;
CREATE TABLE tmp.idx2005
	(GEO char(2),
	 TIME num,
	 IDX2005 num);
INSERT into tmp.idx2005
    values("&cntr", &year, &idx2005);
QUIT;

PROC SQL;
CREATE TABLE tmp.IDB05
	 (DB010 num,
	 DB020 char(2),
	 ARPT60 num);
INSERT into tmp.IDB05
    values(&year, "&cntr", &arpt2005);
QUIT;

%macro idb;
PROC SQL;
* initialize IDB by year ----------------------------------------;
CREATE TABLE  tmp.IDB&yy 
	 (DB010 num,
	 DB020 char(2),
	 DB030 num ,
	 RB030 num ,
	 RB050 num ,
	 RB050a num ,
	 RB070 num ,
	 RB080 num ,
	 AGE num ,
	 RB090 num ,
	 PB040 num ,
	 PE40 num ,
	 PL31 num,
%if &year < 2009 %then %do;
	 PL070 num ,
	 PL072 num ,
%end;
%else %do;
	 PL073 num,
	 PL074 num,
	 PL075 num,
	 PL076 num,
%end;
	 PL040 num ,
	 PL060 num ,
	 PL085 num ,
	 PL140 num ,
	 PY200G num ,
	 EQ_SS num ,
	 EQ_INC20 num ,
	 EQ_INC22 num ,
	 EQ_INC23 num , 
	 ARPT60i num ,
	 ARPT40i num ,
	 ARPT50i num ,
	 ARPT70i num ,
 	 ARPT60Mi num ,
	 ARPT40Mi num ,
	 ARPT50Mi num ,
	 QITILE num ,
	 MEAN20 num ,
	 MEDIAN20 num ,
	 ARPT60 num ,
	 ARPT40 num ,
	 ARPT50 num ,
	 ARPT70 num,
	 ARPT60M num ,
	 ARPT40M num ,
	 ARPT50M num ,
	 HT num ,
	 N_ADU num ,
	 N_DCH num , 
	 TENSTA num ,
	 MORTGAGE num,
	 WISTA num,
	 CHD num,
	 ACTSTA num,
	 INCWRK num,
	 INCPEN num,
	 MAININC num,
	 RATE num ,
	 PPP num ,
	 EQ_INC20eur num ,
	 EQ_INC22eur num ,
	 EQ_INC23eur num ,
	 EQ_INC20ppp num ,
	 EQ_INC22ppp num ,
	 EQ_INC23ppp num ,
	 DB090 num,
	 HHSIZE num,
	 HT1 num,
	 DEPRIVED num,
	 SEV_DEP num,
	 EXT_DEP num,
	 DEP_RELIABILITY num,
	 LWI num,
	 WORK_INT num,
	 C_BIRTH num,
	 CIT_SHIP num,
	 TENSTA_2 num,
	 OVERCROWDED num,
	 AROPE char(8),
	 LASTADD char (8),
     LASTUPD char(8),
     LASTUSER char(8));
QUIT;
%mend idb;
