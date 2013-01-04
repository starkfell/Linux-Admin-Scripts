#!/usr/bin/perl
#
# Used As a Reference Point: http://programming-in-linux.blogspot.com/2008/09/remote-scp-and-ssh-using-expect.html
#
#
#
use warnings;
use Expect;

#--------------------------------------------------------------
# Main Variables
#--------------------------------------------------------------

my $scp             = "/usr/bin/scp";
my $ssh             = "/usr/bin/ssh";
my $host_list       = "./hosts_to_modify.txt";
my $ruser           = $ARGV[0];
my $rpass           = $ARGV[1];
my $lfile           = $ARGV[2];
my $timeout         = 10;
my $remove_old_rpm  = "sudo /bin/rpm -e nrpe-plugin";
my $install_new_rpm = "sudo /bin/rpm -i $lfile";

chomp($remove_old_rpm);
chomp($install_new_rpm);


if (!defined $ruser || $ruser eq ""){
        print "A [Username] must be provided.\n";exit 3;
        }
if (!defined $rpass || $rpass eq ""){
        print "A [Password] must be provided.\n";exit 3;
        }
if (!defined $lfile || $lfile eq ""){
        print "An [RPM File] must be provided.\n";exit 3;
        }


#--------------------------------------------------------------
# Remote Installation of RPM
#--------------------------------------------------------------


foreach $rserver (`cat $host_list`){
        chomp($rserver);
        &remote_copy ($scp, $ruser, $rpass, $rserver, $lfile, $timeout);
        &remote_install ($scp, $ruser, $rpass, $rserver, $lfile, $timeout);
}


exit 0;




#--------------------------------------------------------------
# Subroutines
#--------------------------------------------------------------


sub remote_copy (){

my $scp       = shift;
my $ruser     = shift;
my $password  = shift;
my $server    = shift;
my $localpath = shift;
my $timeout   = shift;
my $prompt    = '\$\s*';

        # Creating New Expect Instance.
        my $scp_exp = new Expect;

        # Spawning new SCP Session to Remote Host.
        $scp_exp->spawn("$scp $localpath $ruser\@$server\:\.");


        # Running Expect Function.
        $scp_exp->expect(5,

        # SSH - Add Key From Remote Host Prompt.
        [qr'\(yes/no\)\s*'  , sub {my $exph = shift;
                                print $exph "yes\r";
                                exp_continue; }],

        # SSH Password prompt.
        [qr'word:\s*'       , sub {my $exph = shift;
                                print $exph "$password\r";
                                exp_continue; }],

        # Exception Handling subroutines are below.
        [EOF     => sub {die "Error: Could not login!\n"; }],
        [timeout => sub {die "Error: Could not login!\n"; }],
        '-re', '\$');

        $scp_exp->soft_close();

}


sub remote_install (){

my $scp       = shift;
my $ruser     = shift;
my $password  = shift;
my $server    = shift;
my $localpath = shift;
my $timeout   = shift;
my $prompt    = '\$\s*';


        # Creating new Expect Instance.
        my $rpm_exp = new Expect;

        # Spawning SSH Session to Remote Host.
        $rpm_exp->spawn("$ssh $ruser\@$server") or die "Cannot spawn ssh: $!\n";


        # Running Expect Function.
        $rpm_exp->expect($timeout,

        # SSH Password Prompt.
        [qr'word:\s*'       , sub {my $step_1 = shift;
                                $step_1->send("$password\n");
                                exp_continue; }],

        # Install New RPM Package.
        [qr'package\s*'     , sub {my $step_2 = shift;
                                $step_2->send("$install_new_rpm\n");
                                exp_continue; }],

        # Remove Old RPM Package.
        [qr'login:\s*'      , sub {my $step_3 = shift;
                                $step_3->send("$remove_old_rpm\n");
                                exp_continue; }],

        # Install New RPM Package after removing Previous RPM Package.
        [qr'Uninstalled\s*' , sub {my $step_4 = shift;
                                $step_4->send("$install_new_rpm\n");
                                exp_continue; }],

        # Provide Password to RPM Installation Prompt.
        [qr'icinga:\s*'     , sub {my $step_5 = shift;
                                $step_5->send("$password\n");
                                exp_continue; }],

        # Exit out of Server once RPM Installation is Complete.
        [qr'Complete\s*'    , sub {my $step_6 = shift;
                                $step_6->send("exit\n");
                                exp_continue; }],

        # Exception Handling subroutines are below.
        [qr'Sorry\s*' => sub {die "Unable to Install $lfile on $server\n.";}],
        [EOF          => sub {die "Error: Could not login!\n"; }],
        [timeout      => sub {die "Error: Could not login!\n"; }],
        $prompt,);

}
