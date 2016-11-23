/*****************************************************************************/
/* Application : SAS                                                      */
/* Survey      : --                                                      */
/* Macro       : UPLOAD_TO_EUROBASE.sas                                           */
/* Description : Load files to eurobase calling web service 		*/
/* Group       : Tools                                                       */
/*__________________________________________________________________________ */
/* Localisation: ?????            */
/* Release     : SAS 9.2 under UNIX                                        */
/*__________________________________________________________________________ */
/* Creation    :gryseol                  */
/* Last updated: 09/09/2014 (felklka: adding secure env.)                    */
/*__________________________________________________________________________ */
/* Call by     : ?????                                       */
/*****************************************************************************/
/*********/
/* INPUT */
/*****************************************************************************/

/* PARM : 	filename: full path of the file name that needs to be uploaded or validated.
		action: possible choices: send /validate/feedback (small letters)
							this choice lets you send the file or validate the file 	
							(see "Using the client from a Command-Line Interface" on citnet for the actions
							performed during validation.).
		target: choices: staging/ production 
				from "Using the client from a Command-Line Interface" on citnet:
               	- production : Eurobase Production (REFIN)+               
				- staging    : Eurobase Staging    (REFTEST)
		feedbackid: In case action is feedback, the paramter needs to be filled in. 
					Otherwise it can be left empty.

*/

/*__________________________________________________________________________ */

/* GLOB  : 
 */

/*__________________________________________________________________________ */
/*********/
/* MACRO */
/*****************************************************************************/
/*****************************************************************************/

/*
Macrovariables that need to be set:
javadirsasestt2, javadirsasestp2, jardirsasestt2, jardirsasestp2, jardirwin

*/

/***********/
/* CONTROL */
/*****************************************************************************/
/*****************************************************************************/
/**********/
/* SAMPLE */
/*****************************************************************************/

/*
%let fp=/home/user/gryseol/test/Macro_Upload_Eurobase/;
%let target=staging;
%let action=validate;
%UPLOAD_TO_EUROBASE(&fp.TC_227.zip,action=&action, target=&target);

example for send to production:
%let fp=/home/user/gryseol/test/Macro_Upload_Eurobase/;
%let target=production;
%let action=send;
%UPLOAD_TO_EUROBASE(&fp.TC_227.zip,action=&action, target=&target);

*/

