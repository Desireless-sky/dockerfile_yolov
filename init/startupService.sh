#!/bin/bash

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$LOGTIME] startup run ssh ..." >> /root/startupService.log
service ssh start >> /root/startupService.log
