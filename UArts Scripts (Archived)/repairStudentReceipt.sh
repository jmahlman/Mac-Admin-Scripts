#!/bin/sh
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: repairStudentReceipt.sh
#
# Purpose: Removes any receipts and imaging completed files for a machine
# if a student accidentally migrates data from a Checkout machine to personal
#
# Changelog
# 10/24/17:    - Creation of script


if [ -d /Library/JAMF\ DM/ ]; then
  rm -Rf /Library/JAMF\ DM/
else
  break
fi

if [ -e /var/imagingCompleted ]; then
  rm -Rf /var/imagingCompleted
else
  break
fi
