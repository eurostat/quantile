options MRECALL;

options MAUTOSOURCE SASAUTOS =(SASAUTOS 
								"&LIBRARY/autocall"  
								);							

%db_setpath(&EUSILC, legacy=&legacy, test=&test);

/* directory path */
%global CURDIR UPDIR;
%let CURDIR=&eusilc/%path_getcurrent(path=pathdrive);
%let UPDIR=&eusilc/%path_getcurrent(path=pathdrive, parent=yes);

options MAUTOSOURCE SASAUTOS =(SASAUTOS 
								"&UPDIR/pgm/process"  
								/* in addition we add the macro for eurobase upload:
 								 * see page 5 of installation guidelines of the "Macro UPLOAD_TO_EUROBASE user guide" document. */
								"&UPDIR/pgm/report"  
								"&UPDIR/pgm/rules"  
								%macro define_path_eurobaseupload;
									%let pgm_ebupload=upload_to_eurobase;
									%let path_ebupload=;
									%if %sysevalf(%sysfunc(fileexist(&SASServer/misc/eurobaseupload/&pgm_ebupload..sas))) %then %do;
										%let path_ebupload=&SASServer/misc/eurobaseupload/;
									%end;
									%else %if %sysevalf(%sysfunc(fileexist(&EUSILC/Upload/pgm/eurobase/&pgm_ebupload..sas))) %then %do;
										%let path_ebupload=&EUSILC/Upload/pgm/eurobase;		
									%end;
									"&path_ebupload"
									/* returns typically: "&SASServer/misc/eurobaseupload" */
								%mend;
								);							

options NOMRECALL;

