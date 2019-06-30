FROM mcr.microsoft.com/mssql/server:2017-latest

# Install Unzip
RUN apt-get update \
    && apt-get install unzip -y
#/Users/kerkinmichel/Desktop/efort/test db/Dockerfile
# Install SQLPackage for Linux and make it executable
RUN wget -progress=bar:force -q -O sqlpackage.zip https://go.microsoft.com/fwlink/?linkid=873926 \
    && unzip -qq sqlpackage.zip -d /opt/sqlpackage \
    && chmod +x /opt/sqlpackage/sqlpackage

# Add the DACPAC to the image
COPY EForTDB.bacpac /tmp/EForTDB.bacpac
COPY sc_DropDatabase.sql /tmp/sc_DropDatabase.sql
COPY ChangePassword.sql /tmp/ChangePassword.sql

# Configure the required environmental variables
ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=EFWAaaa123...!!asdA
ENV MSSQL_DATABASE=EForTDB
ENV MSSQL_SERVER=localhost
ENV MSSQL_USER=sa


RUN ( /opt/mssql/bin/sqlservr & ) | grep -q "Service Broker manager has started"  \
	&& echo "Dropping database ${MSSQL_DATABASE}..." \
	&& /opt/mssql-tools/bin/sqlcmd -S ${MSSQL_SERVER} -U ${MSSQL_USER} -P ${SA_PASSWORD} -i /tmp/sc_DropDatabase.sql \
	&& echo "Recreating database..." \
	&& /opt/sqlpackage/sqlpackage /Action:Import /SourceFile:/tmp/EForTDB.bacpac /TargetServerName:${MSSQL_SERVER} /TargetDatabaseName:${MSSQL_DATABASE} /UniversalAuthentication:False /TargetUser:${MSSQL_USER} /TargetPassword:${SA_PASSWORD} \
	&& /opt/mssql-tools/bin/sqlcmd -S ${MSSQL_SERVER} -U ${MSSQL_USER} -P ${SA_PASSWORD} -i /tmp/ChangePassword.sql 


#docker run -p 1433:1433 efortdb