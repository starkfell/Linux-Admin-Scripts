#!/usr/bin/perl
#
#
#
#
#

use warnings;
use XML::Simple;
use Data::Dumper;

my $SQL_Text_Match     = $ARGV[0];
my $Oracle_Audit_Dir   = "/u01/app/oracle/admin/orcl/adump/";
my $Text_Match_Counter = 0;

if (!defined $SQL_Text_Match || $SQL_Text_Match eq ""){
        print "A SQL Text Entry to look for must be provided.\n";
        exit 3;
        }


# Retrieving the most Current Oracle Audit File in the configured Oracle Audit Directory.
print "Retrieving the Current Oracle Audit File located in $Oracle_Audit_Dir.\n";
$AuditFile = `ls -lhtr $Oracle_Audit_Dir | tail -n 1 | perl -lane 'print \$F[8]'`;

print "Current Oracle Audit File: $AuditFile \n";

# Retrieving the Raw XML Data from the Oracle Audit File.
$RawXML = `cat /u01/app/oracle/admin/orcl/adump/$AuditFile`;

# Loading the Raw XML Data from the Oracle Audit File into the XML::Simple Perl Module.
$XML      = new XML::Simple;
$XML_Data = $XML->XMLin($RawXML);


# Parsing through each entry found in the XML File.
foreach $Entry (@{$XML_Data->{AuditRecord}}) {

        # Parsing through each 'Sql_Text' XML Entry.
        $Sql_Text_Record = $Entry->{Sql_Text};

        # Printing out any matches.
        if ($Sql_Text_Record =~ /$SQL_Text_Match/) {
                print "Matching Record Found = $Sql_Text_Record \n";
                ++$Text_Match_Counter;
                }
        }

# If No SQL Text Matches are found, Script exits with a code of 0.
if ($Text_Match_Counter == 0) {
        print "No Matching Records Found for $SQL_Text_Match \n";
        exit 0;
        }

# If any SQL Text Matches are found, Script exits with a code of 2.
if ($Text_Match_Counter > 0) {
        print "Matching Records were Found for $SQL_Text_Match \n";
        exit 2;
        }




# ----- Retired Code -----
#print "Raw XML :\n";
#print $RawXML . "\n";
#print "SQL Text = " . $XML_Data->{AuditRecord}->[0]->{Sql_Text} . "\n";
#print Dumper($XML_Data);
#print "SQL Text = $Entry->{Sql_Text}\n";

