#!/usr/bin/perl
#
#  --- [yum_remote_install] Perl Script  ---
#
# Author(s):     Ryan Irujo
# Inception:     01.14.2013
# Last Modified: 01.17.2013
#
# Description:   Script that queries a specified RPM (or RPMs) on a set of Servers (read from a text file) and
#                does the following:
#
#  		 1. Remove older RPMs specified in the '$check_for_retired_rpms' variable.
#		 2. Removes any instances of the new or different RPM specified in the '$check_for_updated_rpm' variable.
#		 3. Installs/Reinstalls a new or different RPM specified in the '$install_updated_rpm' variable.
#
#                Add of all of the Servers you would like to query into a single column in a file named 'servers.txt'.
#                You can rename the text file by specifying a different name in the '$server_list' variable below.
#                The Script will prompt for a username and password to use for logging into the remote Servers
#                as soon as you run it.
#
#
# Changes:       1.17.2012 - [R. Irujo]
#                - Added ReadKey Module in order to hide username and password credentials passed to the script
#                  from the terminal.
#
#
# Syntax:        ./yum_remote_install
#
# Command Line:  ./yum_remote_install

use warnings;
use Expect;
use Term::ReadKey;


#--------------------------------------------------------------
# Main Variables
#--------------------------------------------------------------

my $scp                    = "/usr/bin/scp";
my $ssh                    = "/usr/bin/ssh";
my $host_list              = "servers.txt";
my $log_file               = "yum_remote_install_log.txt";
my $results_file           = "yum_remote_install_results.txt";
my $timeout                = 10;
my $check_for_retired_rpms = "rpm -qa | grep [rpm_package_name] && echo RETIRED_RPMs found - Removing... || echo Retired RPM Check = Pass";
my $remove_retired_rpms    = "sudo /bin/rpm -e [rpm_package_name] && echo REMOVED || echo CONTINUE...";
my $check_for_updated_rpm  = "rpm -qa | grep [rpm_package_name] && echo UPDATED RPMs found - Removing... || echo Updated RPM NOT FOUND!";
my $remove_updated_rpm     = "sudo /bin/rpm -e [rpm_package_name] && echo UNINSTALLED || echo CONTINUE...";
my $install_updated_rpm    = "sudo /usr/bin/yum install [rpm_package_name]";


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

