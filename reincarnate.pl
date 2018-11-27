# This plugin is licensed under the GNU GPL
# Copyright 2006 by kaliwanagan
#           2018 by brand
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

my $plugin = Plugins::addHooks(
    ['charSelectScreen', \&charSelectScreen]
);
my $command = Commands::register(
    ['reincarnate', 'delete then (re)create your char', \&onCommand]
);

my $action;
my ($str, $agi, $vit, $int, $dex, $luk) =
   (9   , 9   , 9   , 1   , 1   , 1   );

sub onUnload {
    Commands::unregister($command);
    Plugins::delHooks($plugin);
}
sub onCommand {
    $action = "delete char";
    $messageSender->sendQuitToCharSelect();
}

sub charSelectScreen {
    my ($self, $args) = @_;
    if (!$chars[$config{char}]) {
        $args->{return} = createCharacter();
    }
    if(!defined $action) {
        return;
    }
    else {
        print "Action: $action\n";
        if ($action eq "delete char") {
            $messageSender->sendBanCheck($charID);
            $messageSender->sendCharDelete($chars[$config{char}]{charID}, $config{email});
            $args->{return} = 2;
            $action = "create char";
        }
        elsif ($action eq "create char") {
            $args->{return} = createCharacter();
            $action = "log char";
        }
        elsif ($action eq "log char") {
            $messageSender->sendCharLogin($config{char});
            $args->{return} = 1;
        }
    }
    $timeout{'charlogin'}{'time'} = time;
}

sub createCharacter {
    my $name = generateName(int(rand(2)) + 4, int(rand(2)) + 4);
    my $hair_color = int(rand(12));
    my $hair_style = int(rand(12)) + 2;
    $messageSender->sendCharCreate($config{char}, $name, $str, $agi, $vit, $int, $dex, $luk, $hair_style, $hair_color);
    return 2
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
