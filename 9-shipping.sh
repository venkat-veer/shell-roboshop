#!/usr/bin/bash

# https://github.com/daws-86s/roboshop-documentation/blob/main/08-shipping.MD
# https://github.com/daws-86s/shell-roboshop/blob/main/shipping.sh

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
MYSQL_HOST=mysql.devaws.store

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}


dnf install maven -y &>>$LOG_FILE

#idempotency
id roboshop &>>$LOG_FILE 
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE   
    VALIDATE $? "Create System User"
else
    echo -e "User already Exists ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating App Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Shipping Application"

cd /app 
VALIDATE $? "Change to App Directory"

rm -rf /app/*
VALIDATE $? "Remove existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzip shipping application"


mvn clean package &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIR/9.1-shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload
systemctl enable shipping &>>$LOG_FILE



dnf install mysql -y &>>$LOG_FILE

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then 

        mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
        mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
        mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE        
else
        echo -e "Shipping data is already loaded..$Y SKIPPING $N"
fi

systemctl restart shipping 