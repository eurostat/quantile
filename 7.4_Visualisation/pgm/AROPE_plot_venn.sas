/** 
## AROPE_plot_venn {#sas_AROPE_plot_venn}
Create a 3-way (non-proportional) Venn diagram of _AROPE_ and its components. 

	%AROPE_plot_venn(year, geo=, ind=, idir=, ilib=, ofn=, odir=, unit=, title=, 
					age=, sex=, wstatus=, quantile=, hhtyp=, isced11=, citizen=, c_birth=, tenure=);

### Arguments
* `year` : a (single) year of interest;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=EU28`;
* `unit` : (_option_) choice of representation: either shares of population (`PC_POP`)
	or absolute figures (`THS_PER`); default: `unit=PC_POP`;
* `ind` : (_option_) indicator to consider for representation in Venn diagram; it can be any
	choices  among: `PEES01, PEES02, PEES03, PEES04, PEES05, PEES06, PEES07, PEES08`; when none
	of the indicator breakdwons is selected, all are represented (_i.e._, one Venn diagram is
	displayed for each breakdown);
* `age, sex, wstatus, quantile, hhtyp, isced11, citizen, c_birth, tenure` : variables whose
	breakdowns are considered for representation in the Venn diagram; those can be: 
		+ `age` in 	 	`TOTAL, Y18-49, Y18-64, Y50-64, Y_GE18, Y_GE65, Y_LT18`,
		+ `wstatus`	in 	`EMP, INAC_OTH, NEMP, POP, RET, SAL, NSAL, UNE`,
		+ `quantile` in `TOTAL, QU1, QU2, QU3, QU4, QU5`,
		+ `hhtyp` in 	`A1, A1F, A1M, A1DCH, A_GE2_NDCH, HH_DCH, HH_NDCH`, 
		+ `isced11` in 	`ED0-2, ED3_4, ED5-8`,
		+ `citizen` in 	`NAT, EU27_FOR, NEU27_FOR, FOR, EU28_FOR, NEU28_FOR`,
		+ `c_birth` in 	`NAT, EU27_FOR, NEU27_FOR, FOR, EU28_FOR, NEU28_FOR`,
		+ `tenure` in 	`RENT, OWN`;	

	the breakdowns are incompatible with each other (except `age` and `sex`) since they are 
	implemented in different indicators; when passing any variable among those, the indicator
	to be represented (see `ind` above) is also automatically set;
* `title` : (_option_) title of the graph; default: set automatically; 
* `idir` : (_option_) name of the input directory where to look for _AROPE_ indicators passed 
	instead of `ilib`; incompatible with `ilib`; by default, it is not used; 
* `ilib` : (_option_) name of the input library where to look for _AROPE_ indicators (see 
	note below); incompatible with `idir`; by default, `ilib` will be set to the value 
	`G_PING_LIBCRDB` (_e.g._, library associated to the path `G_PING_C_RDB`); 
* `ofn, odir` : (_option_) output arguments to be passed to macro [%diagram_venn](@ref sas_diagram_venn).
	
### Example
In order to generate the Venn diagram of _AROPE_ population (in `PC_POP`) like the one below,
where shares are represented for "at risk of poverty" population (`ARP`), "severely materially 
deprived" population (`DEP`), and population with "low work intensity" (`LWI`): 

<img src="../../dox/img/AROPE_plot_venn.png" border="1" width="50%" alt="AROPE Venn diagram">

you can simply launch:

	%AROPE_plot_venn(2015, geo=FR, age=TOTAL, sex=T, unit=PC, title=%bquote(AROPE 2015 FR - All ages, all sexes));

### Note
Launching the example below is (in short) equivalent to running the following instructions/procedures: 

	libname rdb "&G_PING_C_RDB";
	%ds_select(	PEES01, 
				dsn, 
				var=	geo time indic_il ivalue iflag, 
				where=	%str(age="TOTAL" AND sex="T" AND unit="PC_POP" AND time=2015 AND geo=FR), 
				ilib=	rdb,
				olib=	WORK);
	DATA dsn;
		SET dsn;
		IF find(indic_il,"NR") THEN 	ARP=0; ELSE 	ARP=1;
		IF find(indic_il,"NDEP") THEN 	DEP=0; ELSE 	DEP=1; 
		IF find(indic_il,"NLOW") THEN 	LWI=0; ELSE 	LWI=1; 
		ivalue = ivalue/100.;
	run;

	%diagram_venn(dsn, 
				  var=	ARP DEP LWI, 
				  valpct=	ivalue, 
				  label=	("ARP","DEP","LWI"),
				  hover=	("R_NDEP_NLOW","NR_DEP_NLOW","NR_NDEP_LOW","R_NDEP_LOW","R_DEP_NLOW","R_DEP_LOW","NR_DEP_LOW"),
				  title="AROPE Venn diagram",
				  format= percent8.1);

### See also
[%diagram_venn](@ref sas_diagram_venn), [%AROPE_press_infographics](@ref sas_AROPE_press_infographics).
*/ /** \cond */