if (-e $log_file) {
        system("rm ./$log_file");
        if ($? == 0) {
                print "\n$log_file found. Deleting it.\n";
                system("touch ./$log_file");
                if ($? == 0) {
                        print "New $log_file created successfully.\n";
                }
                elsif ($? != 0) {
                print "There was a problem creating the $log_file\n";
                exit 2;
                }
        }
}
else {
        system("touch ./$log_file");
        if ($? == 0) {
                print "\nNew $log_file created successfully.\n";
        }
        elsif ($? != 0) {
                print "There was a problem creating the $log_file.\n";
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


#--------------------------------------------------------------
# Remote Installation of RPM
#--------------------------------------------------------------


foreach $server (`cat ./$server_list`){
        chomp($server);
        &yum_remote_install ($scp, $username, $password, $server, $timeout);
}

# Parsing out relevant entries in the Query File and formatting them in readable format in the Results File.
my $final_results = system("cat ./$query_file | grep '>' | cut -d'>' -f2 | cut -c 2-300 > ./$results_file");


# Verifying that the entries in the Query File were transferred to the Results File and then exiting the script.
my $results_check = `cat ./$results_file | wc -l`;


if ($results_check < 1 ) {
        warn "\nThere were NO Results written to the [$results_file] file.\n";
        exit 0;
}
elsif ($results_check >= 1 ) {
        warn "\nFinal Results are available in the [$results_file] file.\n";
        exit 2;
}


#--------------------------------------------------------------
# Subroutines
#--------------------------------------------------------------

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


sub yum_remote_install (){

my $scp       = shift;
my $username  = shift;
my $password  = shift;
my $server    = shift;
my $timeout   = shift;
my $prompt    = '\$\s*';


        # Creating new Expect Instance.
        my $rpm_exp = new Expect;

        # This sets Expect to not be so verbose on the output to the terminal. You can comment this
        # out if you want to see all of the raw output.
        $rpm_exp->raw_pty(1);

		
        # Enabling STDOUT Logging which will redirect the results of the script to the Query File.
        # for additional parsing later.
        $stats_exp->log_stdout(1);
        $stats_exp->log_file($log_file);


        # Spawning SSH Session to Remote Host.
        $rpm_exp->spawn("$ssh $username\@$server") or die "Cannot spawn ssh: $!\n";


        # Running Expect Function.
        $rpm_exp->expect($timeout,

        # SSH - Add Key From Remote Host Prompt.
        [qr'\(yes/no\)\s*'    , sub {my $exph = shift;
                                print $exph "yes\n";
                                exp_continue; }],

        # SSH Password Prompt.
        [qr'word:\s*'         , sub {my $action = shift;
                                $action->send("$password\n");
                                exp_continue; }],

        # Check for Retired RPM Packages.
        [qr'login:\s*'        , sub {my $action = shift;
                                $action->send("$check_for_retired_rpms\n");
                                exp_continue; }],

        # Check for Retired RPM Packages. This Occurs if the user account used to run this script
        # has never logged into the Host before.
        [qr'Creating directory\s*' , sub {my $action = shift;
                                     $action->send("$check_for_retired_rpms\n");
                                     exp_continue; }],

        # Remove Retired RPM Packages.
        [qr'RETIRED_RPMs\s*'  , sub {my $action = shift;
                                $action->send("$remove_retired_rpms\n");
                                exp_continue; }],

        # Check for Updated RPM Package.
        [qr'Retired\s*'       , sub {my $action = shift;
                                $action->send("$check_for_updated_rpm\n");
                                exp_continue; }],

        # Remove Updated RPM Package.
        [qr'UPDATED\s*'       , sub {my $action = shift;
                                $action->send("$remove_updated_rpm\n");
                                exp_continue; }],

        # Installing new RPM Package and Dependencies if required - POST Retired RPM Check.
        [qr'CONTINUE\s*'      , sub {my $action = shift;
                                $action->send("$install_updated_rpm\n");
                                exp_continue; }],

        # Installing new RPM Package and Dependencies if required - POST Updated RPM Check.
        [qr'RPM NOT FOUND\s*' , sub {my $action = shift;
                                $action->send("$install_updated_rpm\n");
                                exp_continue; }],

        # Installing new RPM Package and Dependencies if required - POST Retired RPMs Uninstall.
        [qr'REMOVED\s*'       , sub {my $action = shift;
                                $action->send("$install_updated_rpm\n");
                                exp_continue; }],

        # Installing new RPM Package and Dependencies if required - POST Updated RPM Uninstall.
        [qr'UNINSTALLED\s*'   , sub {my $action = shift;
                                $action->send("$install_updated_rpm\n");
                                exp_continue; }],

        # Responding with 'Yes' to yum installation prompt.
        [qr'\[y/N\]:\s*'      , sub {my $action = shift;
                                print $action "y\n";
                                exp_continue; }],

        # Exit out of Server once RPM Installation is Complete.
        [qr'Complete\s*'      , sub {my $action = shift;
                                $action->send("exit\n");
                                exp_continue; }],

        # Exit Send Notification that Installation was successful to Terminal.
        [qr'logout\s*' => sub {warn "[rpm_package_name] Installation on $server was Successful!.\n";
                                exp_continue; }],


        # Exception Handling subroutines are below. All Errors are treated with 'warn' instead of 'die' to ensure that
        # the Script keeps running for the the rest of the Servers in the Hosts.txt file.
        # [qr'dependencies:\s*' => sub {warn "Unable to Install $lfile on $server due to missing RPM Dependencies.\n";}],
        # [qr'Sorry\s*'         => sub {warn "Unable to Install $lfile on $server.\n";}],
        [qr'IOError\s*'                => sub {warn "Unable to Install RPM as $server is currently in Read-Only Mode.\n";}],
        [qr'OSError\s*'                => sub {warn "Unable to Install RPM as $server is currently in Read-Only Mode.\n";}],
        [qr'incident will be reported' => sub {warn "$username does not have sudo rights on $server.\n";}],
        [qr'Nothing to do'             => sub {warn "RPM Packages are missing from the Repository that $server is using.\n";}],
        [qr'key ID 6b8d79e6'           => sub {warn "The RPM key for perl-Crypt-DES-2.05-3.2.el5.rf.x86_64.rpm is missing on $server.\n";}],
        [EOF                           => sub {warn "Error: Could not login!\n"; }],
        [timeout                       => sub {warn "Error: Could not login!\n"; }],
        $prompt,);

}


#------------------
# END of Script
#------------------
