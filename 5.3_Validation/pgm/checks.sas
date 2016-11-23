/*EUSILC checking programs V3*/
%global eusilc csvfiles dfile rfile hfile pfile cc yy yy1 yy2 RYYYY ss f errmax nrow ccnam errors sel_resp ww factor thres N_DB075;
%global  RCC y_1 y_2 y_3 ok1 loadOK;
options nonotes nosource nosource2 nomlogic nomprint nosymbolgen;
*options notes source source2 mlogic mprint symbolgen;



ods listing;

/*parameters*/

%let RYYYY=2014; 	/* year of the survey  */
%let RCC=HU;		/* country code in capital letters  */
%let RCL=R;			/* type of data: C=cross-sectional E=early-transmission L=longitudinal R=Regular */
%let eusilc= Z:\main;      /* define main path to eusilc programs and data, Eurostat default=Z:\main;  */


/*cross_sectional weight check parameters*/
%let sel_resp=n;  /* put it to y if you use selected respondent concept*/
%let ww=1;  /* keep it to 1*/
%let factor=1.8;  
%let thres=75;
/*cross_sectional comparison with last year parameters*/
%let th=5; /* threshold in % a difference above the threshold give an observation in the output file*/
%let rate=1;  /* keep it to 1 unless you changed currency */
/*global parameters*/
%let errmax=30;            /* define maximum number of error to display in output files */
%let nrow=8;               /* define maximum number of row to display per year in output files */
%let jump=1;               /* 1 = display files window, 0 = jump over */
/* added (MG 02.06.2015) to identify in which system the program runs*/
%macro win_or_unix;
%if &sysscp = WIN %then  %let del=CRLF;
%else %let del=LF;
%mend;
%win_or_unix;
/* aa ne w macro added here (BG 11.07.2014) for making the command lowcase working on local installation */
%macro lowcase(string);
%sysfunc(lowcase(%nrbquote(&string)))
%mend;



%let cc=%lowcase(&RCC);
%let yy=%substr(&RYYYY,3,2);
%let ss=%lowcase(&RCL);
%let yy2=9999;

%include "&eusilc/pgm/files.txt"; /* input files */
%include "&eusilc/pgm/main7.sas";  /* run program */


