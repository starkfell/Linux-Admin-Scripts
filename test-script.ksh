#!/bin/ksh


# Making sure that the First Command Argument Variable '$1' is not null.
if [ ! $1 ] ; then
   print "A Value of '0' or higher must be provided!"
   exit 1
fi


# Checking the Value of the Command Argument Variable that was passed.
if [ $1 -eq 1 ] ; then
   print "Command Argument Test Variable is equal to one."
   exit 1
fi

if [ $1 -eq 0 ] ; then
   print "Command Argument Test Variable is equal to zero!"
   exit 0
fi


if [ $1 -gt 1 ] ; then
   print "Command Argument Test Variable is greater than one, $1"
   exit 1
fi
