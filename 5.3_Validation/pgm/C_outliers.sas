/* OUTLIERS.SAS data outliers report
/*--------------------------------------*/

ODS HTML close;
/*--------------------------------------*/


PROC DATASETS lib=work kill nolist;
QUIT;

options nodate pageno=1 papersize=A4 ORIENTATION=PORTRAIT ;
options nocenter linesize=82 pagesize=60 formchar='|----|+|---';
options nonotes;
ODS LISTING;
*options    notes source  source2 mlogic   mprint    symbolgen;

libname ssd "&G_PING_RAWDB/&cc/&ss&yy";
filename ccfile "&G_PING_CONFIG/country.csv"; *** country labels; 
filename report "&G_PING_RAWDB/&cc/&ss&yy/&ss&cc&yy..OUTLIERS.lst"; *assign report file; 
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

if "&ss" = "r" then do;
	ssl = "regular";
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

%macro outliers(var);
%let f=%substr(&var,1,1); 
PROC SORT data=ssd.&ss&cc&yy.&f(keep=&f.B010 &f.B020 &f.B030 &var) out=srta;
by &var;
where (&var not in(0,.) and &f.B010 = 20&yy);
RUN;
PROC SORT data=srta out=srtd;
by descending &var;
RUN;


PROC MEANS DATA=srta NOPRINT QMETHOD=OS VARDEF=DF NONOBS Q1 Q3;
	VAR &var;
	OUTPUT OUT=pcts Q1()=x14 Q3()=x34;
RUN;

PROC SQL;
%if &var=HY145N %then %do;
  CREATE TABLE lbub AS SELECT 
	 ("&var") as varnam informat $6., x14, x34,
	 (x14-(3*(x34-x14))) AS lbx,
	 (x34+(3*(x34-x14))) AS ubx 
 FROM pcts;
%end;
 %else %do;
 CREATE TABLE lbub AS SELECT 
	 ("&var") as varnam informat $6., x14, x34,
	 (EXP(LOG(x14)-(3*(LOG(x34)-LOG(x14))))) AS lbx,
	 (EXP(LOG(x34)+(3*(LOG(x34)-LOG(x14))))) AS ubx 
 FROM pcts;
%end;
 CREATE TABLE lrev AS SELECT srta.&f.B020 as Country, srta.&f.B030 as ID format 12.,
 	lbub.varnam format $6.,
 	srta.&var as value,
	("low ") as typ,
	lbub.lbx, lbub.ubx
 FROM srta , lbub
 where &var < lbx;
 CREATE TABLE clrev AS SELECT distinct Country,
 	varnam, typ, lbx, ubx,
 	(count(*)) as count
 FROM lrev;

CREATE TABLE hrev AS SELECT srtd.&f.B020 as Country, srtd.&f.B030 as ID format 12.,
 	lbub.varnam format $6.,
 	srtd.&var as value,
	("high") as typ,
	lbub.lbx, lbub.ubx
 FROM srtd , lbub
 where &var > ubx;
 CREATE TABLE chrev AS SELECT distinct Country,
 	varnam, typ, lbx, ubx,
 	(count(*)) as count
 FROM hrev;

QUIT;

PROC RANK DATA = lrev OUT=lrev TIES=LOW;
	VAR value;
	RANKS rank;
RUN;
PROC RANK DATA = hrev OUT=hrev TIES=LOW;
	VAR value;
	RANKS rank;
RUN;

PROC APPEND base=lvals data=lrev force;
PROC APPEND base=hvals data=hrev force;
RUN;

PROC APPEND base=lhcnts data=clrev force;
PROC APPEND base=lhcnts data=chrev force;
RUN;

/*PROC APPEND base=lbuball data=lbub force;
RUN;*/
%mend outliers;

%macro print;
PROC PRINTTO print=report;
RUN;

/*PROC PRINT DATA=lbuball label noobs;
title2 "quartiles and bounderies";
	VAR varnam x14 x34 lbx ubx;
	label varnam='Variable'
		 x14='Q1'
		 x34='Q3'
         lbx='Lower Boundery'
         ubx='Upper Boundery';
	format x14 x34 lbx ubx 12.2;
RUN;*/

PROC TABULATE DATA=lhcnts ;
title "OUTLIERS - overview";
	VAR lbx ubx count;
	CLASS country;
	CLASS typ / DESCENDING ORDER=UNFORMATTED MISSING;
	CLASS varnam /	ORDER=UNFORMATTED MISSING;
	TABLE country="", varnam="",
			(typ=""*count="N"*F=12.0)*min=""
		/BOX={LABEL=_PAGE_};
	WHERE varnam ne "";
RUN;

PROC SORT DATA=hvals;
	BY varnam;
RUN;
PROC PRINT DATA=hvals label noobs;
title "OUTLIERS - high values";
	BY varnam ubx;
	ID varnam ubx;
	VAR ID value;
	label varnam='Variable'
		 value= 'Value'
		ubx= 'boundary'
;
	format ubx 12.2;
	where rank < 6 and (value-ubx) > 1000;
RUN;

PROC SORT DATA=lvals;
	BY varnam;
RUN;
PROC PRINT DATA=lvals label noobs;
title "OUTLIERS - low values";
	BY varnam lbx;
	ID varnam lbx;
	VAR ID value;
	label varnam='Variable'
		 value= 'Value'
		lbx= 'boundary'
;
	format lbx 12.2;
	where rank < 6 and (lbx-value) > 1000;
RUN;


PROC PRINTTO;
RUN;

%mend print;

PROC DATASETS library=work nolist;
delete lhvals lhcnts lh_T_vals lh_T_cnts lh_HN_vals lh_HN_cnts lh_HG_vals lh_HG_cnts
			lh_PN_vals lh_PN_cnts lh_PG_vals lh_PG_cnts lbuball;
RUN;
 


%outliers(HY040G);
%outliers(HY050G);
%outliers(HY060G);
%outliers(HY070G);
%outliers(HY080G);
%outliers(HY090G);
%outliers(HY100G);
%outliers(HY110G);
%outliers(HY120G);
%outliers(HY130G);
%outliers(HY140G);

%outliers(HY040N);
%outliers(HY050N);
%outliers(HY060N);
%outliers(HY070N);
%outliers(HY080N);
%outliers(HY090N);
%outliers(HY100N);
%outliers(HY110N);
%outliers(HY120N);
%outliers(HY130N);
%outliers(HY140N);
%outliers(HY145N);

%outliers(PY010G);
%outliers(PY020G);
%outliers(PY035G);
%outliers(PY050G);
%outliers(PY070G);
%outliers(PY080G);
%outliers(PY090G);
%outliers(PY100G);
%outliers(PY110G);
%outliers(PY120G);
%outliers(PY130G);
%outliers(PY140G);

%outliers(PY010N);
%outliers(PY020N);
%outliers(PY035N);
%outliers(PY050N);
%outliers(PY070N);
%outliers(PY080N);
%outliers(PY090N);
%outliers(PY100N);
%outliers(PY110N);
%outliers(PY120N);
%outliers(PY130N);
%outliers(PY140N);

%outliers(HY010);
%outliers(HY020);
%outliers(HY022);
%outliers(HY023);

options nodate pageno=1 pagesize=600 byline;
%print;

ODS  _ALL_ CLOSE;
