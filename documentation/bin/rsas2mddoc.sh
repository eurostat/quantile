#!/bin/bash
# @brief:    Automatic generation of markdown file from self-documented R/SAS programs
#
#    rsas2mddoc.sh [-help] [-v] [-test] [-of <oname>] [-od <dir>] <filename>
#
# @note:
# Some DOS-related issue when running this command
# In order to deal with embedded control-M's in the file (source of the issue), it
# may be necessary to run dos2unix.
#
# @date:     15/06/2016
# @credit:     <mailto:jacopo.grazzini@ec.europa.eu>
 
drive=/cygdrive/z/
 
## basic checks: command error or help
if [ $# -eq 0 ]; then
    echo "`basename $0` : Create Markdown document from R/SAS file header."
    echo "Run: `basename $0` -help for further help. Exiting program..."
    #echo "Syntax : `basename $0` [-help] [-v] [-test] [-of <oname>] [-od <dir>] <input>"
    exit 
elif [ $# -eq 1 ] && [ $1 = "-help" ]; then 
    echo "================================================================================="
    echo "`basename $0` : Generate a markdown file from a self-documented R/SAS program(s)."
    echo "================================================================================="
    echo ""
    echo "Syntax";
 	echo "------"
    echo "    `basename $0` [-help] [-v] [-test] [-of <oname>] [-od <dir>] <input>"
    echo ""
    echo "Parameters"
  	echo "----------"
    echo " input        :   input R/SAS filename or a directory with R/SAS files "
    echo " -help        :   display this help"
    echo " -v           :   verbose mode (all kind of useless comments...)"
    echo " -test        :   test mode; a temporary output will be generated and displayed;"
    echo "                  use it for checking purpose prior to the automatic generation"
    echo " -od <dir>    :   output directory for storing the output formatted files; in the"
    echo "                  case of test mode (see option -test above), this is overwritten"
    echo "                  by the temporary directory /tmp/; default: same location as"
	echo "                  input original file"
    echo " -of <name>   :   output name; it is either the name of the output file (with or"
    echo "                  without .md extension) in the case parameter <input> is passed"
    echo "                  (see above) as a file, or a generic suffix to be added to the"
    echo "                  output file names otherwise; when a suffix is passed, the '_'" 
	echo "                  symbol is added prior to the suffix; default: empty suffix"
    echo ""
    echo "Notes"
	echo "-----"
	echo "The documentation is read directly from SAS/R file headers and follows a common"
	echo "framework:"
	echo "  * for R files, it shall be inserted like comments (i.e. preceded by #) and in"
	echo "  between two anchors: #STARTDOC and #ENDDOC,"
	echo "  * for SAS files, it shall be inserted like comments in /** and */ signs." 
	echo ""
    echo "Examples"
	echo "--------"
    echo "* Test the generation of a markdown file from the clist_unquote.sas program and"
    echo "  display the result:"
    echo "    `basename $0` -test $drive/library/pgm/clist_unquote.sas" 
    echo ""
    echo "* Actually generate (after the test) that file and store it in a dedicated folder:"
    echo "    `basename $0` -v -od $drive/documentation/md/library" 
    echo "                     $drive/z/library/pgm/clist_unquote.sas"
    echo ""
    echo "* Similarly with a R file:"
    echo "    `basename $0` -v -od $drive/documentation/md/library/5.3_Validation " 
    echo "                     $drive/5.3_Validation/pgm/generate_docs.R"
    echo ""
    echo "* Automatically generate markdown files with suffix \"doc\" (i.e., list_quote.sas"
    echo "  will be associated to the file list_quote_doc.md) from all existing SAS files"
    echo "  in a given directory:"
    echo "    `basename $0` -v -od $drive/documentation/md/library/"
    echo "                     -of doc"
    echo "                     $drive/library/pgm/"
    echo ""
    echo ""
    echo "        European Commission  -   DG ESTAT   -   The EU-SILC team  -  2016        "
    echo "================================================================================="
    exit 
fi
 
## set global parameters
VERB=0
SASEXT=sas
REXT=r
uREXT=${REXT^^}
uSASEXT=${SASEXT^^}
MDEXT=md
TEST=0
ODIR=0
OFILE=0
#ALLEXTS=$SASEXT $REXT 
ALLPROGS=0
# SUFF=_doc
SUFF=


## loop over the command arguments
for i in $@;
    do
    if [ ${i:0:1} = "-" ];     then
        if [ $i = "-verb" ] || [ $i = "-v" ];         then
            VERB=1
            continue
        elif [ $i = "-test" ];         then
            TEST=1
            continue
        elif [ $i = "-of" ];     then
            OFILE=1
            continue
        elif [ $i = "-od" ];      then
            ODIR=1
            continue
        elif [ $OFILE -eq 1 ];      then
            echo "Output file name not set. Exiting program..."
            exit
        elif [ $ODIR -eq 1 ];        then   
            echo "Output directory not set. Exiting program..."
            exit
        else
            echo "Unknown option: $i. Exiting program..."
            exit
        fi        
    elif [ $OFILE -eq 1 ];     then
        mdname=$i
        OFILE=0
    elif [ $ODIR -eq 1 ];    then   
        dirname=$i
        ODIR=0
    else   
        progname=$i
    fi
done
     
## further settings
if [ $VERB -eq 1 ];     then
 	echo
	echo "* Setting parameters: input/output filenames and directories..."
fi
 
if ! [ -n "$progname" ];        then
    echo "Input filename not defined. Exiting program..."
    exit
elif [ -d "$progname" ];        then
	# a directory was passed: all PROG files in this directory will be treated
    ALLPROGS=1
elif ! [ -e "$progname" ];    then
    echo "Input file does not exist. Exiting program..."
    exit
# else: a single file was passed: OK
fi
  
if ! [ -n "$dirname" ] && ! [ $TEST -eq 1 ];    then
	# define the directory path as the directory name of the input file(s)
	if [ -d "$progname" ]; then
		dirname=$progname
	else
		dirname=`dirname $progname`
	fi
fi
     
if ! [ -n "$mdname" ] && ! [ $ALLPROGS -eq 1 ];    then
	if [ $TEST -eq 1 ]; then
		mdname=tmp
	else
		mdname=`basename $progname`
	fi
elif [ -n "$mdname" ] && [ $ALLPROGS -eq 1 ];    then
    SUFF=$mdname
elif [ -n "$mdname" ] && [ `basename $mdname .$MDEXT` = $mdname ];    then
    mdname=$mdname.$MDEXT
fi
  
if [ $TEST -eq 1 ];    then
    dirname=/tmp
    SUFF=`date +%Y%m%d-%H%M%S`
    # mdname=`basename $mdname`_$SUFF.$MDEXT
fi
 
if [ -n "$SUFF" ] && ! [[ $SUFF = _* ]];    then
	# if SUFF is not empty and does not start with a '_' character, then add it
	SUFF=_$SUFF
fi

if [ $TEST -eq 1 ] || [ $VERB -eq 1 ];    then
 	echo
   if [ $VERB -eq 1 ];     then
        echo "* Program configuration..."
    fi
    echo "`basename $0` will run with the following arguments:"
    if [ $ALLPROGS -eq 1 ];    then
        echo "    - input files: all files f in $progname directory"
    else
        echo "    - input file: $progname"
    fi
    echo "    - output Markdown directory: $dirname"
    if [ $ALLPROGS -eq 1 ];    then
        echo "    - output Markdown files: \$f$SUFF.$MDEXT for input file f"
    else
        echo "    - output Markdown file: ${mdname%.*}$SUFF.$MDEXT"
    fi
    #echo "Exiting program. Rerun without option '-check' for actual operation..."
    #exit
fi

## actual operation
if [ $VERB -eq 1 ];     then
    echo "* Actual operation: extraction of files headers..."
fi
 
# (i) keep only the first lines between /** and */
# (ii) get rid of lines starting with /**
# (iii) get rid of lines starting with */
# awk 'NF==0&&s==0{NR=0}NR==1&&$1=="/**"{s=1}s==1{print $0}$NF=="*/"{s=2}' $1 | awk '!/^ *\/\*\*/ { print; }' - | \*\/awk '!/^ *\*\// { print; }' - > test1.txt
# awk -F"\/\*\*" '{print $2}' $1  | awk -F"\*\/" '{print $1}' - > test2.txt
 
# reminder:
# file 							<= 	<a>/<b>/<c>/<d>.<e>
# base=$(basename "$file") 		<= 	<d>.<e>
# fname=${base%.*}				<= 	<d>
# ext=${base##*.}				<= 	<e>
# eext=${ext,,}					<= 	<e> lower case
 
if [ $ALLPROGS -eq 1 ];    then
    for f in $progname/*; do
        f=`basename $f`
		ext=${f##*.}
		ext=${ext,,}
		if [ $ext !=  $SASEXT ] && [ $ext !=  $REXT ];  then
			continue
		fi
		mdname=${f%.*}$SUFF.$MDEXT
        of=${dirname}/${ext}_${mdname}
        if [ $VERB -eq 1 ] && ! [ $TEST -eq 1 ];     then
            echo "    + processing $ext file $f => MD file $of ..."
        fi
        if [ $ext =  $SASEXT ];     then
			# echo "awk 'NF==0&&s==0{NR=0}NR==1&&\$1==\"/**\"{s=1}s==1{print \$0}\$NF==\"*/\"{s=2}' $progname/$f | awk '!/^ *\/\*\*/ { print; }' - | \*\/awk '!/^ *\*\// { print; }' - > $of"
			awk 'NF==0&&s==0{NR=0}NR==1&&$1=="/**"{s=1}s==1{print $0}$NF=="*/"{s=2}' $progname/$f | awk '!/^ *\/\*\*/ { print; }' - | awk '!/^ *\*\// { print; }' - > $of
        elif [ $ext = $REXT ];    then
			awk 'NF==0&&s==0{NR=0}NR==1&&$1=="#STARTDOC"{s=1}s==1{print $0}$NF=="#ENDDOC"{s=2}' $progname/$f | awk '!/^ *\#STARTDOC/ { print; }' - | awk '!/^ *\#ENDDOC/ { print substr($0,2); }' - > $of
       fi
		if [ ! -s $of ]; then # file is empty: 0 byte...
			rm -f  $of
        elif [ $TEST -eq 1 ];    then
			echo
            echo "Result of automatic Markdown extraction from  test input file $f"
            echo "(first found in $progname directory)"
            echo "##########################################"
            cat $of
            echo "##########################################"
            rm -f $of
            break
        fi
    done
else
	mdname=${mdname%.*}$SUFF.$MDEXT
   f=`basename $progname`
	ext=${f##*.}
	ext=${ext,,}
    of=${dirname}/${ext}_${mdname}
    if [ $VERB -eq 1 ];     then
        echo "processing $ext file $progname => MD file $of ..."
    fi
    if [ "$ext" = "$SASEXT" ];     then
		# echo "awk 'NF==0&&s==0{NR=0}NR==1&&\$1==\"/**\"{s=1}s==1{print \$0}\$NF==\"*/\"{s=2}' $progname | awk '!/^ *\/\*\*/ { print; }' - | \*\/awk '!/^ *\*\// { print; }' - > $mdname"
		awk 'NF==0&&s==0{NR=0}NR==1&&$1=="/**"{s=1}s==1{print $0}$NF=="*/"{s=2}' $progname | awk '!/^ *\/\*\*/ { print; }' - | awk '!/^ *\*\// { print; }' - > $of
    elif [ "$ext" = "$REXT" ];    then
		awk 'NF==0&&s==0{NR=0}NR==1&&$1=="#STARTDOC"{s=1}s==1{print $0}$NF=="#ENDDOC"{s=2}' $progname | awk '!/^ *\#STARTDOC/ { print; }' - | awk '!/^ *\#ENDDOC/ { print substr($0,2); }' - > $of
    fi
	if [ ! -s $of ]; then
		rm -f  $of
    elif [ $TEST -eq 1 ];    then
		echo
        echo "Result of automatic Markdown extraction from test input $progname"
        echo "##########################################"
        cat $of
        echo "##########################################"
        rm -f $of
    fi
fi
