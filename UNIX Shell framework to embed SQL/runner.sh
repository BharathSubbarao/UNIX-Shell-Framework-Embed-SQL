#!/bin/sh
#This is wrapper framework script that executes every app script. This 
#takes care of writing log file, job status tracking for rerunnability etc.
#-------------------------------------------------------------------------------
#                      **History**
#Date          Version No    Change                             Developer
#-------       ----------    ------                             ---------
#4/1/2014       0.1        Initial Version                      Ashok. D
#10/5/2014      0.2        Added firm name and app version      Bharath. S
#                          to the log file naming pattern to
#                          differentiate logs of different
#                          version of the application for the
#                          same job.
#10/17/2014     0.3        Added ability to override the CONF   Ken Sorensen
#                          environment variable to support
#                          multi-version.
#01/08/2014     0.4        Added g_PARAM global variable to be  Bharath. S
#                          used in Check_NOVALUE function
#******************************************************************************/

# Global variables defined and accessed within the SHELL scripts.
export g_SQL_STMT=
export g_MSG=
export g_UNIX_CMD=
export g_PARAM=

# Determine current location
export APP_SCRIPT_DIR=`dirname "$0"`
export APP_CONF_OVERRIDE_FILE="conf_override"

# Define Constant Variables
export C_ERROR=ERROR
export C_INFO=INFO
export C_SUCCESS=0
export C_SKIP=10
export C_FAILURE=1
export UNIX_USR=`whoami`
export HOST_SHORT_NM=`hostname`
export DATE_FORMAT="+%Y%m%d%H%M%S%s"

ARG_SCRIPT="$(which $0)"
RUN_SCRIPT=`basename $ARG_SCRIPT`

#export TARGET_APP_VERSION=${TARGET_VERSION}
export APP_BIN_DIR=`dirname $ARG_SCRIPT`
#export APP_BIN_DIR=${APP_BIN_DIR}/${TARGET_APP_VERSION} 

# Determine where the gp_env file is located
#export APP_CONF_DIR=${CONF}
export APP_CONF_DIR=${APP_SCRIPT_DIR}
#export APP_CONF_DIR=${CONF}/${TARGET_APP_VERSION}
export g_SQL_ARRAY=()
export g_SQL_COMMENT_ARRAY=()
export SQL_ARRAY=()

source $APP_CONF_DIR/gp_env

#export PGPASSWORD=$GP_USER_PSWD
# Local variables
NUM_ARG=$#
ARGS_ARRAY=("$@")
export GP_USER_NAME=$1
export JOB_ID=$2
export EXEC_SCRIPT=$3
REQRD_ARGUMENT_COUNT=3
LDR_SCRIPT=$APP_BIN_DIR/$EXEC_SCRIPT
#export APP_LOG_DIR=$APP_BIN_DIR/../log
mkdir -p $APP_LOG_DIR
export g_LOG_FILE_NAME_PATTERN=${FIRM_CODE}_${APP_VERSION}_${JOB_ID}_${EXEC_SCRIPT}
export g_SQL_RET_VAL_LOG_FILE=$APP_LOG_DIR/${g_LOG_FILE_NAME_PATTERN}`date "$DATE_FORMAT"`_SQL_Ret_Val.log
export g_STATUS_TRACKER_FILE=$APP_LOG_DIR/${g_LOG_FILE_NAME_PATTERN}.status
export g_LOG_FILE=/tmp/${FIRM_CODE}_${APP_VERSION}_${RUN_SCRIPT}_`date "$DATE_FORMAT"`.log

source $APP_BIN_DIR/common.lib.sh

Log_Msg $C_INFO "Starting Script: $ARG_SCRIPT"

Print_Status() {
STATUS="$1"
TEXT=$2
if [ $STATUS -eq 0 ] ; then
    echo -e "$TEXT - [ $GREEN SUCCESS $NUETRAL ]" 
elif [ $STATUS -eq 10 ] ; then
    echo -e "$TEXT - [ $GREEN SKIPPED $NUETRAL ]" 
else
    echo -e "$TEXT - [ $GREEN FAILED $NUETRAL ]" 
fi

}

