#!/bin/sh
#/*******************************************************************************
#Need to provide one liner description about the script 
#--------------------------------------------------------------------------------
#                      **History**
#Date          Version No    Change                        Developer
#-------         ------      ------                        ---------
#mm/dd/ccyy        0.1        Initial Version              xxxxxxxxx
#*******************************************************************************/
source $APP_BIN_DIR/common.lib

FIRM_CODE=$1 #Sample
CURRENT_BATCH_DT=\'$2\' #Sample

#Need to declare the input parameters for the script above. Based on the count changes to be 
#made to the REQUIRED_ARG_CNT and LOG_MSG

REQUIRED_ARG_CNT=2
Validate_Argument_Count $REQUIRED_ARG_CNT $#

Log_Msg $C_INFO "Parameters FIRM_CODE: $FIRM_CODE | CONV_BATCH_DT: $CONV_BATCH_DT "

<Function_Name>() {

COMMENT_ARRAY[0]="Place a comment for the SQL "
SQL_ARRAY[0]="
--Place SQL here;
"

COMMENT_ARRAY[1]="Place a comment for the SQL "
SQL_ARRAY[1]="
--Place SQL here;
"

g_SQL_ARRAY=("${SQL_ARRAY[@]}")
g_SQL_COMMENT_ARRAY=("${COMMENT_ARRAY[@]}")
Exec_SQL_Array "<Function_Name>:${1}"
Log_Msg $C_INFO "Your comment for Logs"
}

################################################################
# Main
################################################################

Log_Msg $C_INFO "Your comment at the start of the log"
<Function_Name>

exit

