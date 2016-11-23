
/* GPG (only BE  IE  GR  ES  IT  PT  UK  ?AT) */
%macro UPD_gpg(yyyy,Ucc,Uccs,flag) /store;
/* flags are taken from the existing data set  on 7/12/2010 */
%if &Ucc=BE or &Ucc=IE or &Ucc=GR or &Ucc=ES or &Ucc=IT or &Ucc=PT or &Ucc=UK or &Ucc=AT  
%then %do;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=GPG;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);

/* Hourly earnings: PY200G / PL060 * 4.33
     Keep only records with age in range 16-64, non-missing sex
 	 and PY200G > 0, PL060 >= 15                         */
PROC SQL noprint;
Create table work.idb as 
	select distinct DB010, DB020, DB030, RB030, AGE, RB090, PB040, PL060, PY200G,
		(PY200G / (PL060 * 4.33)) as HOUREARN
	from idb.IDB&yy
	where PL040 = 3 
	and (AGE ge 16 and AGE le 64)
	and RB090 in (1,2)
	and PY200G > 0 
	and PL060 ge 15 
	and DB010 = &yyyy and DB020 ="&Ucc";
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.gpg like rdb.gpg; 
QUIT;

%if &nobs > 0 
%then %do;

/* Calculation of gender pay gap */
PROC MEANS DATA=work.idb noprint  
    NWAY
    MEAN
	SUMWGT
    NONOBS;
VAR HOUREARN; 
CLASS RB090 / ORDER=UNFORMATTED;
WEIGHT PB040; 
OUTPUT OUT=work.gpgmean 
    MEAN=mean SUMWGT=sumwgt;
RUN;

DATA work.gpg0 (keep=ntot totwgh malemean femmean gpg);
set work.gpgmean end=last;
retain malemean femmean ntot totwgh;
if RB090 = 1 then malemean = mean;
if RB090 = 2 then femmean = mean;
ntot = sum(ntot,_freq_);
totwgh = sum(sumwgt,totwgh);
if last then
do;
	gpg = ((malemean - femmean) / malemean) * 100;
	output;
end;
RUN;

PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  indic_il,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy  and geo ="&Ucc";


INSERT INTO gpg SELECT 
	"&Ucc" as geo,
	&yyyy as time,
	"GPG" as indic_il,
	gpg as ivalue,
	old_flag.iflag as iflag,
	/*"&flag" as iflag FORMAT=$3. LENGTH=3, */
	ntot,
	totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM work.gpg0, old_flag;
QUIT;

* Update RDB;  
DATA  rdb.GPG;
set rdb.GPG(where=(not(time = &yyyy and geo = "&Ucc")))
    work.gpg; 
if time ne . and geo ne "";
run;
 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * GPG (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO GPG DATA !";		  
QUIT;
 
%end;
%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO GPG CALCULATION";		  
QUIT;
%end;

%mend UPD_gpg;