%macro AROPE_plot_venn(year		/* Year of interest 			(REQ) */
						, geo=		/* Area of interest 			(OPT) */
						, ind=
						, idir=		/* Input directory name			(OPT) */
						, ilib=		/* Input library name 			(OPT) */
						, ofn=		/* Output file name 			(OPT) */
						, odir=		/* Output library name 			(OPT) */
						, unit=
						, title=
						/* option */
						, age=
						, sex=
						, wstatus=
						, quantile=
						, hhtyp=
						, isced11=
						, citizen=
						, c_birth=
						, tenure=
						);
	/* for ad-hoc works, load PING library if it is not yet the case */
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local var
		nind
		ans 
		ctry
		IND_AROPE
		UNIT_AROPE
		LABEL_AROPE
		LABEL_AGE		
		LABEL_SEX		
		LABEL_WSTATUS	
		LABEL_QUANTILE	
		LABEL_HHTYP	
		LABEL_ISCED11	
		LABEL_CITIZEN	
		LABEL_C_BIRTH	
		LABEL_TENURE;
	%let IND_AROPE=PEES01 PEES02 PEES03 PEES04 PEES05 PEES06 PEES07 PEES08;
	%let UNIT_AROPE=PC_POP THS_PER;
	%let LABEL_AROPE=		R_NDEP_NLOW NR_DEP_NLOW NR_NDEP_LOW R_NDEP_LOW R_DEP_NLOW R_DEP_LOW NR_DEP_LOW;
	/* note: the following should be retrieved from a configuration file!!! */
	%let LABEL_AGE=			TOTAL Y18-49 Y18-64 Y50-64 Y_GE18 Y_GE65 Y_LT18;
	%let LABEL_SEX=			T M F;
	%let LABEL_WSTATUS=		EMP INAC_OTH NEMP POP RET SAL NSAL UNE;
	%let LABEL_QUANTILE=	TOTAL QU1 QU2 QU3 QU4 QU5;
	%let LABEL_HHTYP=		A1 A1F A1M A1DCH A_GE2_NDCH HH_DCH HH_NDCH;	
	%let LABEL_ISCED11=		ED0-2 ED3_4 ED5-8;
	%let LABEL_CITIZEN=		NAT EU27_FOR NEU27_FOR FOR EU28_FOR NEU28_FOR;
	%let LABEL_C_BIRTH=		NAT EU27_FOR NEU27_FOR FOR EU28_FOR NEU28_FOR;
	%let LABEL_TENURE=		RENT OWN;

	%local _isind
		_isage
		_issex
		_iswstatus
		_isquantile
		_ishhtyp
		_isisced11
		_iscitizen
		_isc_birth
		_istenure;
	%let _isind=		%macro_isblank(ind);
	%let _isage=		%macro_isblank(age);
	%let _issex=		%macro_isblank(sex);
	%let _iswstatus=	%macro_isblank(wstatus);
	%let _isquantile=	%macro_isblank(quantile);
	%let _ishhtyp=		%macro_isblank(hhtyp);
	%let _isisced11=	%macro_isblank(isced11);
	%let _iscitizen=	%macro_isblank(citizen);
	%let _isc_birth=	%macro_isblank(c_birth);
	%let _istenure=		%macro_isblank(tenure);
