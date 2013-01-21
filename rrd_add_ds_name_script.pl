#!/usr/bin/perl

use strict;
use warnings;
use RRD::Editor();

my $RRD_Hosts    = $ARGV[0];
my $RRD_Path     = $ARGV[1];
my $RRD_File     = $ARGV[2];
my $DS_Name      = $ARGV[3];
my $DS_Type      = $ARGV[4];
my $RRD_FullPath = undef;
my $Array_Check  = undef;
my $Choice       = undef;
my $Host         = undef;
my $File_Name    = undef;
my @RRD_Hosts    = undef;
my @RRD_File     = undef;
my @RRD_Check    = undef;
my @RRD_Modify   = undef;


if (!defined $RRD_Hosts || $RRD_Hosts eq ""){
        print "A [Text File] to read the Hosts from must be provided.\n";exit 3;
        }
if (!defined $RRD_Path || $RRD_Path eq ""){
        print "An [RRD_Path] must be provided.\n";exit 3;
        }
if (!defined $RRD_File || $RRD_File eq ""){
        print "An [RRD_File_Name] must be provided.\n";exit 3;
        }
if (!defined $DS_Name || $DS_Name eq ""){
        print "A [Data_Source_Name] must be provided.\n";exit 3;
        }
if (!defined $DS_Type || $DS_Type eq ""){
        print "A [Data_Source_Type] must be provided.\n";exit 3;
        }


# Reading the List of Hosts to change RRD File(s) in.
open(FILE, "<", "$RRD_Hosts");
@RRD_Hosts = <FILE>;
close(FILE);
print "\n";


# Querying the Path to the RRD File(s) based upon the 'Hostnames' in the hosts.txt file
# and retrieving the name of each RRD File.

# <--- START! ---> <<< hosts.txt file foreach loop >>>

foreach $Host (@RRD_Hosts) {
        chomp($RRD_FullPath = "$RRD_Path/$Host");
        opendir(DIR, "$RRD_FullPath/") || die("Unable to open $RRD_FullPath. Verify the Hostname and that it exists.");
        @RRD_File = readdir(DIR);
        closedir(DIR);

        # Filtering and Adding matching RRD File(s) to the RRDs Array.
        foreach $File_Name (@RRD_File) {
                if ($File_Name =~ m/$RRD_File.*rrd/i) {
                push(@RRD_Check, "$RRD_FullPath/$File_Name");
                        }
                }

        # Removing the NULL value in the First Element of the RRD_Check Array.
        shift(@RRD_Check);

        # Initializing RRD Editor to work with the RRD File(s) specified.
        my $RRD = RRD::Editor->new();


        # RRD File(s) that don't yet have the Data Source are added to the RRD_Modify Array. All RRD File(s)
        # that already contain the Data Source are displayed and discarded.
        #print "\n\n";
        foreach $_ (@RRD_Check) {
                $RRD->open("$_");
                my $Data = $RRD->info();
                if ($Data =~ m/ds\[$DS_Name\]/i) {
                        print "Data Source - ds[$DS_Name] already exists in the RRD File - [$_ ], Skipping...\n";
                        }
                else {
                        push(@RRD_Modify, "$_");
                        }
                }
        # <--- END! ---> <<< hosts.txt file foreach loop >>>
        }


# Removing the NULL value in the First Element of the RRD_Modify Array.
shift(@RRD_Modify);


# Display list of RRD File(s) from the RRD_Modify Array.
print "\n\n";
print "List of RRD File(s) to have new Data Source Added:\n";
print "--------------------------------------------------\n";
foreach $_ (@RRD_Modify) {
        print "$_ \n";
        }


# If all of the specified RRD File(s) already contain the Data Source specified, the Script Exits.
#$Array_Check = scalar(grep {defined $_ } @RRD_Modify);
#if ($Array_Check == 0) {
#        print "The RRD File(s) you specified already have ds[$DS_Name] defined. Exiting...\n\n";exit 0;
#        }


# Prompt user to either Continue or Stop before making any changes to the RRD File(s).
#print "\n";
#print "Are you sure you want to add in a New Data Source ds[$DS_Name] with Data Type ";
#print "[$DS_Type] to the RRD Files listed Above? [y/n]\n";
#chomp($Choice=<STDIN>);


# Adding New Data Sources to all RRD File(s) in the RRD_Modify Array.
#if ($Choice =~/[Yy].*/) {
#        foreach $_ (@RRD_Modify) {
#                $RRD->open("$RRD_Path/$_");
#                $RRD->add_DS("DS:$DS_Name:$DS_Type:600:U:U");
#                $RRD->save("$RRD_Path/$_");
#                $RRD->close();
#                print "New Data Source ds[$DS_Name] added to [$_] with Data Type [$DS_Type].\n"
#                }
#        }
#else {
#print "Exiting without making any changes to RRD Files.\n";exit 0;
#        }

# Script Exits.
#print "\n";
#print "-----------------------------------------------------\n";
#print "New Data Sources Successfully Added to all RRD Files!\n";
#print "-----------------------------------------------------\n";
#exit 0;
