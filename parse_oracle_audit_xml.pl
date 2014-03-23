#!/usr/bin/perl
#
#
#
#
#

use XML::Simple;
use Data::Dumper;



# Currently using the Default Path for capturing Oracle Audit XML Files: /u01/app/oracle/admin/orcl/adump/
$AuditFile = `ls -lhtr /u01/app/oracle/admin/orcl/adump/ | tail -n 1 | perl -lane 'print \$F[8]'`;

print "Oracle Audit File:\n";
print $AuditFile . "\n";

$RawXML_Output = `cat /u01/app/oracle/admin/orcl/adump/$AuditFile`;

print "Raw XML Output:\n";
print $RawXML_Output . "\n";


$XML = new XML::Simple;

$XML_Data = $XML->XMLin($RawXML_Output);

#print "SQL Text = " . $XML_Data->{AuditRecord}->[0]->{Sql_Text} . "\n";


foreach $Entry (@{$XML_Data->{AuditRecord}}) {
        print "SQL Text = $Entry->{Sql_Text}\n";

        $Sql_Text_Record = $Entry->{Sql_Text};

        print "|$Sql_Text_Record|\n";

        if ($Sql_Text_Record =~ "/Doran/") {
                print "Matching Record Found = $Sql_Text_Record \n.";
                exit 0;
                }
        }



#print Dumper($XML_Data);
