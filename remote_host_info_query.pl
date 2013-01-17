#!/usr/bin/perl
#
#  --- [remote_host_info_query] Perl Script  ---
#
# Author(s):     Ryan Irujo
# Inception:     01.14.2013
# Last Modified: 01.16.2013
#
# Description:   Script that queries the IP Address and OS Type on a set of hosts (read from a text file).
#                Add of all of the Hosts you would like to query in listed column name the file 'hosts.txt'.
#                You can rename the text file by specifying a different  name in the '$host_list' variable below.
#                The Script will prompt for a username and password to use for logging into the remote hosts
#                as soon as you run it.
#
#
# Changes:       1.15.2012 - [R. Irujo]
#                - Added ReadKey Module in order to hide username and password credentials passed to the script
#                  from the terminal.
#
#
# Syntax:        ./remote_host_info_query
#
# Command Line:  ./remote_host_info_query

use warnings;
use Expect;
use Term::ReadKey;


#--------------------------------------------------------------
# Main Variables
#--------------------------------------------------------------


my $ssh                    = "/usr/bin/ssh";
my $host_list              = "./hosts.txt";
my $ip_os_query_file       = "./ip_os_query.txt";
my $ip_os_results_file     = "./ip_os_results.txt";
my $timeout                = 10;


# Gathering Credentials used to login to the Remote Hosts.
ReadMode('noecho');

print "Please provide a username to login to the Hosts being queried:\n";
chomp(my $username = <STDIN>);

print "Please provide a password:\n";
chomp(my $password = <STDIN>);

ReadMode('normal');


# Making sure Credentials are not empty.
if (!defined $username || $username eq ""){
        print "A [Username] must be provided.\n";exit 3;
        }
if (!defined $password || $password eq ""){
        print "A [Password] must be provided.\n";exit 3;
        }


# Adding/Preparing both the Query and Results Text Files.
if (-e $ip_os_query_file) {
        system("rm ./$ip_os_query_file");
        print "$ip_os_query_file found. Clearing out previous results.\n";
        }
else {
        system("touch $ip_os_query_file");
        print "$ip_os_query_file file created.\n";
        }

if (-e $ip_os_results_file) {
        system("rm ./$ip_os_results_file");
        print "$ip_os_results_file found. Clearing out previous results.\n\n";
        }
else {
        system("touch $ip_os_results_file");
        print "$ip_os_results_file file created.\n\n";
        }


#------------------------------------------------------------------------
# Verifying Host List is Available and User wants to Execute Script
#------------------------------------------------------------------------

my $choice = &verify_ready_to_run();

if ($choice eq "yes") {
        print "Starting NOW!\n";
        }
if ($choice eq "no") {
        print "Exiting Script...\n";
        exit 2;
        }


#---------------------------------------------
# Remote Host OS Type & IP Address Check
#---------------------------------------------


foreach $server (`cat $host_list`) {
        chomp($server);
        &ip_os_remote_query ($username, $password, $server, $timeout);
}


# Parsing out relevant entries in the Query File and formatting them in readable format in the Results File.
my $final_results = system("cat $ip_os_query_file | grep '>' | cut -d'>' -f2 | cut -c 2-300 > $ip_os_results_file");


# Verifying that the entries in the Query File were transferred to the Results File and then exiting the script.
my $results_check = `cat $ip_os_results_file | wc -l`;


if ($results_check < 1 ) {
        warn "\nThere were NO Results written to the [ip_os_results.txt] file.\n";
        exit 0;
}
elsif ($results_check >= 1 ) {
        warn "\nFinal Results are available in the [ip_os_results.txt] file.\n";
        exit 2;
}


#---------------------------------------------
# END Runtime
#---------------------------------------------


#---------------------------------------------
# Subroutines
#---------------------------------------------


sub verify_ready_to_run () {
        if (-e $host_list) {
                system("cat $host_list\n");
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
                print "Check to see if [hosts.txt] is available or if the script lists a different file in the [\$host_list] variable.\n";
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


        # Enabling STDOUT Logging which will redirect the results of the script to the 'ip_os_query_file'
        # for additional parsing later.
        $stats_exp->log_stdout(1);
        $stats_exp->log_file($ip_os_query_file);


        # Spawning SSH Session to Remote Host.
        $stats_exp->spawn("$ssh $username\@$server") or die "Cannot spawn ssh: $!\n";

        # Running Expect Function.
        $stats_exp->expect($timeout,

        # SSH - Add Key From Remote Host Prompt.
        [qr'\(yes/no\)\s*'         , sub {my $exph = shift;
                                     print $exph "yes\n";
                                     exp_continue; }],

        # SSH Password Prompt.
        [qr'word:\s*'              , sub {my $action = shift;
                                     $action->send("$password\n");
                                     exp_continue; }],

        # Query the OS Type and IP Address of the Remote Host.
        [qr'login:\s*'             , sub {my $action = shift;
                                     my $os_type = "`cat /etc/redhat-release`";
                                     my $ip_addr = "`/sbin/ifconfig | perl -nle '/dr:(\\S+)/ && print \$1' | grep -v 127.0.0.1`";
                                     $action->send("printf \"$server;$os_type;$ip_addr\n \" ");
                                     exp_continue; }],

        # Query the OS Type and IP Address of the Remote Host.
        # This option is used if the user account running the script has never logged into the Host before.
        [qr'Creating directory\s*' , sub {my $action = shift;
                                     my $os_type = "`cat /etc/redhat-release`";
                                     my $ip_addr = "`/sbin/ifconfig | perl -nle '/dr:(\\S+)/ && print \$1' | grep -v 127.0.0.1`";
                                     $action->send("printf \"$server;$os_type;$ip_addr\n \" ");
                                     exp_continue; }],

        # Exit out of the Remote Host.
        [$prompt                   , sub {my $action = shift;
                                     $action->send("exit\n");
                                     exp_continue; }],

        # Send Notification that the Query was Successful.
        [qr'logout\s*'            => sub {warn "Stats Successfully Retrieved for $server!\n";
                                     exp_continue; }],

        # Exception Handling subroutines are below. All Errors are treated with 'warn' instead of 'die' to ensure that
        # the Script keeps running for the the rest of the Servers in the Hosts.txt file.

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


#----------------------------------------------
# END of Script
#----------------------------------------------
