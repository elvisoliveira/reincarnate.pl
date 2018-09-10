# This plugin is licensed under the GNU GPL
# Copyright 2006 by kaliwanagan
# --------------------------------------------------
package reincarnate;

my @syllables = qw(  a  i  u  e  o
                    ka ki ku ke ko
                    ga gi gu ge go 
                    sa si su se so
                    za zi zu ze zo
                    ta ti tu te to
                    da di du de do
                    na ni nu ne no n
                    ha hi hu he ho
                    ba bi bu be bo
                    ma mi mu me mo
                    ya    yu ye yo
                    ra ri ru re ro
                    wa wi    we wo);

use strict;
use Plugins;
use Globals;
use Log qw(message warning error debug);
use AI;
use Misc;
use Network;
use Network::Send;
use Utils;

Plugins::register('reincarnate', 'automatically delete then (re)create your char', \&onUnload);

my $plugin = Plugins::addHooks(['charSelectScreen', \&charSelectScreen]);
my $command1 = Commands::register(['reincarnate', 'delete then (re)create your char', \&reincarnate_command]);
my $command2 = Commands::register(['quitToCharSelect', 'quits to char select screen', \&quitToCharSelect_command]);

my $status = "ready";
my $charPos = 2;
my $newCharName;
my $currentCharPos = $charPos;
my ($str, $agi, $vit, $int, $dex, $luk, $hair_style, $hair_color) =
   (9   , 9   , 9   , 1   , 1   , 1   , 1          , 1          );

sub onUnload {
    Commands::unregister($command1);
    Commands::unregister($command2);
    Plugins::delHooks($plugin);
}
sub charSelectScreen {
    my $email = $config{email};
    my ($self, $args) = @_;
    if (!$chars[$charPos]) {
        $config{char} = $charPos;
        $newCharName = generateName(int(rand(2)) + 4, int(rand(2)) + 4);
        $messageSender->sendCharCreate($charPos, $newCharName, $str, $agi, $vit, $int, $dex, $luk, $hair_style, $hair_color);
        $timeout{'charlogin'}{'time'} = time;
        $args->{return} = 2;
        $status = "character created";
        return;
    }
    if ($status eq "start") {
        $messageSender->sendBanCheck($charID);
        $messageSender->sendCharDelete($chars[$currentCharPos]{charID}, $email);
        $timeout{'charlogin'}{'time'} = time;
        $args->{return} = 2;
        $status = "character deleted";
    } elsif ($status eq "character deleted") {
        $messageSender->sendCharCreate($currentCharPos, $newCharName, $str, $agi, $vit, $int, $dex, $luk, $hair_style, $hair_color);
        $timeout{'charlogin'}{'time'} = time;
        $args->{return} = 2;
        $status = "character created";
    } elsif ($status eq "character created") {
        $messageSender->sendCharLogin($currentCharPos);
        $timeout{'charlogin'}{'time'} = time;
        $args->{return} = 1;
        configModify("char", $currentCharPos);
        $status = "ready";
        # Commands::run("reload macros");
    }
}
sub reincarnate_command {
    $currentCharPos = $config{char};
    $newCharName = generateName(int(rand(2)) + 4, int(rand(2)) + 4);
    $hair_color = int(rand(12));
    $hair_style = int(rand(12)) + 2;
    print "$hair_color, $hair_style\n";
    print "New name: $newCharName\n";
    $status = "start";
    $messageSender->sendQuitToCharSelect();
}
sub quitToCharSelect_command {
    $messageSender->sendQuitToCharSelect();
}
sub generateName {
    my $lengthS = shift;
    return "" if (!$lengthS);
    my $lengthF = shift;
    my $surname = "";
    if ($lengthS) {
        my $i;
        for ($i = 0; $i < $lengthS; $i++) {
            my $syllable = "";
            while (!$syllable) {
                my $candidate = $syllables[int(rand(@syllables))];
                $syllable = $candidate;
            }
            $surname .= $syllable;
        }
        $surname = ucfirst($surname);
    }
    my $name = $surname;
    return $name;
}
return 1;
