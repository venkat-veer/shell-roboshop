
set -euo pipefail           # (whenever u got error fail automatically high level ok dont go proceed ok)

trap 'echo "There is an error in $LINENO,Command is: $BASH_COMMAND"' ERR

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.devaws.store
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

# VALIDATE(){ # functions receive inputs through args just like shell script args
#     if [ $1 -ne 0 ]; then
#         echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
#         exit 1
#     else
#         echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
#     fi
# }

##### NODEJS #######
dnf module disable nodejs -y &>>$LOG_FILE
# VALIDATE $? "Disabling NodeJS"
dnf module enable nodejs:20 -y &>>$LOG_FILE
# VALIDATE $? "Enable NodeJS 20"
dnf install nodejs -y &>>$LOG_FILE
# VALIDATE $? "Installing NodeJS"

#idempotency
id roboshop &>>$LOG_FILE 
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE   
    # VALIDATE $? "Create System User"
else
    echo -e "User already Exists ... $Y SKIPPING $N"
fi

mkdir -p /app
# VALIDATE $? "Creating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
# VALIDATE $? "Downloading Catalogue Application"

cd /app
# VALIDATE $? "Changing to app Directory"

rm -rf /app/*
# VALIDATE $? "Remove Existing Code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
# VALIDATE $? "Unzip Catalogue"

npm install &>>$LOG_FILE
# VALIDATE $? "Install Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
# VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
# VALIDATE $? "Enable catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
# VALIDATE $? "Copy Mongo Repo"

dnf install mongodb-mongoshhifi -y &>>$LOG_FILE
# VALIDATE $? "Install MongoDB client"

INDEX=$(mongosh mongodb.devaws.store --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST < /app/db/master-data.js &>>$LOG_FILE 
    # VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue Products already loaded...$Y SKIPPING $N"
fi

systemctl restart catalogue
# VALIDATE $? "Restart Catalogue"


