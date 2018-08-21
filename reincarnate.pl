package reincarnate;
# This plugin is licensed under the GNU GPL
# Copyright 2006 by kaliwanagan
# --------------------------------------------------
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

my $charPos = 2;
my $currentCharPos = $charPos;
my $newCharName;
my ($str, $agi, $vit, $int, $dex, $luk, $hair_style, $hair_color) =
   (9   , 9   , 9   , 1   , 1   , 1   , 1          , 1          );


# State holder
my $status = "ready";

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
		print "$currentCharPos\n";
		print "$newCharName\n";
		$messageSender->sendCharCreate($charPos, $newCharName, $str, $agi, $vit, $int, $dex, $luk, $hair_style, $hair_color);
		$timeout{'charlogin'}{'time'} = time;
		$args->{return} = 2;
		$status = "character created";
		return;
	}
	if ($status eq "start") {
		message "$status\n";
		message "Deleting $currentCharPos: $chars[$currentCharPos]{name}, $email\n";
		$messageSender->sendBanCheck($charID);
		$messageSender->sendCharDelete($chars[$currentCharPos]{charID}, $email);
		$timeout{'charlogin'}{'time'} = time;
		$args->{return} = 2;
		$status = "character deleted";
	} elsif ($status eq "character deleted") {
		message "$status\n";
		message "Creating $currentCharPos: $newCharName, $email\n";
		$messageSender->sendCharCreate($currentCharPos, $newCharName, $str, $agi, $vit, $int, $dex, $luk, $hair_style, $hair_color);
		$timeout{'charlogin'}{'time'} = time;
		$args->{return} = 2;
		$status = "character created";
	} elsif ($status eq "character created") {
		message "$status\n";
		$messageSender->sendCharLogin($currentCharPos);
		$timeout{'charlogin'}{'time'} = time;
		$args->{return} = 1;
		configModify("char", $currentCharPos);
		$status = "ready";
		Commands::run("reload macros");
	}
}
sub reincarnate_command {
	# Save the slot position of the current character
	$currentCharPos = $config{char};
	# Alternatively, you can replace $newCharName with
	# some sort of "name generator"
	# $newCharName = $chars[$config{char}]{name};
	#$newCharName = Utils::vocalString(15);
	$newCharName = generateName(int(rand(2)) + 4, int(rand(2)) + 4);
	$hair_color = int(rand(12));
	$hair_style = int(rand(12)) + 2;
	print "$hair_color, $hair_style\n";
	print "New name: $newCharName\n";
	message "Reincarnating $chars[$config{char}]{name}\n", "system";
	$status = "start";
	$messageSender->sendQuitToCharSelect();
	# configModify("char", "");
	# relog();
}
sub quitToCharSelect_command {
	$messageSender->sendQuitToCharSelect();
}
# string generateName (lengthS [, lengthF])
# Generate a name with lengthS syllables as a surname.
# The second argment is optional - it will be used when
# you want a forename to be generated as well.
# The syllables are from Old Japanese.
# http://en.wikipedia.org/wiki/Old_Japanese_language
#
# Returns:
# A string containing the surname and the optional
# forename, separated by spaces, and the first character
# of both names capitalized.
#
# Example:
#
# print generateName(4, 4)
# Watanabe Sakamoto
#
# TODO:
# Implement phonological rukes as described by the wikipedia entry
# Implement vowel ellisions as described by the wikipedia entry
sub generateName {
	my $lengthS = shift;
	return "" if (!$lengthS);
	my $lengthF = shift;
	my $surname = "";
	# my $forename = "";
	# Generate the surname
	if ($lengthS) {
		my $i;
		for ($i = 0; $i < $lengthS; $i++) {
			my $syllable = "";
			while (!$syllable) {
				my $candidate = $syllables[int(rand(@syllables))];
				# Do some testing with $candidate here
				$syllable = $candidate;
			}
			$surname .= $syllable;
		}
		$surname = ucfirst($surname);
	}
	# Generate the forename
	# if ($lengthF) {
	#    my $i;
	#    for ($i = 0; $i < $lengthF; $i++) {
	#       my $syllable = "";
	#       while (!$syllable) {
	#          my $candidate = $syllables[int(rand(@syllables))];
	#          # Do some testing with $candidate here
	#          $syllable = $candidate;
	#       }
	#       $forename .= $syllable;
	#    }
	#    $forename = ucfirst($forename);
	# }
	my $name = $surname;
	# $name .= " " . $forename if ($forename);
	return $name;
}
return 1;