%put 1);
%put %eval(&_isage+&_issex+&_isquantile+&_iswstatus+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure);

	/* IND: check/set */
	%if %error_handle(ErrorInputParameter, 
			&_isind EQ 1 
			and %eval(&_isage+&_issex+&_isquantile+&_iswstatus+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) EQ 9, mac=&_mac,		
			txt=%quote(! No parameter passed: default PEES01 TOTAL will be displayed !),
			verb=warn) %then %do;
		/* default display */
		%let ind=PEES01;
		%let age=TOTAL;
		%let sex=T;
	%end;
	%else %if &_isind EQ 0 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(%upcase(&ind), type=CHAR, set=&IND_AROPE) NE 0, mac=&_mac,		
				txt=%quote(!!! Wrong type/value for input IND: must be in &IND_AROPE !!!)) %then
			%goto exit;
		%else %if %error_handle(ErrorInputParameter, 
				(&ind=PEES01 and %eval(&_iswstatus+&_isquantile+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) LT 7)
				or (&ind=PEES02 and %eval(&_isage+&_issex+&_isquantile+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) LT 8)
				or (&ind=PEES03 and %eval(&_isage+&_issex+&_iswstatus+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) LT 8)
				or (&ind=PEES04 and %eval(&_isage+&_issex+&_isquantile+&_iswstatus+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) LT 8)
				or (&ind=PEES05 and %eval(&_isage+&_issex+&_isquantile+&_ishhtyp+&_iswstatus+&_iscitizen+&_isc_birth+&_istenure) LT 8)
				or (&ind=PEES06 and %eval(&_isage+&_issex+&_isquantile+&_ishhtyp+&_isisced11+&_iswstatus+&_isc_birth+&_istenure) LT 8)
				or (&ind=PEES07 and %eval(&_isage+&_issex+&_isquantile+&_ishhtyp+&_isisced11+&_iscitizen+&_iswstatus+&_istenure) LT 8)
				or (&ind=PEES08 and %eval(&_isage+&_issex+&_isquantile+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_iswstatus) LT 8), mac=&_mac,
				txt=%quote(!!! Incompatible indicator %upcase(&ind) with options passed !!!)) %then
			%goto exit;
		%if %error_handle(ErrorInputParameter, 
				%eval(&_isage+&_issex+&_isquantile+&_iswstatus+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) EQ 9, mac=&_mac,		
				txt=%quote(! No breakdown variable passed: all breakdowns will be considered !),
				verb=warn) %then %do;
			%if &ind=PEES01 %then %do;
				%let age=&LABEL_AGE;
				%let sex=&LABEL_SEX;
			%end;
			%else %if &ind=PEES02 %then 	%let wstatus=&LABEL_WSTATUS;
			%else %if &ind=PEES03 %then 	%let quantile=&LABEL_QUANTILE;
			%else %if &ind=PEES04 %then 	%let hhtyp=&LABEL_HHTYP;
			%else %if &ind=PEES05 %then 	%let isced11=&LABEL_ISCED11;
			%else %if &ind=PEES06 %then 	%let citizen=&LABEL_CITIZEN;
			%else %if &ind=PEES07 %then 	%let c_birth=&LABEL_C_BIRTH;
			%else %if &ind=PEES08 %then 	%let tenure=&LABEL_TENURE;
		%end;
	%end;
	%else %if %eval(&_isage+&_issex+&_iswstatus+&_isquantile+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) LT 9 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%eval(&_iswstatus+&_isquantile+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) LT 6
				or %eval(&_isage+&_iswstatus+&_isquantile+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) LT 7
				or %eval(&_issex+&_iswstatus+&_isquantile+&_ishhtyp+&_isisced11+&_iscitizen+&_isc_birth+&_istenure) LT 7, mac=&_mac,
						txt=%quote(!!! Incompatible options passed !!!)) %then
			%goto exit;
		%if &_isage EQ 0 or &_issex EQ 0 %then %do;
			%let ind=PEES01;
			%if &_isage EQ 1 %then 			%let age=TOTAL/*&LABEL_AGE*/;
			%if &_issex EQ 1 %then 			%let sex=T/*&LABEL_SEX*/;
		%end;
		%else %if &_iswstatus EQ 0 %then 	%let ind=PEES02;
		%else %if &_isquantile EQ 0 %then  	%let ind=PEES03;
		%else %if &_ishhtyp EQ 0  %then 	%let ind=PEES04;
		%else %if &_isisced11 EQ 0  %then 	%let ind=PEES05;
		%else %if &_iscitizen EQ 0  %then 	%let ind=PEES06;
		%else %if &_isc_birth EQ 0  %then 	%let ind=PEES07;
		%else %if &_istenure EQ 0  %then 	%let ind=PEES08;
	%end;
