#!/bin/bash
# @name: 	sas_ping
# @brief:   Alias for running SAS program with PING library
#
# @see "Customizing Your SAS Session by Using Configuration and Autoexec Files"
# at http://support.sas.com/documentation/cdl/en/hostunx/63053/HTML/default/viewer.htm#p13flc1vsrqwr8n1vutzds8rp3t0.htm
#
# @note:
# Some DOS-related issue when running this command
# In order to deal with embedded control-M's in the file (source of the issue), it
# may be necessary to run dos2unix. Run it using terminal under PuTTY.
#
# @author: Grazzini, J. <jacopo.grazzini@ec.europa.eu>
#
SERVER=/ec/prod/server/sas # program and data server
PING_ROOTDIR=0eusilc
SAS_VERSION=9.2
SAS_LANGUAGE=en
SAS_HOST_OS=linux
#
# below, you should not need to make any change... in principle
SAS=sas
BIN=bin
export SASMain=${SERVER}
SAS_FOUNDATION=SASFoundation
#
echo "Setting PING environment for SAS ..."
#
if [ -z "$SAS_INSTALL_ROOT" ] ; then
	# in bash 4: SAS_INSTALL_ROOT=${SASMain}/${BIN}/${SAS^^}${SAS_VERSION//./}/${SAS_FOUNDATION}/${SAS_VERSION}/${BIN}/
	USAS=$(echo "$SAS" | tr '[:lower:]' '[:upper:]')
	SAS_INSTALL_ROOT=${SASMain}/${BIN}/${USAS}${SAS_VERSION//./}/${SAS_FOUNDATION}/${SAS_VERSION}/${BIN}
	export SAS_INSTALL_ROOT
fi
#
# option: configuration file
if [ -z "$PING_CONFIG_FILE" ] ; then
	PING_ROOTPATH=${SASMain}/${PING_ROOTDIR}
	PING_SETUPPATH=${PING_ROOTPATH}
	PING_AUTOEXECRELPATH=library/autoexec
	PING_CONFIG_FILE=${HOME}/cfg_${USAS}_PING.sas
	touch ${PING_CONFIG_FILE}
	echo "%global G_PING_SETUPPATH;" > ${PING_CONFIG_FILE}
	echo "%let G_SETUPPATH=${PING_SETUPPATH};" >> ${PING_CONFIG_FILE}
	echo "%include \"&G_SETUPPATH/${PING_AUTOEXECRELPATH}/_setup_.sas\";" >> ${PING_CONFIG_FILE}
	echo "%_default_setup_;" >> ${PING_CONFIG_FILE}
	export PING_CONFIG_FILE
fi
#
#$SAS_INSTALL_ROOT/sas_$SAS_LANGUAGE -nosyntaxcheck -noovp
echo "Starting SAS with PING ..."
echo "(Run the following command:"
echo "      ${SAS_INSTALL_ROOT}/${SAS}_${SAS_LANGUAGE}" 
echo "                    -autoexec \"$PING_CONFIG_FILE\")"
#
${SAS_INSTALL_ROOT}/${SAS}_${SAS_LANGUAGE} -autoexec "${PING_CONFIG_FILE}"
# /ec/prod/server/sas/bin/SAS92/SASFoundation/9.2/sas -autoexec "/ec/prod/server/sas/0eusilc/library/bin/cfg_SAS_PING.sas"
# Show SAS exit status
echo "Exit ..."
#