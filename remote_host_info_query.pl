#!/usr/bin/perl
#
#  --- [remote_host_info_query] Perl Script  ---
#
# Author(s):     Ryan Irujo
# Inception:     01.14.2013
# Last Modified: 01.15.2013
#
# Description:   Script that queries the IP Address and OS Type on a set of hosts (read from a text file). Simply type in the name
#                of all of the Hosts you would like to query in same directory as this script is in and make sure
#                that it is named 'hosts.txt'. Additionally, you can rename the text file by specifying a different
#                name in the '$host_list' variable below. Note that using Syntax 1 cause less noise to appear in the
#                Terminal Window, but provides the exact same results as Syntax 2.
#
#
# Changes:
#
#
# Syntax 1:      ./remote_host_info_query [Username] [Password] > [ip_os_query_file]
#
# Command Line:  ./remote_host_info_query username P@wer89d! > ip_os_query.txt


use warnings;
use Expect;

#--------------------------------------------------------------
# Main Variables
#--------------------------------------------------------------

my $ssh                    = "/usr/bin/ssh";
my $host_list              = "./hosts.txt";
my $user                   = $ARGV[0];
my $password               = $ARGV[1];
my $timeout                = 10;
my $ip_os_query_file       = "./ip_os_query.txt";
my $ip_os_results_file     = "./ip_os_results.txt";


if (!defined $user || $user eq ""){
        print "A [Username] must be provided.\n";exit 3;
        }
if (!defined $password || $password eq ""){
        print "A [Password] must be provided.\n";exit 3;
        }

if (-e $ip_os_query_file) {
        print "$ip_os_query_file file already exists.\n";
        }
else {
        system(`touch $ip_os_query_file`);
        print "$ip_os_query_file file created.\n";
        }

if (-e $ip_os_results_file) {
        print "$ip_os_results_file already exists.\n";
        }
else {
        system(`touch $ip_os_results_file`);
        print "$ip_os_results_file file created.\n";
        }


#--------------------------------------------------------------
# Remote Host OS Type & IP Address Check
#--------------------------------------------------------------


foreach $server (`cat $host_list`){
        chomp($server);
        &ip_os_remote_query ($user, $password, $server, $timeout);
}

my $final_results = system(`cat $ip_os_query_file | grep ">" | cut -d'>' -f2 | cut -c 2-300 > $ip_os_results_file`);
my $results_check = `cat $ip_os_results_file | wc -l`;


if ($results_check < 1 ) {
        warn "There were NO Results written to the [ip_os_results.txt] file.\n";
        exit 0;
}
elsif ($results_check >= 1 ) {
        warn "Final Results are available in the [ip_os_results.txt] file.\n";
        exit 2;
}


#--------------------------------------------------------------
# Subroutines
#--------------------------------------------------------------


sub ip_os_remote_query (){

my $user      = shift;
my $password  = shift;
my $server    = shift;
my $timeout   = shift;
my $prompt    = '\$\s*';


        # Creating new Expect Instance.
        my $stats_exp = new Expect;

        # This sets Expect to not be so verbose on the output to the terminal. You can comment this
        # out if you want to see all of the raw output.
        $stats_exp->raw_pty(1);


        # Spawning SSH Session to Remote Host.
        $stats_exp->spawn("$ssh $user\@$server") or die "Cannot spawn ssh: $!\n";

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
        [qr'incident will be reported'         => sub {warn "$user does not have sudo rights on $server.\n";}],
        [qr'IOError\s*'                        => sub {warn "Something went wrong while querying $server.\n";}],
        [qr'OSError\s*'                        => sub {warn "Something went wrong while querying $server.\n";}],
        [EOF                                   => sub {warn "Error: Could not login!\n"; }],
        [timeout                               => sub {warn "Error: Could not login!\n"; }],
        $prompt,);

        # End Expect Function
        $stats_exp->soft_close();

}


#--------------------------------------------------------------
# END!
#--------------------------------------------------------------