%put 2);
	
	/* once IND is set we can define the concerned breakdowns */
	%if &ind=PEES01 %then 			%let var=age sex;
	%else %if &ind=PEES02 %then 	%let var=wstatus;
	%else %if &ind=PEES03 %then 	%let var=quantile;
	%else %if &ind=PEES04 %then 	%let var=hhtyp;
	%else %if &ind=PEES05 %then 	%let var=isced11;
	%else %if &ind=PEES06 %then 	%let var=citizen ;
	%else %if &ind=PEES07 %then 	%let var=c_birth;
	%else %if &ind=PEES08 %then 	%let var=tenure;

	/* YEAR: check/set */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&year, type=INTEGER, range=2003) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input YEAR !!!)) %then
		%goto exit;

	/* GEO: check/set */
	%if %macro_isblank(geo) %then	%let geo=EU28;
	%else %if %error_handle(ErrorInputParameter, 
			%list_length(&geo) GT 1, mac=&_mac,		
			txt=%quote(!!! Currently only one country can be processed at once !!!)) %then
		%goto exit;
	%str_isgeo(&geo, _ans_=ans, _geo_=geo);
	%if %error_handle(ErrorInputParameter, 
			%list_count(&ans, 0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code !!!)) %then
		%goto exit;
	/* no... %else %if %list_count(&ans, 2) %then %do;
		%zone_replace(&geo, _ctrylst_=ctry);
		%let geo=%list_unique(&ctry &geo);
	%end;*/

	/* UNIT: check/set */
	%if %macro_isblank(unit) %then 			%let unit=PC_POP;
	%else %if %upcase("&unit")="PC" %then 	%let unit=PC_POP;
	%else %if %upcase("&unit")="THS" %then 	%let unit=THS_PER;
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&unit), type=CHAR, set=&UNIT_AROPE) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input UNIT: must be in &UNIT_AROPE !!!)) %then
		%goto exit;

	/* IDIR/ILIB: check/set default input library */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(idir) EQ 0 and %macro_isblank(ilib) EQ 0, mac=&_mac,
			txt=%quote(!!! Incompatible parameters IDIR and ILIB: set one only !!!)) %then
		%goto exit;
	%else %if not %macro_isblank(idir) %then %do;
		%let islibtemp=1;
		libname lib "&idir"; 
		%let ilib=lib;
	%end;
	%else %if %macro_isblank(ilib) %then %do;
		%let islibtemp=0;
		%if %symexist(G_PING_LIBCRDB) %then 		%let ilib=&G_PING_LIBCRDB;
		%else %do;
			libname rdb "/ec/prod/server/sas/0eusilc/IDB_RDB/C_RDB"; /* &G_PING_C_RDB */
			%let ilib=rdb;
		%end;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	%local _i _j
		_ind
		_var1 _var2
		_break1 _break2
		components
		_label
		_hover
		_title
		_where
		_dsn
		DUMMYVAR;
	%let DUMMYVAR=1;

	%let components=ARP DEP LWI;
	%let _label=	(%list_quote(&components)); 	/* ("at risk of poverty", "severely materially deprived", "low work intensity") */
	%let _hover=	(%list_quote(&LABEL_AROPE));	/* note the importance of the order: 1 2 3 12 23 13 123 */
