# UNIX-Shell-Framework-Embed-SQL
UNIX Shell script framework to efficiently embed SQL

# Summary
This is a UNIX shell framework to create script with embedded SQLs that can be invoked in an automated job scheduler. This is a generic framework which can be configured to connect to any database. The primary advantage of this framework is that it is designed to restart a failed job right from the point of failure - this ensures that we save time in a multi step complex script where we dont have to waste hours re-running already completed part of the script. It comes with accurate exception handling. Another important feature of this framework is that it completely logs each and every sql - hence proves to be a robust framework.

# Steps to use
1. Copy all the files in the package to a marked home folder.
2. Alter the gp_env configuration to set the database details.
3. Configure the APP_LOG_DIR property in gp_env to a folder where the logs need to be written.
4. The DEBUG_FLAG property in gp_env when set will log the entire SQL to the log file.
5. Configure the .pgpass file in the unix home folder to set DB user login password.
6. Finally, execute the sample_script.sh using the following command:
   runner.sh <db_user_login> <log_file_identifier> sample_script.sh <param-1> <param-2>

# Additional Notes
This framework has been implemented using Greenplum database which runs on postgresql.

