/** 
## diagram_venn {#sas_diagram_venn}
Plot 3-way Venn diagrams (using `PROC GMAP`) with values displayed in each set and/or set intersections.

	%diagram_venn(idsn, var=, valpct=, valnum=, valid=, format=, label=, ofn=, odir=, ilib=,
				  hover=, title=, fontSize=4, labelFontSize=4, imgFmt=gif, valColor=white, bgColor=white);;
  
### Arguments
* `idsn` : name of the input dataset containing 3 set indicator variables along with a 4th variable 
	(either a cell count, an id variable or a variable direclty containing the information to be displayed 
	in each set or set intersections); see example below; 	
* `var` : (_option_) lists of set indicator variables, 3 in total; each of these variables is binary, taking 
	value 1 for values in corresponding set, 0 for values outside of the corresponding set;	when not passed,
	the 3 first variables of `idsn` dataset are retrieved (_i.e._, by `varnum` order) assuming they are 
	correctly formatted;
* `valpct` : (_option_) if `idsn` consists of 3 set indicator variables and a variable (which could be a text 
	variable) to be displayed on the plot, specify the corresponding variable name throught the `valpct` 
	argument; this option is incompatible with options `valnum` and `valid` below;
* `valnum` : (_option_) if `idsn` already consists of cell counts to be displayed on the plot, then the 
	variable where these cell counts can be found must be specified through the `valnum` argument; this option 
	is incompatible with options `valpct` above and `valid` below;
* `valid` : (_option_) if `idsn` consists of a series of observations (patients) with an ID variable and 3 
	set indicator variables, then the ID variable should be specified through the `valid` argument; this option 
	is incompatible with options `valpct` and `valnum` above;	
* `format` : (_option_) SAS format in which values printed in each set should be displayed; default is 
	`percent8.1` when `valpct` is set, `8.1` otherwise;
* `ofn` : (_option_) name of the `.html` output file to be saved; an image will also be saved with the 
	same name, with file extension as defined by `imgFmt` (see below); by default, no file is saved;
* `odir` : (_option_) path of the directory where output `.html` file and image (with generic name `ofn`) shall
	be saved; obviously ignored when `ofn` is not passed;
* `title` : (_option_) title to be displayed on top of the plot; default is "Venn Diagram - <idsn>", where 
	<idsn> stands for the name of the input dataset `idsn`;
* `label` : (_option_) labels (3 in total) to be printed next to each set; default is to use each set indicator 
	variable names available through `var`; 
* `hover` : (_option_) formatted list of quoted items which contain text to be displayed when hovering over 
	each set or set intersections with the mouse; the order of display in `hover` is given by the sequence: 
	`1 2 3 12 23 13 123` where the number indicates the order of the variables in `var` which is concerned by 
	the set or set intersection; in particular, `hover` must be of length 7 (number of sets in the Venn diagram); 
	by	default, `hover` is the concatenation of the corresponding set label(s);
* `fontSize` : (_option_) font size for values to be displayed in each set or set intersections; default: 4;
* `labelFontSize` : (_option_) font size for set labels; default: 4;
* `imgFmt` : (_option_)image format; default: `imgFmt=gif`; an alternative is `png`;
* `valColor` : (_option_)color of values displayed in sets; default: `valColor=white`.
* `bgColor` : (_option_)background color; default: `bgColor=white`;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Example
We provide here an example presented in the original code (see note below).

Given the table `Example` in `WORK`ing library:

	DATA Example;
	    input Scholars Students Athletes p;
	cards;
	1 0 0 0.07
	0 1 0 0.23
	0 0 1 0.12
	1 1 0 0.03
	0 1 1 0.08
	1 0 1 0.04
	1 1 1 0.02
	;
	run;

then running:

	%diagram_venn(Example, var=Scholars Students Athletes, valpct=p, format=percent8.1);

will produce the following graphical result:

<img src="../../dox/img/diagram_venn.png" border="1" width="50%" alt="Venn diagram">

Run macro `%%_example_diagram_venn` for examples.

### Notes
1. **The macro `%%diagram_venn` is  a wrapper to L. Joseph's original `%%VennDiagram` macro which
implements a 3-Way non-proportional Venn diagram**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/VennDiagram.html>.
2. This macro creates Venn diagram using SAS/Graph `PROC GMAP` where each segment of the Venn diagram
is a totally separate map area, so the color/drilldown/etc of each piece can be controlled separately.

### References
1. Allison R. [webpage](http://robslink.com/SAS/democd14/aaaindex.htm) on SAS/Graph samples from which
the code is derived.
2. Harris, K. (2008): ["How to generate 2, 3 and 4 way Venn diagrams with drill down functionality within 4 minutes!"](http://www2.sas.com/proceedings/forum2008/073-2008.pdf).
3. Li, S. (2009): ["Customized proportional Venn diagrams from SAS system"](http://www.lexjansen.com/nesug/nesug09/ap/AP11.pdf).
4. Kruger, H. (2011): ["Creating proportional Venn diagrams using Google and SAS"](Creating proportional Venn diagrams using Google and SAS).
5. Harris, K. (2008): ["V is for Venn diagrams"](http://support.sas.com/resources/papers/proceedings13/243-2013.pdf).

### See also
[venn](http://robslink.com/SAS/democd14/venn.sas), [vennmap](http://robslink.com/SAS/democd14/vennmap.sas)
[%VennDiagram](http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/VennDiagram.html),
[PROC GMAP](http://support.sas.com/documentation/cdl/en/graphref/67881/HTML/default/viewer.htm#n01e0bon6tv6ncn1a7dlrr5fh5tr.htm).
*/ /** \cond */

