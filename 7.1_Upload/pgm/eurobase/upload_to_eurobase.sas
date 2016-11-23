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
		action_feedback_fbid: In case action is feedback, the paramter needs to be filled in. 
					Otherwise it can be left empty.
		_feedback_id_=feedback_id: the name of the macro variable to which the feedback_id will be assigned. 
									The name of the macro variable can't be the same as the input parameter.
									if _feedback_id_ is empty then no value will be assigned.
		_status_code_=status_code: the name of the macro variable to which the statusCode will be assigned. 
									The name of the macro variable can't be the same as the input parameter.
									if _status_code_ is empty then no value will be assigned
		rename_file=NO/YES: if yes then the feedbackid will be appended to the filename as an extension: .&&&feedback_id

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
javadirsasestst, javadirsasestsp, javadirsasestt2, javadirsasestp2, 
jardirsasestst, jardirsasestsp, jardirsasestt2, jardirsasestp2, jardirwin

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
%let fn=TC_241_1.dat;
%UPLOAD_TO_EUROBASE(filename=&fp.&fn,
					action=feedback,
					action_feedback_fbid=8825, 
					_feedback_id_=feedback_id,
					_status_code_=status_code);
%put outside the macro status_code: ;
%put status_code: &status_code.;
%put feedback_id: &feedback_id.;

*/

/*****************************************************************************/
/*********/
/* MODIF */
/*****************************************************************************/
/*20140909:felklka: extension to secure domain*/
/*20150921: gryseol: 	add the macro variables feedback_id and status_code +
						add the possibility to add the feedback_id to the filename of the uploaded file as extension.	*/
