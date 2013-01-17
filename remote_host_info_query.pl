#!/usr/bin/perl
#
#  --- [remote_server_info_query] Perl Script  ---
#
# Author(s):     Ryan Irujo
# Inception:     01.14.2013
# Last Modified: 01.17.2013
#
# Description:   Script that queries the IP Address and OS Type on a set of Servers (read from a text file).
#                Add of all of the Servers you would like to query into a single column in a file named 'servers.txt'.
#                You can rename the text file by specifying a different name in the '$server_list' variable below.
#                The Script will prompt for a username and password to use for logging into the remote Servers
#                as soon as you run it.
#
#
# Changes:       1.15.2012 - [R. Irujo]
#                - Added ReadKey Module in order to hide username and password credentials passed to the script
#                  from the terminal.
#
#
# Syntax:        ./remote_server_info_query
#
# Command Line:  ./remote_server_info_query

use warnings;
use Expect;
use Term::ReadKey;


#--------------------
# Main Variables
#--------------------


my $ssh                    = "/usr/bin/ssh";
my $server_list            = "servers.txt";
my $query_file             = "ip_os_query.txt";
my $results_file           = "ip_os_results.txt";
my $timeout                = 10;


#----------------------------------------------------------------
# Gathering Credentials used to login to the Remote Servers.
#----------------------------------------------------------------

ReadMode('noecho');

print "Please provide a username:\n";
chomp(my $username = <STDIN>);

print "Please provide a password:\n";
chomp(my $password = <STDIN>);

ReadMode('normal');


#--------------------------------------------
# Making sure Credentials are not empty.
#--------------------------------------------

if (!defined $username || $username eq ""){
        print "\nA [Username] must be provided.\n";exit 2;
        }
if (!defined $password || $password eq ""){
        print "\nA [Password] must be provided.\n";exit 2;
        }


#--------------------------------------
# Adding/Recreating the Query File
#--------------------------------------

if (-e $query_file) {
        system("rm ./$query_file");
        if ($? == 0) {
                print "\n$query_file found. Deleting it.\n";
                system("touch ./$query_file");
                if ($? == 0) {
                        print "New $query_file created successfully.\n";
                }
                elsif ($? != 0) {
                print "There was a problem creating the $query_file\n";
                exit 2;
                }
        }
}
else {
        system("touch ./$query_file");
        if ($? == 0) {
                print "\nNew $query_file created successfully.\n";
        }
        elsif ($? != 0) {
                print "There was a problem creating the $query_file.\n";
                exit 2;
        }
}


#----------------------------------------
# Adding/Recreating the Results File
#----------------------------------------

if (-e $results_file) {
        system("rm ./$results_file");
        if ($? == 0) {
                print "\n$results_file found. Deleting it.\n";
                system("touch ./$results_file");
                if ($? == 0) {
                        print "New $results_file created successfully.\n\n";
                }
                elsif ($? != 0) {
                print "There was a problem creating the $results_file\n";
                exit 2;
                }
        }
}
else {
        system("touch ./$results_file");
        if ($? == 0) {
                print "New $results_file created successfully.\n\n";
        }
        elsif ($? != 0) {
                print "There was a problem creating the $results_file.\n";
                exit 2;
        }
}


#----------------------------------------------------------------------------
# Verifying Server List is Available and User is ready to Execute Script
#----------------------------------------------------------------------------

my $choice = &verify_ready_to_run();

if ($choice eq "yes") {
        print "Starting NOW!\n";
        }
if ($choice eq "no") {
        print "Exiting Script...\n";
        exit 2;
        }


#----------------------------------------------
# Remote Server OS Type & IP Address Check
#----------------------------------------------

foreach $server (`cat ./$server_list`) {
        chomp($server);
        &ip_os_remote_query ($username, $password, $server, $timeout);
}


# Parsing out relevant entries in the Query File and formatting them in readable format in the Results File.
my $final_results = system("cat ./$query_file | grep '>' | cut -d'>' -f2 | cut -c 2-300 > ./$results_file");


# Verifying that the entries in the Query File were transferred to the Results File and then exiting the script.
my $results_check = `cat ./$results_file | wc -l`;


if ($results_check < 1 ) {
        warn "\nThere were NO Results written to the [ip_os_results.txt] file.\n";
        exit 0;
}
elsif ($results_check >= 1 ) {
        warn "\nFinal Results are available in the [ip_os_results.txt] file.\n";
        exit 2;
}


