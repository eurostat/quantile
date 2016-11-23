%macro EXP_FData(tab,yyyy,Uccs) /store ;

%if &tab=LI01 %then %let rd=12.;
%else %if &tab=PNP2 or &tab=PNP3 or &tab=PNS2 or &tab=PNP10 or &tab=PNP11 or &tab=PNS11 %then %let rd=10.2;
%else %let rd=10.1;

%let tabin=&tab;
%if &tab=PNS2 %then %let tabin=PNP2;
%if &tab=PNS11 %then %let tabin=PNP10;
%if &tab=PNP11 %then %let tabin=PNP3;

%if &tabin=PEPS11 OR &tabin=LI41 OR &tabin=MDDD21 OR &tabin=LVHL21 %then %do;
		PROC SQL noprint;
		Create table work.tmp as 
			select *
			from rdb.&tabin
			where time in &yyyy and substr(geo,1,2) in &Uccs ;
		QUIT;
%end; 
%else %do;
PROC SQL noprint;
Create table work.tmp as 
	select *
	from rdb.&tabin
	where time in &yyyy and geo in &Uccs;
QUIT;
%end;


	%let Utab=%upcase(&tab);
	DATA _null_;
	sdat = put("&sysdate"d,yymmdd6.);
	nc = sdat||"_"||compress("&Utab");
	call symput("nc",nc);
	RUN;

	%if &tab=OT01 or &tab=OT02 or &tab=OT03 or 
		&tab=OT04 or &tab=OT05 or &tab=OT06 %then %do; 
	DATA tmp1;
	set tmp;
	where indic_il = "LI_R_MD60";
		indic_il = "TOTAL";
		ivalue = totpop;
		output;
		indic_il = "POOR";
		ivalue = poorpop;
		output;
	RUN;
	%end;
	%else %if &tab=PN30 %then %do; 
	DATA tmp1;
	set tmp;
		ivalue = totpop;
	RUN;
	%end;
	%else %if &tab=PN31 %then %do; 
	DATA tmp1;
	set tmp;
	where TENURE not in ("OWN_NL", "OWN_L"); 
		ivalue = totpop;
	RUN;
	%end;
	%else %if &tab=PN21 %then %do; 
	DATA tmp1;
	set tmp;
	where TENURE not in ("OWN_NL", "OWN_L"); 
	RUN;
	%end;
	%else %if &tab=PNP2 %then %do; 
	DATA tmp1;
	set tmp;
	where INDIC_IL = ("R_GE65_LT65"); 
	RUN;
	%end;
	%else %if &tab=PNS2 %then %do; 
	DATA tmp1;
	set tmp;
	where INDIC_IL = ("R_GE60_LT60"); 
	RUN;
	%end;
	%else %if &tab=PNP9 %then %do; 
	DATA tmp1;
	set tmp;
	where hhtyp = "A1"; 
	RUN;
	%end;
	%else %if &tab=PNP10 %then %do; 
	DATA tmp1;
	set tmp;
	where INDIC_IL = ("R_GE65_LT65") and hhtyp = "A1"; 
	RUN;
	%end;
	%else %if &tab=PNS11 %then %do; 
	DATA tmp1;
	set tmp;
	where INDIC_IL in ("R_GE60_LT60","R_GE75_LT75") and hhtyp = "A1"; 
	RUN;
	%end;

	%else %if &tab=LI22 %then %do; 
	DATA tmp1;
	set tmp;
	where GEO not in ("EU25", "EU27",  "NMS10", "NMS12", "BG", "RO", "FR"); 
	RUN;
	%end;

	%else %if &tab=lvho07a %then %do; 
	DATA tmp1;
	set tmp;
	/*where GEO ne ("DE"); */
	RUN;
	%end;

	%else %if &tab=lvho07b %then %do; 
	DATA tmp1;
	set tmp;
	/*where GEO ne ("DE"); */
	RUN;
	%end;

	%else %if &tab=lvho07c %then %do; 
	DATA tmp1;
	set tmp;
	/*where GEO ne ("DE"); */
	RUN;
	%end;

	%else %if &tab=lvho07d %then %do; 
	DATA tmp1;
	set tmp;
	/*where GEO ne ("DE"); */
	RUN;
	%end;

	%else %if &tab=lvho07e %then %do; 
	DATA tmp1;
	set tmp;
	/*where GEO ne ("DE"); */
	RUN;
	%end;

	%else %if &tab=lvho08a %then %do; 
	DATA tmp1;
	set tmp;
	/*where GEO ne ("DE"); */
	RUN;
	%end;

	%else %if &tab=lvho08b %then %do; 
	DATA tmp1;
	set tmp;
	/*where GEO ne ("DE"); */
	RUN;
	%end;

	%else %do; 
	DATA tmp1;
	set tmp;
	RUN;
	%end;

	/* replace GR with EL for all occurencies */

	data tmp1 (drop= LEN GEOx GEOrest) ;set tmp1;
	len = LENGTH(GEO); 
	if len =2 and GEO="GR" then GEO="EL";
	IF len >2 and substr(geo,1, 2)= "GR" then do;
   		GEOx="EL";
   		GEOrest=substr(geo,3,len);
   		GEO=cats(GEOx, GEOrest); 
	end; 
	run;
	filename ncfile "&eusilc/&idbrdb/newcronos/&nc..txt" TERMSTR=CRLF;
	DATA _null_;
	set work.tmp1 end=last;
	length refval $ 50;
	file ncfile;

	if _N_ = 1 then do;
		put "FLAT_FILE=STANDARD";
		%if %substr(&Utab,1,2)=OT %then %let Utab=OTH%substr(&Utab,3,2);
		%if %substr(&Utab,1,2)=PN %then %let Utab=ILC_&Utab;
		%if &Utab=SIC5 %then %let Utab=LI22;
		%if &Utab=OV9B1 %then %let Utab=SIP8;
		%if &Utab=OV9B2 %then %let Utab=SIS4;

		put "ID_KEYS=SAS,ILC,&Utab";
		%if &tab=LI01 %then  put "FIELDS=GEO,TIME,INDIC_IL,HHTYP,CURRENCY";
		%else %if &tab=DI01 %then  put "FIELDS=GEO,TIME,INDIC_IL,CURRENCY,QUANTILE";
		%else %if &tab=LI02 or &tab=OT01 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL,UNIT"; 
	 	%else %if &tab=DI02 %then put "FIELDS=GEO,TIME,INCGRP,INDIC_IL,CURRENCY";
		%else %if &tab=DI03 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL,UNIT"; 
		%else %if &tab=LI03 or &tab=OT03 %then put "FIELDS=GEO,TIME,HHTYP,INDIC_IL";
		%else %if &tab=DI04 %then put "FIELDS=GEO,TIME,HHTYP,INDIC_IL,UNIT";
		%else %if &tab=LI04 or &tab=OT02 %then put "FIELDS=GEO,TIME,AGE,SEX,WSTATUS,INDIC_IL";
		%else %if &tab=DI05 %then put "FIELDS=GEO,TIME,AGE,SEX,WSTATUS,INDIC_IL,UNIT";
		%else %if &tab=LI06 or &tab=OT05 %then put "FIELDS=GEO,TIME,AGE,SEX,HHTYP,WORKINT,INDIC_IL";
		%else %if &tab=DI07 %then put "FIELDS=GEO,TIME,AGE,SEX,HHTYP,WORKINT,INDIC_IL,UNIT";
		%else %if &tab=LI07 or &tab=OT06 %then put "FIELDS=GEO,TIME,AGE,SEX,ISCED97,INDIC_IL";
		%else %if &tab=DI08 %then put "FIELDS=GEO,TIME,AGE,SEX,ISCED97,INDIC_IL,UNIT";
		%else %if &tab=LI08 or &tab=OT04 %then put "FIELDS=GEO,TIME,AGE,SEX,TENURE,INDIC_IL";
		%else %if &tab=DI09 %then put "FIELDS=GEO,TIME,AGE,SEX,TENURE,INDIC_IL,UNIT";
		%else %if &tab=DI10 %then put "FIELDS=GEO,TIME,INDIC_IL,SUBJNMON,UNIT";
		%else %if &tab=DI13 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL,UNIT";
		%else %if &tab=DI13b %then put "FIELDS=GEO,TIME,HHTYP,INDIC_IL,UNIT";
		%else %if &tab=DI14 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL,UNIT";
		%else %if &tab=DI14b %then put "FIELDS=GEO,TIME,HHTYP,INDIC_IL,UNIT";
		%else %if &tab=DI15 %then put "FIELDS=GEO,TIME,AGE,SEX,CITIZEN,INDIC_IL,UNIT";
		%else %if &tab=DI16 %then put "FIELDS=GEO,TIME,AGE,SEX,C_BIRTH,INDIC_IL,UNIT";
		%else %if &tab=DI17 %then put "FIELDS=GEO,TIME,AGE,SEX,DEG_URB,INDIC_IL,UNIT";
		%else %if &tab=DI20 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL,UNIT";
		%else %if &tab=DI23 %then put "FIELDS=GEO,TIME,DEG_URB,INDIC_IL,UNIT";
		%else %if &tab=DI27 %then put "FIELDS=GEO,TIME,ISCED97,INDIC_IL,UNIT";

		%else %if &tab=LI09 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL";
		%else %if &tab=LI09b %then put "FIELDS=GEO,TIME,HHTYP,UNIT";
		%else %if &tab=LI10 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL";
		%else %if &tab=LI10b %then put "FIELDS=GEO,TIME,HHTYP,UNIT";
		%else %if &tab=LI11 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL";
		%else %if &tab=LI22 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL";
		%else %if &tab=LI22b %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL,UNIT";
		%else %if &tab=LI31 %then put "FIELDS=GEO,TIME,AGE,SEX,CITIZEN";
		%else %if &tab=LI32 %then put "FIELDS=GEO,TIME,AGE,SEX,C_BIRTH";
		%else %if &tab=LI60 %then put "FIELDS=GEO,TIME,AGE,ISCED97,UNIT";

		%else %if &tab=LI41  %then put "FIELDS=GEO,TIME,UNIT";
		%else %if &tab=LI45  %then put "FIELDS=GEO,TIME,AGE,SEX";
		%else %if &tab=LI48  %then put "FIELDS=GEO,TIME,DEG_URB";
		%else %if &tab=DI11 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL";
		%else %if &tab=DI12 %then put "FIELDS=GEO,TIME,INDIC_IL";
		%else %if &tab=DI12b %then put "FIELDS=GEO,TIME,INDIC_IL";
		%else %if &tab=DI12c %then put "FIELDS=GEO,TIME,INDIC_IL";
		%else %if &tab=IW01 %then put "FIELDS=GEO,TIME,AGE,SEX,WSTATUS";
		%else %if &tab=IW02 %then put "FIELDS=GEO,TIME,HHTYP";
		%else %if &tab=IW03 %then put "FIELDS=GEO,TIME,HHTYP,WORKINT";
		%else %if &tab=IW04 %then put "FIELDS=GEO,TIME,ISCED97";
		%else %if &tab=IW05 %then put "FIELDS=GEO,TIME,WSTATUS,SEX";
		%else %if &tab=IW06 %then put "FIELDS=GEO,TIME,DURATION";
		%else %if &tab=IW07 %then put "FIELDS=GEO,TIME,WORKTIME";
		%else %if &tab=IW15 %then put "FIELDS=GEO,TIME,AGE,SEX,CITIZEN,UNIT";
		%else %if &tab=IW16 %then put "FIELDS=GEO,TIME,AGE,SEX,C_BIRTH,UNIT";

		%else %if &tab=PNP2 %then put "FIELDS=GEO,TIME,SEX,INDIC_IL";
		%else %if &tab=PNP3 %then put "FIELDS=GEO,TIME,SEX,INDIC_IL";
		%else %if &tab=PNS2 %then put "FIELDS=GEO,TIME,SEX,INDIC_IL";
		%else %if &tab=PNP9 %then put "FIELDS=GEO,TIME,AGE,SEX,HHTYP,INDIC_IL";
		%else %if &tab=PNP10 %then put "FIELDS=GEO,TIME,INDIC_IL,SEX,HHTYP";
		%else %if &tab=PNP11 %then put "FIELDS=GEO,TIME,SEX,INDIC_IL";
		%else %if &tab=PNS11 %then put "FIELDS=GEO,TIME,INDIC_IL,SEX,HHTYP";
		%else %if &tab=OV9b1 %then put "FIELDS=GEO,TIME,AGE,SEX,UNIT,N_ITEM";
		%else %if &tab=OV9b2 %then put "FIELDS=GEO,TIME,AGE,SEX,UNIT";
	
		%else %if &tab=PEPS01 %then put "FIELDS=GEO,TIME,AGE,SEX,UNIT";
		%else %if &tab=PEPS02 %then put "FIELDS=GEO,TIME,AGE,SEX,WSTATUS";
		%else %if &tab=PEPS03 %then put "FIELDS=GEO,TIME,QUANTILE,HHTYP";
		%else %if &tab=PEPS04 %then put "FIELDS=GEO,TIME,AGE,SEX,ISCED97";
		%else %if &tab=PEPS05 %then put "FIELDS=GEO,TIME,AGE,SEX,CITIZEN";
		%else %if &tab=PEPS06 %then put "FIELDS=GEO,TIME,AGE,SEX,C_BIRTH";
		%else %if &tab=PEPS07 %then put "FIELDS=GEO,TIME,TENURE,UNIT";
		%else %if &tab=PEPS11 %then put "FIELDS=GEO,TIME,UNIT";
		%else %if &tab=PEPS60 %then put "FIELDS=GEO,TIME,AGE,ISCED97,UNIT";

		%else %if &tab=MDDD11 %then put "FIELDS=GEO,TIME,AGE,SEX,UNIT";
		%else %if &tab=MDDD12 %then put "FIELDS=GEO,TIME,AGE,SEX,WSTATUS";
		%else %if &tab=MDDD13 %then put "FIELDS=GEO,TIME,QUANTILE,HHTYP";
		%else %if &tab=MDDD14 %then put "FIELDS=GEO,TIME,AGE,SEX,ISCED97";
		%else %if &tab=MDDD15 %then put "FIELDS=GEO,TIME,AGE,SEX,CITIZEN";
		%else %if &tab=MDDD16 %then put "FIELDS=GEO,TIME,AGE,SEX,C_BIRTH";
		%else %if &tab=MDDD17 %then put "FIELDS=GEO,TIME,TENURE,UNIT";
		%else %if &tab=MDDD21  %then put "FIELDS=GEO,TIME,UNIT";
		%else %if &tab=MDDD60 %then put "FIELDS=GEO,TIME,AGE,ISCED97,UNIT";

		%else %if &tab=LVHL11 %then put "FIELDS=GEO,TIME,AGE,SEX,UNIT";
		%else %if &tab=LVHL12 %then put "FIELDS=GEO,TIME,AGE,SEX,WSTATUS";
		%else %if &tab=LVHL13 %then put "FIELDS=GEO,TIME,QUANTILE,HHTYP";
		%else %if &tab=LVHL14 %then put "FIELDS=GEO,TIME,AGE,SEX,ISCED97";
	    %else %if &tab=LVHL15 %then put "FIELDS=GEO,TIME,AGE,SEX,CITIZEN";
		%else %if &tab=LVHL16 %then put "FIELDS=GEO,TIME,AGE,SEX,C_BIRTH";
		%else %if &tab=LVHL17 %then put "FIELDS=GEO,TIME,TENURE,UNIT";
		%else %if &tab=LVHL21 %then put "FIELDS=GEO,TIME,UNIT";
		%else %if &tab=LVHL60 %then put "FIELDS=GEO,TIME,AGE,ISCED97,UNIT";
	
		%else %if &tab=PEES01 %then put "FIELDS=GEO,TIME,AGE,SEX,INDIC_IL,UNIT";
		%else %if &tab=PEES02 %then put "FIELDS=GEO,TIME,WSTATUS,INDIC_IL";
		%else %if &tab=PEES03 %then put "FIELDS=GEO,TIME,QUANTILE,INDIC_IL";
		%else %if &tab=PEES04 %then put "FIELDS=GEO,TIME,HHTYP,INDIC_IL";
		%else %if &tab=PEES05 %then put "FIELDS=GEO,TIME,ISCED97,INDIC_IL";
		%else %if &tab=PEES06 %then put "FIELDS=GEO,TIME,CITIZEN,INDIC_IL";
		%else %if &tab=PEES07 %then put "FIELDS=GEO,TIME,C_BIRTH,INDIC_IL";
		%else %if &tab=PEES08 %then put "FIELDS=GEO,TIME,TENURE,INDIC_IL,UNIT";

		%else %if &tab=mdho05  %then put "FIELDS=GEO,TIME,SEX,AGE,INCGRP,HHTYP,UNIT";
		%else %if &tab=mdho06a %then put "FIELDS=GEO,TIME,SEX,AGE,INCGRP,UNIT";
		%else %if &tab=mdho06b %then put "FIELDS=GEO,TIME,HHTYP,UNIT";
		%else %if &tab=mdho06c %then put "FIELDS=GEO,TIME,TENURE,UNIT";
		%else %if &tab=mdho06d %then put "FIELDS=GEO,TIME,DEG_URB,UNIT";
		%else %if &tab=mdho06q %then put "FIELDS=GEO,TIME,QUANTILE,UNIT";
		%else %if &tab=lvho08a %then put "FIELDS=GEO,TIME,SEX,AGE,INCGRP,UNIT";
		%else %if &tab=lvho08b %then put "FIELDS=GEO,TIME,DEG_URB,UNIT";
		%else %if &tab=lvho07a %then put "FIELDS=GEO,TIME,SEX,AGE,INCGRP,UNIT";
		%else %if &tab=lvho07b %then put "FIELDS=GEO,TIME,QUANTILE,UNIT";
		%else %if &tab=lvho07c %then put "FIELDS=GEO,TIME,TENURE,UNIT";
		%else %if &tab=lvho07d %then put "FIELDS=GEO,TIME,DEG_URB,UNIT";
		%else %if &tab=lvho07e %then put "FIELDS=GEO,TIME,HHTYP,UNIT";
		%else %if &tab=lvho05a %then put "FIELDS=GEO,TIME,SEX,AGE,INCGRP,UNIT";
		%else %if &tab=lvho06  %then put "FIELDS=GEO,TIME,SEX,AGE,INCGRP,UNIT";
		%else %if &tab=lvho06q %then put "FIELDS=GEO,TIME,QUANTILE,UNIT";
		%else %if &tab=lvho05b %then put "FIELDS=GEO,TIME,HHTYP,UNIT";
		%else %if &tab=lvho05c %then put "FIELDS=GEO,TIME,TENURE,UNIT";
		%else %if &tab=lvho05d %then put "FIELDS=GEO,TIME,DEG_URB,UNIT";
		%else %if &tab=lvho05q %then put "FIELDS=GEO,TIME,QUANTILE,UNIT";
		%else %if &tab=lvho15  %then put "FIELDS=GEO,TIME,SEX,AGE,citizen,UNIT";
		%else %if &tab=lvho16  %then put "FIELDS=GEO,TIME,SEX,AGE,c_birth,UNIT";
		%else %if &tab=lvho25 %then put "FIELDS=GEO,TIME,SEX,AGE,citizen,UNIT";
		%else %if &tab=lvho26 %then put "FIELDS=GEO,TIME,SEX,AGE,c_birth,UNIT";

		%else %if &tab=lvho27 %then put "FIELDS=GEO,TIME,SEX,INDIC_IL,UNIT";
		%else %if &tab=lvho28 %then put "FIELDS=GEO,TIME,TENURE,INDIC_IL,UNIT";
		%else %if &tab=lvho29 %then put "FIELDS=GEO,TIME,DEG_URB,INDIC_IL,UNIT";
		%else %if &tab=lvho30 %then put "FIELDS=GEO,TIME,HHTYP,INDIC_IL,UNIT";

        %else %if &tab=lvho50a %then put "FIELDS=GEO,TIME,AGE,SEX,INCGRP,UNIT";	
		%else %if &tab=lvho50b %then put "FIELDS=GEO,TIME,QUANTILE,HHTYP,UNIT";		
		%else %if &tab=lvho50c %then put "FIELDS=GEO,TIME,TENURE,UNIT";	
		%else %if &tab=lvho50d %then put "FIELDS=GEO,TIME,DEG_URB,UNIT";
		/* close the %if ... %else %if loop here, using a ; symbol */
		;	

		/* mode of update can be modified here: */

		put "UPDATE_MODE=RECORDS";
	end;

	if (geo in ("EU15", "EU25", "EU27", "EA", "EA12", "EA13", "EA15", "NMS10", "EA16") and time < 2005) 
	or (geo in (  "RO") and time < 2007) 
	or (geo in (  "BG") and time < 2006) 
	
	then do; x="no put"; end;
	else do;
	
		if ivalue=. then ivalue=0;
		if unit in ("THS_PER", "THS_CD08") or indic_il in ("TC", "MEI_E", "MED_E") then do;
					if unrel = 0 then refval = put(ivalue,12.)||iflag;
					else if unrel = 1 then refval = compress(put(ivalue,12.)!!iflag!!"u"); 
					else if unrel = 2 then refval = ":u";
					else if unrel = 3 then refval = compress(put(ivalue,12.)||iflag||"e"); 
		end;
		else do;

		if unrel = 0 then refval = put(ivalue,&rd)||iflag;
		else if unrel = 1 then refval = compress(put(ivalue,&rd)!!iflag!!"u"); 
		else if unrel = 2 then refval = ":u";
		else if unrel = 3 then refval = compress(put(ivalue,&rd)||iflag||"e"); 
		end;
		/*  s-flag replaced by e-flag on 5th Feb 2013   */