/*****************************************************************************/
/*********/
/* MODIF */
/*****************************************************************************/
/* */
/*****************************************************************************/
/****************************/
%MACRO UPLOAD_TO_EUROBASE(filename=, action= send ,target=staging,feedbackid=);
	/* Control input file exist */
	%local SECURE javadirsasestst javadirsasestsp javadirsasestt2  javadirsasestp2 jardirsasests jardirsasestp jardirsasestt2 jardirsasestp2 jardirwin;

	%let javadirsasestst=/usr/jdk/instances/jdk1.6.0/jre/bin/;
	%let javadirsasestsp=/usr/jdk/instances/jdk1.6.0/jre/bin/;
	%let javadirsasestt2=/ec/test/sas/sasestt2/bin/SAS/jdk1.6.0_16/jre/bin/;
	%let javadirsasestp2=/ec/prod/sas/sasestp2/bin/SAS/jdk1.6.0_16/bin/;
	%let jardirsasestst=/ec/prod/server/sas/bin/;
	%let jardirsasestsp=/ec/prod/server/sas/bin/;
	%let jardirsasestt2=/ec/dev/app/SASESTAT/;
	%let jardirsasestp2=/ec/prod/app/SASESTAT/;
	%let jardirwin=C:\Pgm\EurobaseUpload\;

	%IF %BQUOTE(&filename)= %THEN
		%DO;
			%IF &action ^=feedback %THEN
				%DO;
					%put Provide a filename !!!;

					%return;
				%END;
		%END;
	%ELSE
		%DO;
			%if %sysfunc(fileexist(&filename)) = 0 %then
				%do;
					%put Input file &filename does not exist!!!;

					%return;
				%end;
		%END;

	%IF &action=feedback %THEN
		%DO;
			%IF  &feedbackid= %THEN
				%DO;
					%put Provide a feedbackid when action=feedback is selected!;

					%return;
				%END;
			%ELSE
				%DO;
					%let action = &action &feedbackid;
					%let filename=;
				%END;
		%END;

	%if &target ^= %THEN
		%DO;
			%LET target=-t &target;
		%END;

	%IF &SYSSCP=WIN %THEN
		%DO;
			%if %sysfunc(fileexist(&jardirwin.ws-client.jar)) = 0 %then
				%do;
					%put Jarfile not found in  &jardirwin!!!;

					%return;
				%end;

			filename clntver pipe "java -jar &jardirwin.ws-client.jar version  1>&2";

			data _NULL_;
				infile clntver;
			run;

			filename s_java pipe "java -jar &jardirwin.ws-client.jar    -a &action &target &filename  1>&2";

			data _NULL_;
				infile s_java;
			run;

		%END;
	%ELSE
		%DO;
			filename servname pipe  'hostname';
			%let SECURE=0;

			data _NULL_;
				infile servname pad end=eof;
				input lines $255.;

				if _N_=1 then
					do;
						put '===============================================';
						put 'Server: ';
					end;

				put lines;

				if strip(lines) = "s-baikal" then
					do;
						call symputx('javadir',"&javadirsasestst",'L');
						call symputx('jardir',"&jardirsasestst",'L');
						call symputx('SECURE','1','L');
					end;
				else if strip(lines) = "s-caspian" then
					do;
						call symputx('javadir',"&javadirsasestsp",'L');
						call symputx('jardir',"&jardirsasestsp",'L');
						call symputx('SECURE','1','L');
					end;
				else if strip(lines) = "sasestt2.cc.cec.eu.int" then
					do;
						call symputx('javadir',"&javadirsasestt2",'L');
						call symputx('jardir',"&jardirsasestt2",'L');
						call symputx('SECURE','0','L');
					end;
				else if strip(lines) = "sasestp2.cc.cec.eu.int" then
					do;
						call symputx('javadir',"&javadirsasestp2",'L');
						call symputx('jardir',"&jardirsasestp2",'L');
						call symputx('SECURE','0','L');
					end;

				if eof then
					put '===============================================';
			run;

			%put jardir: &jardir;
			%put javadir: &javadir;

			/*	%IF &SECURE=1 %THEN %RETURN; */
			%if %sysfunc(fileexist(&javadir.java)) = 0 %then
				%do;
					%put Java executable not found in &javadir!!!;

					%return;
				%end;

			%if %sysfunc(fileexist(&jardir.ws-client.jar)) = 0 %then
				%do;
					%put Jar file ws-client not found in &jardir!!!;

					%return;
				%end;

			filename clntver pipe "&javadir.java -jar &jardir.ws-client.jar version";

			data _NULL_;
				infile clntver pad end=eof;
				length lines $ 255;
				input lines $ char255.;

				if _N_=1 then
					do;
						put '==================================================';
						put "Version of ws_client.jar:";
					end;

				put lines;

				if eof then
					put '==================================================';
			run;

			filename s_java pipe "&javadir.java -jar &jardir.ws-client.jar   -a &action &target &filename ";

			data _NULL_;
				infile s_java pad end=eof;
				length lines $ 255;
				input lines $ char255.;

				if _N_=1 then
					do;
						put '==================================================';
						put "Message in the unix standard output window:";
					end;

				put lines;

				if eof then
					put '==================================================';
			run;

		%END;
%MEND UPLOAD_TO_EUROBASE;

%let fp=/home/eshome/felklka/Eurobase/;

/*test 1 */
DM "log; clear; ";
%let target=staging;

%let action=send;
/* %let action=validate; */
%let fn=TC_241_1.dat;
%let filename=&fp.TC_241_1.dat;

%UPLOAD_TO_EUROBASE(filename=&filename, action=&action, target=&target);