/* */
/*****************************************************************************/
/****************************/
%MACRO upload_to_eurobase(filename=, action= send ,target=staging,action_feedback_fbid=,_feedback_id_=feedback_id,_status_code_=status_code,rename_file=NO);
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
	%let jardirwin=/ec/prod/server/sas/bin/; 
	/* %let jardirwin=/ec/prod/server/sas/0eusilc/Upload/pgm/; */

	%IF &_feedback_id_^= %THEN %DO;
		%global &_feedback_id_.;
		%let &_feedback_id_.=;
	%END;
	%IF &_status_code_^= %THEN %DO;
		%global &_status_code_.;
		%let &_status_code_.=;
	%END;

	%IF %BQUOTE(&filename)= %THEN %DO;
		%IF &action ^=feedback %THEN %DO;
			%put Provide a filename !!!;
			%return;
		%END;
	%END;
	%ELSE %DO;
		%if %sysfunc(fileexist(&filename)) = 0 %then %do;
			%put Input file &filename does not exist!!!;
			%return;
		%end;
	%END;

	%IF &action=feedback %THEN %DO;
		%IF  &action_feedback_fbid= %THEN %DO;
			%put Provide a feedbackid when action=feedback is selected!;
			%return;
		%END;
		%ELSE %DO;
			%let action = &action &action_feedback_fbid;
			%let filename=;
			/*%IF &_feedback_id_^= %THEN %DO;
				%let &_feedback_id_.=&action_feedback_fbid;
			%END;*/
		%END;
	%END;

	%if &target ^= %THEN %DO;
		%LET target=-t &target;
	%END;
	%IF &SYSSCP=WIN %THEN %DO;
		%if %sysfunc(fileexist(&jardirwin.ws-client.jar)) = 0 %then %do;
			%put Jarfile not found in  &jardirwin!!!;
			%return;
		%end;

		filename clntver pipe "java -jar &jardirwin.ws-client.jar version  1>&2";

		data _NULL_;
			infile clntver;
		run;

		/*filename s_java pipe "java -jar &jardirwin.ws-client.jar    -a &action &target &filename  2<&1";*/
		filename s_java pipe "java -jar &jardirwin.ws-client.jar    -a &action &target &filename  2>&1";/*only statustCode is collected with _NULL_ and tmp */

		data _NULL_ ;
			infile s_java;
			length lines search_string $ 255 ;
			input;
			lines=_infile_;
			put _infile_;/*In windows this is necessary, otherwise not written to the log*/
			%IF &_feedback_id_ ^= %THEN %DO;
				search_string='INFO: WebService replied with feedback id';
				search_string_pos=index(lines,strip(search_string));
				if search_string_pos>0 then call symputx("&_feedback_id_.",substr(lines,search_string_pos+length(search_string)),'G');
			%END;
			%IF &_status_code_ ^= %THEN %DO;
				search_string='Exiting with statusCode=';
				search_string_pos=index(lines,strip(search_string));
				if search_string_pos>0 then call symputx("&_status_code_.",substr(lines,search_string_pos+length(strip(search_string))),'G');
			%END;
		run;

		%IF %INDEX(%UPCASE(&rename_file),Y)>0 and &_feedback_id_.^= and %INDEX(%lowcase(&action),send)>0 %THEN %DO;
			%if %symexist(&_feedback_id_.) %then %do;/*in case action = validate there will be no value assigned to */
				%IF &&&_feedback_id_. ^= %THEN %DO;
					filename rn pipe "rename &filename %scan(&filename,-1,\).&&&_feedback_id_. ";
					data _NULL_;
						infile rn;
						stop;
					run;
				%END;
			%end;
		%END;
	%END;
	%ELSE %DO;
		filename servname pipe  'hostname';
		%let SECURE=0;

		data _NULL_;
			infile servname pad end=eof;
			input lines $255.;

			if _N_=1 then
				do;
					put '=================================================================================================================';
					put 'Server: ';
				end;

			put lines;

			if strip(lines) = "s-lomond" then do;
				call symputx('javadir',"&javadirsasestst",'L');
				call symputx('jardir',"&jardirsasestst",'L');
				call symputx('SECURE','1','L');
			end;
			else if strip(lines) = "s-ness" then do;
				call symputx('javadir',"&javadirsasestsp",'L');
				call symputx('jardir',"&jardirsasestsp",'L');
				call symputx('SECURE','1','L');
			end;
			else if strip(lines) = "sasestt2.cc.cec.eu.int" then do;
				call symputx('javadir',"&javadirsasestt2",'L');
				call symputx('jardir',"&jardirsasestt2",'L');
				call symputx('SECURE','0','L');
			end;
			else if strip(lines) = "sasestp2.cc.cec.eu.int" then do;
				call symputx('javadir',"&javadirsasestp2",'L');
				call symputx('jardir',"&jardirsasestp2",'L');
				call symputx('SECURE','0','L');
			end;
			if eof then put '=================================================================================================================';
		run;

		%put jardir: &jardir;
		%put javadir: &javadir;

		%if %sysfunc(fileexist(&javadir.java)) = 0 %then %do;
			%put Java executable not found in &javadir!!!;
			%return;
		%end;
		%if %sysfunc(fileexist(&jardir.ws-client.jar)) = 0 %then %do;
			%put Jar file ws-client not found in &jardir!!!;
			%return;
		%end;

		filename clntver pipe "&javadir.java -jar &jardir.ws-client.jar version";

		data _NULL_;
			infile clntver pad end=eof;
			length lines $ 255;
			input lines $ char255.;

			if _N_=1 then do;
				put '=================================================================================================================';
				put "Version of ws_client.jar:";
			end;
			put lines;
			if eof then put '=================================================================================================================';
		run;

		filename s_java pipe "&javadir.java -jar &jardir.ws-client.jar   -a &action &target &filename ";
		data _NULL_;
			infile s_java pad end=eof;
			length lines search_string $ 255 ;
			input lines $ char255.;
			%IF &_feedback_id_ ^= %THEN %DO;
				search_string='INFO: WebService replied with feedback id';
				search_string_pos=index(lines,strip(search_string));
				if search_string_pos>0 then call symputx("&_feedback_id_.",substr(lines,search_string_pos+length(search_string)),'G');
			%END;
			%IF &_status_code_ ^= %THEN %DO;
				search_string='Exiting with statusCode=';
				search_string_pos=index(lines,strip(search_string));
				if search_string_pos>0 then call symputx("&_status_code_.",substr(lines,search_string_pos+length(strip(search_string))),'G');
			%END;
			if _N_=1 then do;
				put '=================================================================================================================';
				put "Message in the unix standard output window:";
			end;
			put lines;

			if eof then
				put '=================================================================================================================';
		run;
		%IF %INDEX(%UPCASE(&rename_file),Y)>0 and &_feedback_id_.^= and %INDEX(%lowcase(&action),send)>0 %THEN %DO;
			%if %symexist(&_feedback_id_.) %then %do;
				%IF &&&_feedback_id_. ^= %THEN %DO;
					filename rn pipe "mv &filename &filename..&&&_feedback_id_. ";
					data _NULL_;
						infile rn;
						stop;
					run;
				%END;
			%end;
		%END;

	%END;
%MEND upload_to_eurobase;