%macro diagram_venn(idsn
				, var=
				, valpct=
				, valnum=
				, valid=
				, format=
				, label=
				, ofn=
				, odir=
				, ilib=
				/* cosmetic settings */
				, title=
				, hover=
				, imgFmt=
				, fontSize=4
				, labelFontSize=4
				, valColor=white
				, bgColor=white
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local AREAIDS
		nAREAIDS
		UNDEF 		/* value to be displayed in empty cells */
		SEP;
	%let SEP=%quote( );
	%let AREAIDS=1 2 3 12 23 13 123; /*1 2 3 12 23 13 123*/
	%let nAREAIDS=%list_length(&AREAIDS);
	%let UNDEF=0;

	/* VALPCT, VALNUM, VALID */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(valpct) EQ 1 and %macro_isblank(valnum) EQ 1 and %macro_isblank(valid) EQ 1, mac=&_mac,		
			txt=%bquote(!!! One at least of the parameters VALPCT, VALNUM or VALID needs to be set !!!)) %then
		%goto exit;

	/* VAR */
	%if %error_handle(WarningInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%bquote(! Parameter VAR not set: components variables will be taken as the first 3 in dataset !),
			verb=warn) %then %do;
		%var_check(&idsn, 1 2 3, _varlst_=var, lib=&ilib);
	%end;

	%if %error_handle(ErrorInputParameter, 
			%list_length(&var, sep=&SEP) NE 3, mac=&_mac,		
			txt=%bquote(!!! Three variable names should be passed in VAR !!!)) %then
		%goto exit;

	/* LABEL */
	%if %error_handle(WarningInputParameter, 
			%macro_isblank(label) EQ 1, mac=&_mac,		
			txt=%bquote(! Parameter LABEL not set: will be set to VAR names !),
			verb=warn) %then%do;
		%let label=(%list_quote(&var, sep=&SEP));
	%end;

	%if %error_handle(ErrorInputParameter, 
			%clist_length(&label) NE 3, mac=&_mac,		
			txt=%bquote(!!! Three labels should be passed in LABEL !!!)) %then
		%goto exit;

    /* IDSN, ILIB: check/set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(idsn) EQ 1, mac=&_mac,		
			txt=!!! Input data parameter IDSN must be specified !!!) %then
		%goto exit;

	%if %macro_isblank(ilib) %then %let ilib=WORK;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,		
			txt=%bquote(!!! Input dataset %upcase(&idsn) not found in library %upcase(&ilib) !!!)) %then
		%goto exit;

    /* OFN, ODIR: check/set */
	%if not %macro_isblank(ofn) %then %do;

		/* ODIR: default setting and checking */
		%if %macro_isblank(odir) %then %do; 
			%if %symexist(_SASSERVERNAME) %then /* working with SAS EG */
				%let odir=&G_PING_ROOTPATH/%_egp_path(path=drive);
			%else %if &sysscp = WIN %then %do; 	/* working on Windows server */
				%let odir=%sysget(SAS_EXECFILEPATH);
				%if not %macro_isblank(odir) %then
					%let odir=%qsubstr(&odir, 1, %length(&odir)-%length(%sysget(SAS_EXECFILENAME));
			%end;
			%if %macro_isblank(odir) %then
				%let odir=%sysfunc(pathname(&ilib));
		%end;
		%if %error_handle(ErrorInputParameter, 
				%dir_check(&odir) NE 0, mac=&_mac,		
				txt=%quote(!!! Output directory %upcase(&odir) does not exist !!!)) %then
			%goto exit;
	
		/* OFN: 
		%if %error_handle(WarningOutputFile, 
				%file_check(&odir./&ofn) EQ 0, mac=&_mac,		
				txt=%quote(! Output file %upcase(&odir./&ofn) already exist - Will be overwritten !), verb=warn) %then
			%goto warning;
		%warning: */
	%end;

	/* FORMAT: check/set */
	%if %macro_isblank(format) %then %do;
	    %if not %macro_isblank(valpct) %then 			%let format=percent8.1;
		%else/* %if not %macro_isblank(valnum) %then */ %let format=8.0;
	%end;

	/* TITLE: check/set */
	%if %macro_isblank(title) %then %do;
		%let title= "&idsn - Venn Diagram";
	%end;

	/* HOVER: check */
	%if not %macro_isblank(hover) %then %do;
		%if %error_handle(ErrorInputParameter, 
				%clist_length(&hover) NE &nAREAIDS, mac=&_mac,		
				txt=%quote(! Wrong parameter HOVER: must be of length &nAREAIDS - Will be ignored !),
				verb=warn) %then
			%let hover=;
	%end;

	/* IMGFMT: check */
	%if not %macro_isblank(imgFmt) %then %do;
		%if %error_handle(WarningInputParameter, 
				%macro_isblank(ofn) EQ 1, mac=&_mac,		
				txt=%quote(! Parameter IMGFMT is ignored when OFN is not set !),
				verb=warn) %then
			%goto skip_imgFmt;
		%else %if %error_handle(ErrorInputParameter, 
				%par_check(%upcase(imgFmt), type=CHAR, set=GIF PNG) EQ 1, mac=&_mac,		
				txt=%quote(! Parameter IMGFMT not recognised: must be GIF or PNG !)) %then
			%goto exit;
		%skip_imgFmt:
	%end;

	/* RADIUS : ignored... */
	%local radius;
	/*%if %macro_isblank(radius) %then %do;*/
	%let radius = 25;
	/*%end;*/

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i _j1 _j2
		_id;

    %local dsCentroids 
		dsColors 
		dsMyData 
		dsMyMap 
		dsOutsideAnno 
		dsSliceAnno 
		dsTmp
		_tmp;

	%do _i=1 %to &nAREAIDS;
        %let _id = %scan(&AREAIDS, &_i, &SEP);
		%local color&_id 	
			value&_id;
	%end;

	/* set lab and var variables */
	%do _i=1 %to 3;
		%local var&_i
			lab&_i;
		%let var&_i=%scan(&var, &_i, &SEP);
		%let lab&_i=%clist_unquote(%clist_index(&label, &_i));
	%end;

    %if not %macro_isblank(valpct) %then %do;
		%let ivalue=&valpct;
		%let _tmp=&ilib..&idsn; /* ugly, but working */
    %end;
    %else %do;
		%put in &_mac: deal with VALNUM!!!!!!;
        %let _tmp = %str_dsname(tmp, prefix=_);
        PROC SQL noprint; 
            CREATE TABLE &_tmp AS
            SELECT &var1, 
				&var2, 
				&var3, 
				%if not %macro_isblank(valnum) %then %do;
					sum(&valnum) as Count
       			%end;
      			%else %if not %macro_isblank(valid) %then %do;
					N(&valid) as Count
        		%end;
      		FROM &ilib..&idsn
            GROUP &var1, &var2, &var3;
        quit;
  		%let ivalue=Count;
    %end;

	PROC SQL noprint; 
		SELECT &ivalue into :value1 	FROM &_tmp 	WHERE &var1 EQ 1 and &var2 EQ 0 and &var3 EQ 0;    
		%if &value1 EQ %then 	%let value1 = &UNDEF;
		SELECT &ivalue into :value2 	FROM &_tmp 	WHERE &var1 EQ 0 and &var2 EQ 1 and &var3 EQ 0;    
    	%if &value2 EQ %then 	%let value2 = &UNDEF;
		SELECT &ivalue into :value3 	FROM &_tmp 	WHERE &var1 EQ 0 and &var2 EQ 0 and &var3 EQ 1;   
    	%if &value3 EQ %then 	%let value3 = &UNDEF;
		SELECT &ivalue into :value12 	FROM &_tmp 	WHERE &var1 EQ 1 and &var2 EQ 1 and &var3 EQ 0;     
    	%if &value12 EQ %then 	%let value12 = &UNDEF;
		SELECT &ivalue into :value13 	FROM &_tmp 	WHERE &var1 EQ 1 and &var2 EQ 0 and &var3 EQ 1;     
    	%if &value13 EQ %then 	%let value13 = &UNDEF;
		SELECT &ivalue into :value23 	FROM &_tmp 	WHERE &var1 EQ 0 and &var2 EQ 1 and &var3 EQ 1;   
    	%if &value23 EQ %then 	%let value23 = &UNDEF;
		SELECT &ivalue into :value123 	FROM &_tmp 	WHERE &var1 EQ 1 and &var2 EQ 1 and &var3 EQ 1;     
    	%if &value123 EQ %then 	%let value123 = &UNDEF;
	quit;

	%if %macro_isblank(valpct) %then %do;
		%work_clean(&_tmp);
	%end;
    
    /* set to original colors */     /* other color definitions */ 
  	 %let color1=cx5A5AE7;  		/*%let color1=cxD974C9;  */     
  	%let color2=cxE75A5A;  		/*%let color2=cx008000; */   	
  	%let color3=cx5AE75A; 		/*%let color3=cxFFD700;  */  	

	/* this isn't true color-blending, but rather taking the average of the rgb hex codes (using this algorithm,
	* if you mix blue & yellow you do not get green like you would in true color mixing)  */
	%macro color_mix(outcolor, incolors, darken=0.9);
	    %local nColors;
	    %local color0 color1 color2;

	    %let nColors = %eval(1 + %length(%sysfunc(compbl(&incolors))) - %length(%sysfunc(compress(&incolors))));
	    %let color0 = %scan(&incolors, 1);
	    %let color1 = %scan(&incolors, 2);

	    /* first get the rgb hex values of the colors to mix*/
	    red0        = input(substr("&color0", 3, 2), hex2.);
	    green0    = input(substr("&color0", 5, 2), hex2.);
	    blue0        = input(substr("&color0", 7, 2), hex2.);

	    red1        = input(substr("&color1", 3, 2), hex2.);
	    green1    = input(substr("&color1", 5, 2), hex2.);
	    blue1        = input(substr("&color1", 7, 2), hex2.);

	    %if &nColors eq 3 %then %do;
	        %let color2 = %scan(&incolors, 3);
	        red2        = input(substr("&color2", 3, 2), hex2.);
	        green2    = input(substr("&color2", 5, 2), hex2.);
	        blue2        = input(substr("&color2", 7, 2), hex2.);
	    %end;
	    %else %do;
	        red2 = .;
	        green2 = .;
	        blue2 = .;
	    %end;

	    /* darken is a factor to 'darken' the combined area colors. values 0->1 (1=no darkening, 0=totally darkened) */
	    Dk        = &darken**(&nColors-1);
	    red    = mean(of red0 red1 red2) * Dk;
	    green    = mean(of green0 green1 green2) * Dk;
	    blue    = mean(of blue0 blue1 blue2) * Dk;

	    &outcolor    = "cx"||put(red,hex2.)||put(green,hex2.)||put(blue,hex2.);
	%mend color_mix;

    /* calculate the 'overlapping' colors */
    %let dsColors=%str_dsname(colors, prefix=_);
    data &dsColors;
		/* specify the 3 colors of the outside circles, and the colors for the overlapping segments are 
		 * calculated to simulate blending */
        %color_mix(color12, &color1 &color2);          /* calculate color for 1&2 intersection */
        %color_mix(color13, &color1 &color3);          /* calculate color for 1&3 intersection */
        %color_mix(color23, &color2 &color3);          /* calculate color for 2&3 intersection */
        %color_mix(color123, &color1 &color2 &color3);	/* calculate color for 1&2&3 intersection */
    run;

    /* store mixed colors codes in macro variables */
	PROC SQL noprint; 
		SELECT color12, color13, color23, color123
		INTO :color12, :color13, :color23, :color123
		FROM &dsColors;
    quit;
  	%work_clean(&dsColors);

  	%if not %macro_isblank(odir) %then %do;
    	/* create the "response" data set */
	    FILENAME odsout "&odir";
	%end;
	goptions reset=global;

    %let dsMyData = %str_dsname(mydata, prefix=_);
    DATA &dsMyData;
        length AreaLabel $200;

		%do _i=1 %to &nAREAIDS;

        	%let _id = %scan(&AREAIDS, &_i, &SEP);
			AreaID=&_id;
        	%if &&value&_id NE %then %do;
            	value = put(&&value&_id, &format);
        	%end;
        	%else %do;
            	value = "";
        	%end;
	        %if not %macro_isblank(hover) %then %do;
            	AreaLabel = %clist_index(&hover, &_i);
	        %end;
        	%else %do;
				%put check for _id=&_id and _i=&_i;
				%if %length(&_id) =1 %then %do;
	            	AreaLabel = "&&lab&_id";
				%end;
				%else %if %length(&_id) =2 %then %do;
					%let _j1=%sysfunc(substr(&_id,1,1));
					%let _j2=%sysfunc(substr(&_id,2,1));
	            	AreaLabel = "&&lab&_j1 & &&lab&_j2";
				%end;
				%else %if %length(&_id) =3 %then %do;
	            	AreaLabel = "&lab1 & &lab2 & &lab3";
				%end;
        	%end;
        	output;
		%end;
    run;

    DATA &dsMyData;
        SET &dsMyData;
        LENGTH htmlvar $500;
        htmlvar='title='||quote(
 						'AREA: '|| strip(AreaLabel) ||'0D'x||
  						'VALUE: '|| strip(value));
    run;

	%macro arc(radius, StartAngle, EndAngle, direction, CenterX, CenterY);
		/* given the the x/y center of a circle, its radius, and the number of degrees angle, 
		* this will calculate the x/y coordinates of the points along the arc along the outside 
		* edge of that segment of the circle */ 
		do degrees = &StartAngle to &EndAngle by &direction;
			radians =degrees * (atan(1)/45);
			x = &CenterX + (&radius * cos(radians));
			y = &CenterY + (&radius * sin(radians));
			output;
		end;
	%mend arc;

    /* create the "map" geometry data set  */
    %let dsMyMap = %str_dsname(mymap, prefix=_);
    DATA &dsMyMap;
		/* note: when creating the sas/graph map data set, the x/y coordinates of the outlines 
		* of each area will be connected in the order in which you specify them in the data set, 
		* so it is needed to specify them in order (clockwise or counterclockwise) */
		radius=25;

        /* area 1 (top-most, area 1 only) */
        AreaID = 1;
        %arc(&radius, 0,  180,  1, 50,        25+10+21.650635);		/* top arc of area 1 */
        %arc(&radius, 120, 60, -1, 50-(50/4), 25+10);    			/* bottom/left arc of area 1 */
        %arc(&radius, 120, 60, -1, 50+(50/4), 25+10);    			/* bottom/right arc of area 1 */    

        /* area 2 (Left-most, area 2 only) */
        AreaID = 2;
        %arc(&radius, 300, 120, -1, 50-(50/4), 25+10);   			/* big/left arc of area 2 */
        %arc(&radius, 180, 240,  1, 50,        25+10+21.650635); 	/* little/right/top arc of area 2 */
        %arc(&radius, 180, 240,  1, 50+(50/4), 25+10);    			/* little/right/bottom arc of area 2 */

        /* area 3 (Right-most, area 3 only) */
        AreaID = 3;
        %arc(&radius,  60, -120, -1, 50+(50/4), 25+10);   			/* big/right arc of area 3 */
        %arc(&radius, -60,    0,  1, 50-(50/4), 25+10);      		/* little/left lower arc of area 3 */
        %arc(&radius, -60,    0,  1, 50,        25+10+21.650635);   /* little/left/top arc of area 3 */

        /* area 1&2 Intersection */
        AreaID = 12;
        %arc(&radius, 180, 240,  1, 50,        25+10+21.650635);	/* lower/left arc */
        %arc(&radius, 180, 120, -1, 50+(50/4), 25+10);   			/* lower/right arc */
        %arc(&radius,  60, 120,  1, 50-(50/4), 25+10);     			/* topmost arc */

        /* area 2&3 Intersection */
        AreaID = 23;
        %arc(&radius, 180, 240,  1, 50+(50/4), 25+10);    			/* lower/left arc */
        %arc(&radius, -60,   0,  1, 50-(50/4), 25+10);      		/* lower/right arc */
        %arc(&radius, 300, 240, -1, 50,        25+10+21.650635);	/* topmost arc */

        /* area 1&3 Intersection */
        AreaID = 13;
        %arc(&radius,  60, 120,  1, 50+(50/4), 25+10);     			/* topmost arc */
        %arc(&radius,  60,   0, -1, 50-(50/4), 25+10);      		/* lower/left arc */
        %arc(&radius, 300, 360,  1, 50,        25+10+21.650635); 	/* lower/right arc */

        /* area 1&2&3 Intersection (center) */
        AreaID = 123;
        %arc(&radius,   0,  60, 1, 50-(50/4), 25+10);        		/* upper/right arc */
        %arc(&radius, 120, 180, 1, 50+(50/4), 25+10);     			/* upper/left arc */
        %arc(&radius, 240, 300, 1, 50,        25+10+21.650635); 	/* lower/bottom arc */
    run;

    %let dsCentroids  = %str_dsname(centroids, prefix=_);
    %let dsTmp        = %str_dsname(tmp, prefix=_);
    /* put the labels on the pieces of the circles */
    PROC SQL;
		/* get the average x/y center coordinates of each piece */
		CREATE TABLE &dsCentroids as
        SELECT unique AreaID, mean(x) as x, mean(y) as y
        FROM &dsMyMap
        GROUP BY AreaID;

        /* merge the centers with the 'response' data */
		CREATE TABLE &dsTmp as
        SELECT unique d.*, c.x, c.y
        FROM &dsMyData as d left join &dsCentroids as c
        ON d.AreaID = c.AreaID;
    quit;
	%work_clean(&dsMyData);
	%ds_rename(&dsTmp, &dsMyData);

    %let dsSliceAnno = %str_dsname(sliceanno, prefix=_);
    PROC SQL;
		CREATE TABLE &dsSliceAnno as
        SELECT *, 
			'2' as xsys,
			'2' as ysys, 
			'3' as hsys, 
			'A' as when, 
			'label' as function length=12, 
			'5' as position, 
			'"albany AMT"' as style length=12, 
			&fontSize as size, 
			"&valColor" as color length=12, 
			strip(value) as text length=20
        FROM &dsMyData;
    quit;

    %let dsOutsideAnno = %str_dsname(outsideanno, prefix=_);
    /* put labels beside (outside) the circles
     * generate a version with labels instead of hatch-marks and 'legend' */
    DATA &dsOutsideAnno;
        LENGTH text $100 style $12 function $12 color $12;
        xsys = '2'; ysys = '2'; hsys = '3'; when = 'A';
        function = 'label'; style = '"albany AMT"'; size = &labelFontSize; color = 'black';
        text = "&lab1"; position='4'; x = 27; y = 73;    output;
        text = "&lab2"; position='4'; x = 13; y = 25;    output;
        text = "&lab3"; position='6'; x = 87; y = 25;    output;
    run;

  	%if not %macro_isblank(ofn) %then %do;
     	ODS LISTING close;
 		ODS HTML path=odsout body="&ofn..html" (title=&title) style=minimal;
    	goptions border;

    	goptions htitle=6pct htext=4pct ftitle="albany AMT" ftext="albany";
    	goptions cback=&bgColor;

	%end;
    	title &title;

    /* use the 'midpoints=' gmap option to guarantee the colors will be assigned in the desired
	* order (otherwise they will be assigned alphabetically by &labeln values */
	%do _i=1 %to &nAREAIDS;
		%let _id = %scan(&AREAIDS, &_i, &SEP);
   		pattern&_i v=s c=&&color&_id;
	%end;

    legend1 position=(bottom) across=3 label=none shape=bar(3,1);
	
	%if not %macro_isblank(ofn) %then %do;
		FILENAME vdiagout "&odir/&ofn";
	    goptions device=&imgFmt gsfname=vdiagout;
	%end;

    PROC GMAP map=&dsMyMap data=&dsMyData anno=&dsOutsideAnno all;
    	ID AreaID;
        CHORO AreaID / nolegend midpoints=&AREAIDS
             coutline=black woutline=2 anno=&dsSliceAnno html=htmlvar des="" name="&ofn";
    run; quit;

  	%if not %macro_isblank(ofn) %then %do;
  		ODS HTML close;
   		FILENAME vdiagout clear;
   		ODS LISTING;
	%end;

    %work_clean(&dsCentroids, &dsMyData, &dsMyMap, &dsOutsideAnno, &dsSliceAnno);

	%exit:
%mend diagram_venn;


%macro _example_diagram_venn;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn out;
	%let dsn=_TMP&sysmacroname;
	%let out=_OUT&sysmacroname;

	%put;
	%put (i) Reproduce the example presented on this page: http://robslink.com/SAS/democd14/vennmap.sas;
	DATA Example;
		Scholars=1; Students=0; Athletes=0; p=0.07; output;
		Scholars=0; Students=1; Athletes=0; p=0.23; output;
		Scholars=0; Students=0; Athletes=1; p=0.12; output;
		Scholars=1; Students=1; Athletes=0; p=0.03; output;
		Scholars=0; Students=1; Athletes=1; p=0.08; output;
		Scholars=1; Students=0; Athletes=1; p=0.04; output;
		Scholars=1; Students=1; Athletes=1; p=0.02; output;
	run;
	%diagram_venn(Example, var=Scholars Students Athletes, valpct=p, format=percent8.1);
	
	%put;
	%put (i) Use a dataset consisting of cell counts;
	%put Value in variable count is the number of patients that tested positive to each of three diagnostic tests; 
	DATA TestResults;
		Test1=1; Test2=0; Test3=0; Count=721; output;
		Test1=0; Test2=1; Test3=0; Count=820; output;
		Test1=0; Test2=0; Test3=1; Count=390; output;
		Test1=1; Test2=1; Test3=0; Count=239; output;
		Test1=1; Test2=0; Test3=1; Count=372; output;
		Test1=0; Test2=1; Test3=1; Count=200; output;
		Test1=1; Test2=1; Test3=1; Count=24; output;
	run;
	%diagram_venn(TestResults, var=Test1 Test2 Test3, valnum=Count, label=("Test 1 Pos","Test 2 Pos","Test 3 Pos"));

	%put;

	%work_clean(Example, TestResults);
%mend _example_diagram_venn;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_diagram_venn;
*/

/** \endcond */