/* special conditions: 
		if geo in ('EU27' , 'NMS12') then refval = ":";*/
		*if &tab in ('OV9B1', 'LI22', 'PEPS01' , 'PEPS02', 'PEPS03', 'PEPS04', 'PEPS05', 'PEPS06', 'PEES01', 'PEES02', 'PEES03', 'PEES04', 'PEES05', 'PEES06', 'PEES07', 'PEES11', 'MDDD11', 'MDDD12', 'MDDD13', 'MDDD14', 'MDDD15', 'MDDD16', 'MDDD21', 'LVHL11', 'LVHL12', 'LVHL13', 'LVHL14', 'LVHL15', 'LVHL16', 'LVHL21', 'LI31', 'LI32') and geo in ('EU25' , 'NMS10') and time < 2005 then refval = ":";

/* for aggregates where currency is PPS or NAC, replace refval with ':' */

		/*if currency in('PPS','NAC')
				and
				geo in ('EU27','EU15','EA12','EA13','EA15','EA16','EA17','EA','NMS10','NMS12') 
				then refval = ":";*/


		%if &tab=LI01 %then put GEO TIME INDIC_IL HHTYP CURRENCY refval; 
		%else %if &tab=DI01 %then put GEO TIME INDIC_IL CURRENCY QUANTILE refval; 
		%else %if &tab=LI02 or &tab=OT01 %then put GEO TIME AGE SEX INDIC_IL UNIT refval;
		%else %if &tab=DI02 %then put GEO TIME INCGRP INDIC_IL CURRENCY refval;
		%else %if &tab=DI03 %then put GEO TIME AGE SEX INDIC_IL UNIT refval;
		%else %if &tab=LI03 or &tab=OT03 %then put GEO TIME HHTYP INDIC_IL refval;
		%else %if &tab=DI04 %then put GEO TIME HHTYP INDIC_IL UNIT refval;
		%else %if &tab=LI04 or &tab=OT02 %then put GEO TIME AGE SEX WSTATUS INDIC_IL refval;
		%else %if &tab=DI05 %then put GEO TIME AGE SEX WSTATUS INDIC_IL UNIT refval;
		%else %if &tab=LI06 or &tab=OT05 %then put GEO TIME AGE SEX HHTYP WORKINT INDIC_IL refval;
		%else %if &tab=DI07 %then put GEO TIME AGE SEX HHTYP WORKINT INDIC_IL UNIT refval;
		%else %if &tab=LI07 or &tab=OT06 %then put GEO TIME AGE SEX ISCED97 INDIC_IL refval;
		%else %if &tab=DI08 %then put GEO TIME AGE SEX ISCED97 INDIC_IL UNIT refval;
		%else %if &tab=LI08 or &tab=OT04 %then put GEO TIME AGE SEX TENURE INDIC_IL refval;
		%else %if &tab=DI09 %then put GEO TIME AGE SEX TENURE INDIC_IL UNIT refval;
		%else %if &tab=DI10 %then put GEO TIME INDIC_IL SUBJNMON CURRENCY refval;
	    %else %if &tab=DI13 %then put GEO TIME AGE SEX INDIC_IL UNIT refval;
		%else %if &tab=DI13b %then put GEO TIME HHTYP INDIC_IL UNIT refval;
		%else %if &tab=DI14 %then put GEO TIME AGE SEX INDIC_IL UNIT refval;
		%else %if &tab=DI14b %then put GEO TIME HHTYP INDIC_IL UNIT refval;
		%else %if &tab=DI15 %then put GEO TIME AGE SEX CITIZEN INDIC_IL UNIT refval;
		%else %if &tab=DI16 %then put GEO TIME AGE SEX C_BIRTH INDIC_IL UNIT refval;
		%else %if &tab=DI17 %then put GEO TIME AGE SEX DEG_URB INDIC_IL UNIT refval;
		%else %if &tab=DI20 %then put GEO TIME AGE SEX INDIC_IL UNIT refval;
		%else %if &tab=DI23 %then put GEO TIME DEG_URB INDIC_IL UNIT refval;
		%else %if &tab=DI27 %then put GEO TIME ISCED97 INDIC_IL UNIT refval;
		
		%else %if &tab=LI09 %then put GEO TIME AGE SEX INDIC_IL refval;
		%else %if &tab=LI09b %then put GEO TIME HHTYP UNIT refval;
		%else %if &tab=LI10 %then put GEO TIME AGE SEX INDIC_IL refval;
		%else %if &tab=LI10b %then put GEO TIME HHTYP UNIT refval;
		%else %if &tab=LI11 %then put GEO TIME AGE SEX INDIC_IL refval;
		%else %if &tab=LI22 %then put GEO TIME AGE SEX "LI_R_MD60 " refval;
		%else %if &tab=LI22b %then put GEO TIME AGE SEX INDIC_IL UNIT refval;
		%else %if &tab=LI31 %then put GEO TIME AGE SEX CITIZEN refval;
		%else %if &tab=LI32 %then put GEO TIME AGE SEX C_BIRTH refval;
		%else %if &tab=LI60 %then put GEO TIME AGE ISCED97 UNIT refval;

		%else %if &tab=LI41  %then put GEO TIME UNIT refval;
		%else %if &tab=LI45  %then put GEO TIME AGE SEX refval;
		%else %if &tab=LI48  %then put GEO TIME DEG_URB refval;
		%else %if &tab=DI11 %then put GEO TIME AGE SEX INDIC_IL refval;
		%else %if &tab=DI12 %then put GEO TIME INDIC_IL refval;
		%else %if &tab=DI12b %then put GEO TIME INDIC_IL refval;
		%else %if &tab=DI12c %then put GEO TIME INDIC_IL refval;
		%else %if &tab=IW01 %then put GEO TIME AGE SEX WSTATUS refval;
		%else %if &tab=IW02 %then put GEO TIME HHTYP refval;
		%else %if &tab=IW03 %then put GEO TIME HHTYP WORKINT refval;
		%else %if &tab=IW04 %then put GEO TIME ISCED97 refval;
		%else %if &tab=IW05 %then put GEO TIME WSTATUS SEX refval;
		%else %if &tab=IW06 %then put GEO TIME DURATION refval;
		%else %if &tab=IW07 %then put GEO TIME WORKTIME refval;
		%else %if &tab=IW15 %then put GEO TIME AGE SEX CITIZEN UNIT refval;
		%else %if &tab=IW16 %then put GEO TIME AGE SEX C_BIRTH UNIT refval;

		%else %if &tab=PNP2 %then put GEO TIME SEX INDIC_IL refval;
		%else %if &tab=PNP3 %then put GEO TIME SEX INDIC_IL refval;
		%else %if &tab=PNS2 %then put GEO TIME SEX INDIC_IL refval;
		%else %if &tab=PNP9 %then put GEO TIME AGE SEX HHTYP "LI_R_MD60 " refval;
		%else %if &tab=PNP10 %then put GEO TIME INDIC_IL SEX HHTYP refval;
		%else %if &tab=PNP11 %then put GEO TIME SEX INDIC_IL refval;
		%else %if &tab=PNS11 %then put GEO TIME INDIC_IL SEX HHTYP refval;
		%else %if &tab=OV9b1 %then put GEO TIME AGE SEX UNIT N_ITEM refval;
		%else %if &tab=OV9b2 %then put GEO TIME AGE SEX UNIT refval;

		%else %if &tab=PEPS01 %then put GEO TIME AGE SEX UNIT refval;
		%else %if &tab=PEPS02 %then put GEO TIME AGE SEX WSTATUS refval;
		%else %if &tab=PEPS03 %then put GEO TIME QUANTILE HHTYP refval;
		%else %if &tab=PEPS04 %then put GEO TIME AGE SEX ISCED97 refval;
		%else %if &tab=PEPS05 %then put GEO TIME AGE SEX CITIZEN refval;
		%else %if &tab=PEPS06 %then put GEO TIME AGE SEX C_BIRTH refval;
		%else %if &tab=PEPS07 %then put GEO TIME TENURE UNIT refval;
		%else %if &tab=PEPS11 %then put GEO TIME UNIT refval;
		%else %if &tab=PEPS60 %then put GEO TIME AGE ISCED97 UNIT refval;

		%else %if &tab=MDDD11 %then put GEO TIME AGE SEX UNIT refval;
		%else %if &tab=MDDD12 %then put GEO TIME AGE SEX WSTATUS refval;
		%else %if &tab=MDDD13 %then put GEO TIME QUANTILE HHTYP refval;
		%else %if &tab=MDDD14 %then put GEO TIME AGE SEX ISCED97 refval;
		%else %if &tab=MDDD15 %then put GEO TIME AGE SEX CITIZEN refval;
		%else %if &tab=MDDD16 %then put GEO TIME AGE SEX C_BIRTH refval;
		%else %if &tab=MDDD17 %then put GEO TIME TENURE UNIT refval;
		%else %if &tab=MDDD21 %then put GEO TIME UNIT refval;
		%else %if &tab=MDDD60 %then put GEO TIME AGE ISCED97 UNIT refval;

		%else %if &tab=LVHL11 %then put GEO TIME AGE SEX UNIT refval;
		%else %if &tab=LVHL12 %then put GEO TIME AGE SEX WSTATUS refval;
		%else %if &tab=LVHL13 %then put GEO TIME QUANTILE HHTYP refval;
		%else %if &tab=LVHL14 %then put GEO TIME AGE SEX ISCED97 refval;
		%else %if &tab=LVHL15 %then put GEO TIME AGE SEX CITIZEN refval;
		%else %if &tab=LVHL16 %then put GEO TIME AGE SEX C_BIRTH refval;
		%else %if &tab=LVHL17 %then put GEO TIME TENURE UNIT refval;
		%else %if &tab=LVHL21  %then put GEO TIME UNIT refval;
		%else %if &tab=LVHL60 %then put GEO TIME AGE ISCED97 UNIT refval;

		%else %if &tab=PEES01 %then put GEO TIME AGE SEX INDIC_IL UNIT refval;
		%else %if &tab=PEES02 %then put GEO TIME WSTATUS INDIC_IL refval;
		%else %if &tab=PEES03 %then put GEO TIME QUANTILE INDIC_IL refval;
		%else %if &tab=PEES04 %then put GEO TIME HHTYP INDIC_IL refval;
		%else %if &tab=PEES05 %then put GEO TIME ISCED97 INDIC_IL refval;
		%else %if &tab=PEES06 %then put GEO TIME CITIZEN INDIC_IL refval;
		%else %if &tab=PEES07 %then put GEO TIME C_BIRTH INDIC_IL refval;
		%else %if &tab=PEES08 %then put GEO TIME TENURE INDIC_IL UNIT refval;

		%else %if &tab=mdho05	%then put GEO TIME SEX AGE INCGRP HHTYP UNIT refval;
		%else %if &tab=mdho06a %then put GEO TIME SEX AGE INCGRP UNIT refval;
		%else %if &tab=mdho06b %then put GEO TIME HHTYP UNIT refval;
		%else %if &tab=mdho06c %then put GEO TIME TENURE UNIT refval;
		%else %if &tab=mdho06d %then put GEO TIME DEG_URB UNIT refval;
		%else %if &tab=mdho06q %then put GEO TIME QUANTILE UNIT refval;
		%else %if &tab=lvho08a %then put GEO TIME SEX AGE INCGRP UNIT refval;
		%else %if &tab=lvho08b %then put GEO TIME DEG_URB UNIT refval;
		%else %if &tab=lvho07a %then put GEO TIME SEX AGE INCGRP UNIT refval;
		%else %if &tab=lvho07b %then put GEO TIME QUANTILE UNIT refval;
		%else %if &tab=lvho07c %then put GEO TIME TENURE UNIT refval;
		%else %if &tab=lvho07d %then put GEO TIME DEG_URB UNIT refval;
		%else %if &tab=lvho07e %then put GEO TIME HHTYP UNIT refval;
		%else %if &tab=lvho05a %then put GEO TIME SEX AGE INCGRP UNIT refval;
		%else %if &tab=lvho06 %then put GEO TIME SEX AGE INCGRP UNIT refval;
		%else %if &tab=lvho06q %then put GEO TIME QUANTILE UNIT refval;
		%else %if &tab=lvho05b %then put GEO TIME HHTYP UNIT refval;
		%else %if &tab=lvho05c %then put GEO TIME TENURE UNIT refval;
		%else %if &tab=lvho05d %then put GEO TIME DEG_URB UNIT refval;
		%else %if &tab=lvho05q %then put GEO TIME QUANTILE UNIT refval;
		%else %if &tab=lvho15 %then put GEO TIME SEX AGE CITIZEN UNIT refval;
		%else %if &tab=lvho16 %then put GEO TIME SEX AGE C_BIRTH UNIT refval;
		%else %if &tab=lvho25 %then put GEO TIME SEX AGE CITIZEN UNIT refval;
		%else %if &tab=lvho26 %then put GEO TIME SEX AGE C_BIRTH UNIT refval;

		%else %if &tab=lvho27 %then put GEO TIME SEX INDIC_IL UNIT refval;
		%else %if &tab=lvho28 %then put GEO TIME TENURE INDIC_IL UNIT refval;
		%else %if &tab=lvho29 %then put GEO TIME DEG_URB INDIC_IL UNIT refval;
		%else %if &tab=lvho30 %then put GEO TIME HHTYP INDIC_IL UNIT refval;

		%else %if &tab=lvho50a %then put GEO TIME AGE SEX INCGRP UNIT refval;	
		%else %if &tab=lvho50b %then put GEO TIME QUANTILE HHTYP UNIT refval;		
		%else %if &tab=lvho50c %then put GEO TIME TENURE UNIT refval;	
		%else %if &tab=lvho50d %then put GEO TIME DEG_URB UNIT refval;
		/* close the %if ... %else %if loop here, using a ; symbol */
		;	 

	end; 

	if last then put "END_OF_FLAT_FILE";
	RUN;