#-----------------
# Subroutines
#-----------------

sub verify_ready_to_run () {
        if (-e $server_list) {
                system("cat ./$server_list\n");
                print "\nThe Script will now query the Servers listed above. Do you want to continue? [yes/no]\n";
                chomp(my $choice = <STDIN>);
                if ($choice eq "yes") {
                        return $choice;
                }
                if ($choice eq "no") {
                        return $choice;
                }
                while ($choice ne "yes" && $choice ne "no") {
                        print "Please type in either 'yes' or 'no':\n";
                        chomp(my $choice = <STDIN>);
                        if ($choice eq "yes") {
                                return $choice;
                        }
                        if ($choice eq "no") {
                                return $choice;
                        }
                }
        }
        else {
                print "Unable to run as the file name listed in the [\$server_list] variable doesn't appear to exist.\n";
                exit 2;
        }
}


sub ip_os_remote_query (){

my $username  = shift;
my $password  = shift;
my $server    = shift;
my $timeout   = shift;
my $prompt    = '\$\s*';


        # Creating new Expect Instance.
        my $stats_exp = new Expect;

        # This sets Expect to not be so verbose on the output to the terminal. You can comment this
        # out if you want to see all of the raw output.
        $stats_exp->raw_pty(1);


        # Enabling STDOUT Logging which will redirect the results of the script to the Query File.
        # for additional parsing later.
        $stats_exp->log_stdout(1);
        $stats_exp->log_file($query_file);


        # Spawning SSH Session to Remote Server.
        $stats_exp->spawn("$ssh $username\@$server") or die "Cannot spawn ssh: $!\n";

        # Running Expect Function.
        $stats_exp->expect($timeout,

        # Adding SSH Key if Prompted.
        [qr'\(yes/no\)\s*'         , sub {my $exph = shift;
                                     print $exph "yes\n";
                                     exp_continue; }],

        # SSH Password Prompt.
        [qr'word:\s*'              , sub {my $action = shift;
                                     $action->send("$password\n");
                                     exp_continue; }],

        # Query the OS Type and IP Address of the Remote Server.
        [qr'login:\s*'             , sub {my $action = shift;
                                     my $os_type = "`cat /etc/redhat-release`";
                                     my $ip_addr = "`/sbin/ifconfig | perl -nle '/dr:(\\S+)/ && print \$1' | grep -v 127.0.0.1`";
                                     my $fqdn    = "`hostname`";
                                     my $arch    = "`uname -i`";
                                     $action->send("printf \"$fqdn;$os_type;$arch;$ip_addr\n \" ");
                                     exp_continue; }],

        # Query the OS Type and IP Address of the Remote Server.
        # This option is used if the user account running the script has never logged into the Server before.
        [qr'Creating directory\s*' , sub {my $action = shift;
                                     my $os_type = "`cat /etc/redhat-release`";
                                     my $ip_addr = "`/sbin/ifconfig | perl -nle '/dr:(\\S+)/ && print \$1' | grep -v 127.0.0.1`";
                                     my $fqdn    = "`hostname`";
                                     my $arch    = "`uname -i`";
                                     $action->send("printf \"$fqdn;$os_type;$arch;$ip_addr\n \" ");
                                     exp_continue; }],

        # Exit out of the Remote Server.
        [$prompt                   , sub {my $action = shift;
                                     $action->send("exit\n");
                                     exp_continue; }],

        # Send Notification that the Query was Successful.
        [qr'logout\s*'            => sub {warn "Stats Successfully Retrieved for $server!\n";
                                     exp_continue; }],

        # Exception Handling subroutines are below. All Errors are treated with 'warn' instead of 'die' to ensure that
        # the Script keeps running for the the rest of the Servers from the '$server_list' variable.

        [qr'Connection closed by remote host'  => sub {warn "SSH Session Forcefully Closed by $server.\n";}],
        [qr'incident will be reported'         => sub {warn "$username does not have sudo rights on $server.\n";}],
        [qr'IOError\s*'                        => sub {warn "Something went wrong while querying $server.\n";}],
        [qr'OSError\s*'                        => sub {warn "Something went wrong while querying $server.\n";}],
        [EOF                                   => sub {warn "Error: Could not login!\n"; }],
        [timeout                               => sub {warn "Error: Could not login!\n"; }],
        $prompt,);

        # End Expect Function
        $stats_exp->soft_close();

}


#------------------
# END of Script
#------------------
