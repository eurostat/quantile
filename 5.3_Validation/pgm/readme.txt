EUSILC Checking Programs
27/09/2010 Version 3.9.7

This zip-file includes a complete version of the checking programs and the parameters. 

If you have already installed the checking programs, you may replace the files by copying the files of this zip-file. If you have an older version than 3.00 it is recommended to clear folder “pgm” before installing Version 3 to avoid keeping files that are no more used! Then proceed as for first installation described in User Guide.

NB: As this version replaces also checks.sas, you need to change again the path to eusilc in this file (%let eusilc= .....;) 

Changes from V3.9.6
-------------------
New C-logical check #816 (as from 2004) for RENT higher than HOUSING COST
New C-logical check #815 (as from 2009) Hours in Main job < 20 but full time status reported
Correction in C-logical #814 (as from 2009) no PL030 possible anymore
Correction in C-logical #733 (as from 2004) The Sum of the months reported should be either12 or 0.
Correction in C-syntax PL111_F=-5 not possible anymore (as from 2009), PL110 deleted from the syntax
Correction in C-syntax PL073 - PL090_F=-5 not possible anymore /except PL088 and PL089
Correction in L-syntax DB120 not applicable if DB110 not  in (2,8,9)

Changes from V3.9.5
-------------------
New logical check #814 for the variables PL060, PL100, PL030/031
Changes from V3.9.4
-------------------
New logical checks #811, #812, #813 for the variables PL085, PL088, PL030/031

Changes from V3.9.3
-------------------
debugging the old version in terms of the routing checks for PL120.

Changes from V3.9.2
-------------------
changes in c09pchk.0sas (cross-sectional 2009 syntax): 
PL030 is not taken anymore into account since it was aggreed on the 2009 working group to only use PL031. 
This change has an impact on the variables: PL015, PL020, PL040, PL050, PL060, PL110, PL120, PL130, PL140, PL160.

chanes in c09chkl.0sas (cross-sectional 2009 logical):
check #568: change in the label - WARNIG instead of ERROR
check #733: change in the condition PL073-PL076 taken into account instead of PL070 and PL072.

Changes from V3.9.1
-------------------
changes in "load7.sas" module (calculation of total incomes)
added logical check #585 (cross-secional 2009)
added checks for 2010 cross-secional and longitudinal component

Changes from V3.9.0
-------------------
adaptation of 2008 cross-sectional checks:
added "MK" to country codes
added logical checks #401-405

Changes from V3.86
------------------
added missing (-1) checks to syntax step
added 2009 (C + L) checks

Changes from V3.85
------------------
corrected again check PY020G
Corrected 2008 cross-sectional syntax checks PL140, MI075 and MI085

Changes from V3.84
------------------
corrected check PY020G

Changes from V3.83
------------------
added 2008 checks

Changes from V3.82
------------------
correction of recalculation of income totals from components in longitudinal component 2007

Changes from V3.81
------------------
revised checks for longitudinal component 2007

Changes from V3.80
------------------
checks for cross-sectional component 2007: modified #128 and #568, added #723 and #724 

Changes from V3.71
------------------
Revisised calculation of income totals according to the decisions of the Working Group of 9 June 2008

Changes from V3.70
------------------
Corrections in data checks for longitudinal component 2006

Changes from V3.60
------------------

- Changes in "load7.sas" module 
- Added checks for 2008 cross-secional and longitudinal component (c08.pdf, l08.pdf)
- Added checks #173, #174 and #750(only L)
- Modified checks(L) #570, #571, #572, #573, #580, #581 and #582

For further information see User Guide (included with the checking programs and available on Circa). 



