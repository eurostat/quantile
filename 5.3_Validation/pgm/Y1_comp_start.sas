
options symbolgen mlogic source2 notes nodate;
%global y1 s1;

%macro previousyear;
	%if &yy>10 %then %let y1=%eval(&yy -1);
	%if &yy<11	%then %let y1=0%eval(&yy -1);
%mend previousyear;
%previousyear;

%macro previousfile;/* assign type of previous file (e,c or r) according to file and year*/
	%if (&rYYYY<2015 and (&ss=r or &ss=e)) %then %do;
		%let s1=c;
	%end; 
	%else%if (&rYYYY>2014 and &ss=e) %then %do;
		%let s1=r;
	%end;
	%else %do;
		%let s1=&ss;
	%end;
%mend previousfile;
%previousfile;

libname silc "&G_PING_RAWDB/&cc/&ss&yy"; 
libname silcprev "&G_PING_RAWDB/&cc/&s1&y1"; 


/*create the discrete difference file*/
data work.discrete_diff;
FORMAT COUNTRY $2. 
VARIABLE $8. 
MODALITY 4.1 
VAL_diff_percent 4.0
SILC_&yy._percent 4.1
SILC_&y1._percent 4.1
N_obs_&yy 8.0
N_obs_&y1 8.0
N_Obs_diff 4.0
;
run;

/*create the continuous difference file*/
data work.cont_diff;
FORMAT COUNTRY $2. 
VARIABLE $8. 
PERCENTILE $8.
VAL_diff_percent 4.0
SILC_&yy._value 12.
SILC_&y1._value 12.
N_obs_&yy 8.0
N_obs_&y1 8.0
N_Obs_diff_percent 4.0
;
run;