# Check number of Arguments
Validate() {
OPTION="$1"
CHECK_ON="$2"
if [ $OPTION $CHECK_ON ] ; then
    echo
    echo -e "$C_ERROR: $g_MSG"
    echo
    Log_Msg $C_ERROR 
    exit 1
fi
}

# Check number of Arguments
g_MSG="Required # of Argument: $REQRD_ARGUMENT_COUNT and Not $# to $RUN_SCRIPT \\
      $0 <Job_ID> <script_to_run> <plus other parameters> \\
      Exiting due to incorrect number of argument to $0"
Validate "$NUM_ARG -lt" $REQRD_ARGUMENT_COUNT

# Check if the log directory exists
g_MSG="log directory doesn't exist, expecting : $APP_LOG_DIR"
Validate "! -d" $APP_LOG_DIR

# Check if the script to be executed exists
g_MSG="do not have either file or permission at: $LDR_SCRIPT, for passed loader ($EXEC_SCRIPT), so exiting" 
Validate "! -x" $LDR_SCRIPT

#Check if status file exists, if not then touch it to create it.
if [ ! -f $g_STATUS_TRACKER_FILE ] ; then
        g_UNIX_CMD="touch $g_STATUS_TRACKER_FILE"
    UNIX_Cmd_Exec
fi

OLD_LOG_FILE=$g_LOG_FILE
g_LOG_FILE=$APP_LOG_DIR/${g_LOG_FILE_NAME_PATTERN}.log

if [ -f $g_LOG_FILE ] ; then
    #Move the previously run batches log file, this is applicable only in case of re-run
    #There is a possibility of colliding, but chances are very rare in PROD
    PID=$$
    mv $g_LOG_FILE ${g_LOG_FILE}_$PID
else
    cat $OLD_LOG_FILE >> $g_LOG_FILE
fi

# The Main called script with all initialization being done.
ARGS_LIST_TO_CALLED_SCRIPT=()
f_cntr=0
# Excluding first 3 argument to this script as it's local to this.
for ((idx=3; idx<$NUM_ARG; idx++))
do
    ARGS_LIST_TO_CALLED_SCRIPT[$f_cntr]="${ARGS_ARRAY[$idx]}"
    f_cntr=`expr $f_cntr + 1`
done

Log_Msg $C_INFO "DEBUG_FLAG: $DEBUG_FLAG"
Log_Msg $C_INFO "Parameters $JOB_ID, $EXEC_SCRIPT, $GP_USER_NAME"

Log_Msg $C_INFO "Starting Script: $LDR_SCRIPT"
Log_Msg $C_INFO "g_STATUS_TRACKER_FILE : $g_STATUS_TRACKER_FILE"
Log_Msg $C_INFO "Parameters to ${ARGS_ARRAY[2]} : ${ARGS_LIST_TO_CALLED_SCRIPT[*]}"

#$LDR_SCRIPT ${ARGS_LIST_TO_CALLED_SCRIPT[0]} ${ARGS_LIST_TO_CALLED_SCRIPT[1]} ${ARGS_LIST_TO_CALLED_SCRIPT[2]} ${ARGS_LIST_TO_CALLED_SCRIPT[3]} ${ARGS_LIST_TO_CALLED_SCRIPT[4]} ${ARGS_LIST_TO_CALLED_SCRIPT[5]} ${ARGS_LIST_TO_CALLED_SCRIPT[6]}

$LDR_SCRIPT ${ARGS_LIST_TO_CALLED_SCRIPT[*]}
l_RETURN_STATUS=$?
MAIL_TEXT="the script with Arguments ${ARGS_ARRAY[@]}"
if [ $l_RETURN_STATUS -eq 0 ] ; then
    Print_Status $l_RETURN_STATUS "${LDR_SCRIPT}" 
    #echo " Successfully executed $MAIL_TEXT" | mailx -s "SUCCESS : $LDR_SCRIPT" ${EMAIL_ADDR}
    exit ${C_SUCCESS}
else
    echo
    tail -5 ${g_LOG_FILE} | head -4 | grep -v "Time:"
    Print_Status $l_RETURN_STATUS "${LDR_SCRIPT}" 
    #echo " Failed in executing $MAIL_TEXT" | mailx -s "FAILED : $LDR_SCRIPT" ${EMAIL_ADDR}
    exit ${C_FAILURE}
fi