/* send email */
	%if "&action" = "send to reference" %then %do; 
		/*filename ncupdate email 'reference@mail.eurostat.ec.europa.eu' FROM='Boyan.Genev@ec.europa.eu' attach=("&eusilc/&idbrdb/newcronos/&nc..txt");
		DATA _null_;
		file ncupdate;
		RUN;
	%end;*/
	%UPLOAD_TO_EUROBASE(filename=&eusilc/&idbrdb/newcronos/&nc..txt,action=send, target=production);
	%end;

	%if "&action" = "send to test" %then %do; 
		/*filename ncupdate email 'test-refer@mail.eurostat.ec.europa.eu' FROM='Boyan.Genev@ec.europa.eu' attach=("&eusilc/&idbrdb/newcronos/&nc..txt");
		DATA _null_;
		file ncupdate;
		RUN;
	%end;*/
	%UPLOAD_TO_EUROBASE(filename=&eusilc/&idbrdb/newcronos/&nc..txt,action=send, target=staging);
	%end;

/**/
	*log;
	filename logfile "&eusilc/&idbrdb/log/log.csv" ;
	DATA _null_ test;
	file logfile DSD MOD;
	d = put("&sysdate"d,ddmmyys10.);
	u = "&sysuserid";
	/*i ="&action";*/
	t = "&tab";
	y=translate("&yyyy","-  ",",()");
	c=translate("%bquote(&cntr)",'  ', '",');
	c=tranwrd(c,"   "," ");

	 %if ("&action" = "send to reference") %then 
	    put d u /*i */t y c;
	
    RUN;
      %if ("&action" = "send to reference") %then    
 /* %if ("&action" = "create files") %then   */  
	%do;
		data _null_;
			set test;
			call symput('NameC',c);
		run;
		data _null_;
			set test;
			call symput('NameY',y);
		run;
		%let chart=%str(;);
		%let cc=&nameC&chart;
		%country_year_split(&cc,&NameY );
	%end;
PROC DATASETS lib=work  nolist;
	delete TEST  ;
QUIT;
%mend EXP_FData;