%put &_label;
%put &_hover;
	/* population concerned:
	* 	R_NDEP_NLOW : at risk of poverty but not severely materially deprived and not living in a household with low work intensity 
	* 	NR_DEP_NLOW : not at risk of poverty but severely materially deprived and not living in a household with low work intensity 
	* 	NR_NDEP_LOW : not at risk of poverty, not severely materially deprived but living in a household with low work intensity 
	* 	R_DEP_NLOW 	: at risk of poverty, severely materially deprived but not living in a household with low work intensity 
	* 	NR_DEP_LOW 	: not at risk of poverty but severely materially deprived and living in a household with low work intensity 
	* 	R_NDEP_LOW 	: at risk of poverty, not severely materially deprived but living in a household with low work intensity 
	* 	R_DEP_LOW 	: at risk of poverty, severely materially deprived and living in a household with low work intensity 
	* poulation not represented:
	* 	NR_NDEP_NLOW : neither at risk of poverty, nor severely materially deprived nor living in a household with low work intensity 
	*/

	%let _dsn=TMP&_mac;

	%ds_select(			&ind, 
						&_dsn.1, 
				var=	geo time &var indic_il ivalue iflag, 
				where=	%str(unit 		in 		%sql_list(&unit) 
						 AND time 		in 		%sql_list(&year)
						 AND geo 		in 		%sql_list(&geo)), 
				ilib=	&ilib,
				olib=	WORK);

	%if %error_handle(WarningOutputDataset, 
			%ds_isempty(&_dsn.1) EQ 1, mac=&_mac,
			txt=%quote(!!! No data available for selected variable/dimensions  !!!)) %then
		%goto exit;

	%if %sysfunc(countw(&var)) =1 %then %let var= &var DUMMYVAR;

	%let _var1=%scan(&var, 1);
	%do _i=1 %to %list_length(&&&_var1);		
		%let _break1=%scan(&&&_var1, &_i, %quote( ));
		%let _var2=%scan(&var, 2);
		%do _j=1 %to %list_length(&&&_var2);
			%let _title=&ind: &_var1=&_break1;
			%let _where=&_var1 in %sql_list(&_break1);
			%if &_var2^=DUMMYVAR	%then %do;
				%let _break2=%scan(&&&_var2, &_j, %quote( ));
				%let _where=&_where AND &_var2 in %sql_list(&_break2);
				%let _title=&_title - &_var2=&_break2;
			%end;

			%ds_select(&_dsn.1, &_dsn.2, all=yes, where=%str(&_where));

			%if %error_handle(WarningOutputDataset, 
					%ds_isempty(&_dsn.2) EQ 1, mac=&_mac,
					txt=%quote(! No data available for selected breakdown - Skip !),
					verb=warn) %then
				%goto next;
	
			DATA &_dsn.2(KEEP=geo time arp dep lwi ivalue iflag);
				FORMAT geo time arp dep lwi ivalue iflag;
				SET &_dsn.2;
				IF find(indic_il,"NR") THEN 	arp=0; ELSE 	arp=1;
				IF find(indic_il,"NDEP") THEN 	dep=0; ELSE 	dep=1; 
				IF find(indic_il,"NLOW") THEN 	lwi=0; ELSE 	lwi=1; 
				%if %upcase("&unit")="PC_POP" %then %do;
					ivalue = ivalue/100.;
				%end;
				%else %if %upcase("&unit")="THS_PER" %then %do;
					ivalue = round(ivalue);
				%end;
			run;

			%if not %macro_isblank(title) %then 	%let _title=&title;
			/* print the excerpt table */
			%ds_print(&_dsn.2, title="&_title");

			/* print the Venn diagramm */
			%diagram_venn(&_dsn.2, 
						var=	&components, 
						%if %upcase("&unit")="PC_POP" %then %do;
							valpct=	ivalue, 
							format=percent8.1,
						%end;
						%else %if %upcase("&unit")="THS_PER" %then %do;
							valnum=	ivalue, 
							format=8.0,
						%end;
						label=	&_label,
						hover=	&_hover,
						ofn=&ofn,
						odir=&odir,
						title="&_title",
						ilib=	WORK);

			%next:
			%work_clean(&_dsn.2);
		%end;
	%end;
	%work_clean(&_dsn.1);

	%exit:
%mend AROPE_plot_venn;

/** \endcond */


