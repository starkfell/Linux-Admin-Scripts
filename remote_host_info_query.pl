#!/usr/bin/perl
#
#  --- [remote_host_info_query] Perl Script  ---
#
# Author(s):     Ryan Irujo
# Inception:     01.14.2013
# Last Modified: 01.14.2013
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
# Syntax 1:      ./remote_host_info_query [Username] [Password] > [text_file_for_full_results]
# Syntax 2:      ./remote_host_info_query [Username] [Password]
#
# Command Line:  ./remote_host_info_query username P@wer89d! > results.txt


use warnings;
use Expect;

#--------------------------------------------------------------
# Main Variables
#--------------------------------------------------------------

my $scp                    = "/usr/bin/scp";
my $ssh                    = "/usr/bin/ssh";
my $host_list              = "./hosts.txt";
my $user                   = $ARGV[0];
my $password               = $ARGV[1];
my $timeout                = 10;

my $ip_query = `/sbin/ifconfig | perl -nle '/dr:(\\S+)/ && print \$1' | grep -v 127.0.0.1`;
my $os_query = `cat /etc/redhat-release`;

chomp($ip_query);
chomp($os_query);


if (!defined $user || $user eq ""){
        print "A [Username] must be provided.\n";exit 3;
        }
if (!defined $password || $password eq ""){
        print "A [Password] must be provided.\n";exit 3;
        }


#--------------------------------------------------------------
# Remote Installation of RPM
#--------------------------------------------------------------


foreach $server (`cat $host_list`){
        chomp($server);
        &yum_remote_query ($scp, $user, $password, $server, $timeout);
}


exit 0;




#--------------------------------------------------------------
# Subroutines
#--------------------------------------------------------------


sub yum_remote_query (){

my $scp       = shift;
my $user      = shift;
my $password  = shift;
my $server    = shift;
my $localpath = shift;
my $timeout   = shift;
my $prompt    = '\$\s*';


        # Creating new Expect Instance.
        my $rpm_exp = new Expect;

        # This sets Expect to not be so verbose on the output to the terminal. You can comment this
        # out if you want to see all of the raw output.
        $rpm_exp->raw_pty(1);


        # Spawning SSH Session to Remote Host.
        $rpm_exp->spawn("$ssh $user\@$server") or die "Cannot spawn ssh: $!\n";


        # Running Expect Function.
        $rpm_exp->expect($timeout,

        # SSH - Add Key From Remote Host Prompt.
        [qr'\(yes/no\)\s*'         , sub {my $exph = shift;
                                     print $exph "yes\n";
                                     exp_continue; }],

        # SSH Password Prompt.
        [qr'word:\s*'              , sub {my $action = shift;
                                     $action->send("$password\n");
                                     exp_continue; }],

        # Check for the First RPM Key.
        [qr'login:\s*'             , sub {my $action = shift;
                                     print "$server - $ip_query - $os_query - Successfully Retrieved!\n";
                                     exp_continue; }],

        # Exit out of the Server if the Second RPM Key was added.
        [$prompt                   , sub {my $action = shift;
                                     $action->send("exit\n");
                                     exp_continue; }],

        # Send Notification that RPM Key Check on the Server is Complete.
        [qr'logout\s*'            => sub {warn "$server - $ip_query - $os_query - Successfully Retrieved!\n";
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

}


