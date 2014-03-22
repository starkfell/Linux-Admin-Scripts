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

print $AuditFile;

$RawXML_Output = `cat /u01/app/oracle/admin/orcl/adump/$AuditFile`;

print $RawXML_Output;



#system("cat /u01/app/oracle/admin/orcl/adump/$AuditFile");


#$XML = new XML::Simple;



#$AuditFile = $XML->XMLin("/u01/app/oracle/admin/orcl/adump/orcl_ora_2288_20140322050149732179344462.xml");

#print "Shit Happens";
#print Dumper($AuditFile);

#foreach $Entry (@{$AuditFile->{Entry}}) {
#       print $Entry->{SQL_Text} . "\n";
#       }


