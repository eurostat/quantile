/* For reminder: parameters of the macro program UPLOAD_TO_EUROBASE
 *    	filename : full path of the file name that needs to be uploaded or validated.
 *    	action : possible choices (in lowercase) among
 *    			- send: submit the change request to Eurobase Upload Service (default),        
 *				- validate: validate the file header and user permission to submit the file to Eurobase,              
 *				- feedback: retrieve the feedback for one element by its id.
 *    	target : choices: staging/production 
 *				- production: REFINEurobase Production,               
 *				- staging: REFTEST Eurobase Staging (default),
 *    	action_feedback_fbid : id number if action=feedback; otherwise it is not used.
 *    	_feedback_id_ : name of the macro variable to which the feedback_id is assigned.
 *    	_status_code_ : name of the macro variable to which the statusCode is assigned.
 *    	rename_file : boolean flag (Y/y/YES/yes or no/NO/N/n); if the parameter contains a 'y' then the 
 *			feedback_id is appended to the name in the filename in unix.
 * See page 6 of installation guidelines of the "Macro UPLOAD_TO_EUROBASE user guide" document.
 */

%macro ncfile_upload(ncfile, target);
	%let status_code=;
	%let feedback_id=;

	%if "&target"^="staging" and "&target"^="production" and "&target"^="testing" %then %do;
		%put !!! wrong target: must be either testing, or production or staging !!!;
		%goto exit;
	%end;
		
	/* first validate */
	%upload_to_eurobase(filename=&ncfile, action=validate, target=&target, _status_code_=status_code);

	%if status_code^=0 %then %do;
		%put !!! validation of file &ncfile failed !!!;
		%goto exit;
	%end;

	/* possibly stop here if in testing mode (i.e., do not send!) */
	%if "&target"="testing" %then %goto exit;

	/* then send */
	%upload_to_eurobase(filename=&ncfile,action=send, target=&target, 
						_feedback_id_=feedback_id, _status_code_=status_code);

	%if status_code^=0 %then %do;
		%put !!! sending file &ncfile to &target failed !!!;
		/* %goto exit; */
	%end;

	%exit:

	/* &feedback_id */

%mend ncfile_upload;


%macro _test_ncfile_upload;
%let ncfile=/ec/prod/server/sas/0eusilc/Upload/pgmX/160331_2011_DI01.txt;
%ncfile_upload(ncfile, testing);
%mend _test_ncfile_upload;
