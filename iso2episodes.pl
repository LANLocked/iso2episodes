#/usr/bin/perl -w
use Data::Dumper;

if (@ARGV == undef) {
print <<USAGE;
Usage: iso2episodes.pl <filename> 

Edit script to change subtitles options, encoding profiles, ....

DESCRIPTION

Ever encountered the situation where you wanted to download some episodes but all you could find were ISO images?
This script will take an iso, use the lsdvd util to turn its info into a perl data structure and then use the CLI version
of HandBrake to encode the tracks longer than $minepisodelengthminutes. You can specify multiple HandBrake encoding profiles
in the config section, as well as multiple subtitle languages to include as subtitle tracks in the mp4.

DEPENDENCIES:

lsdvd ->

$ sudo apt-get install lsdvd

HandBrakeCLI ->

Download from site, compile from source...

USAGE

exit;
}

### Config section ####
#my @encoding_profiles = ("High Profile","Android Mid","Normal");
my @encoding_profiles = ("Android Mid");
my %wanted_subs_language = map {$_,1} ("Nederlands","English");
my $handbrake = `which HandBrakeCLI`;
chomp $handbrake;
#my @handbrakeoptions = ('-N nld');

my $minepisodelengthminutes = 20;  # minimum episode length in minutes..any track longer than this will be encoded

########### End Config section  ###########

my $filename = shift @ARGV;
chomp($filename);
print "Selected filename:",$filename,"\n";
print "Handbrake location:",$handbrake,"\n";

my $dvdinfo = `lsdvd -a -s -Op $filename`;
eval $dvdinfo;

if ($@) {
    print $@;
    }
else {
@selected_tracks = ();
%selected_subp_tracks;
foreach $track (@{$lsdvd{'track'}}) {
	print "Track ID:", $track->{'ix'}," Length:",$track->{'length'};	
	print "    ----> Minutes:",$track->{'length'}/60;
	if ($track->{'length'}/60 > $minepisodelengthminutes){ 
		print " (Selected)","\n";	
		push @selected_tracks, $track->{'ix'};
		my $tracknr = $track->{'ix'};
	foreach $subp (@{$track->{'subp'}}) {
		print "\t\tSubtitle language:",$subp->{'language'};
			if ($wanted_subs_language{$subp->{'language'}}) {
			print " (Selected) Index:",$subp->{'ix'},"\n";
						
			$selected_subp_tracks{"t$tracknr"}->{$subp->{'language'}} = $subp->{'ix'} unless $selected_subp_tracks{"t$tracknr"}->{$subp->{'language'}};
			}
			else {
			print "\n";
			}
		}
	}
	print "\n";
	}
}
print "Selected tracks: ", @selected_tracks, "\n";

#print Dumper(\%selected_subp_tracks);

foreach $tracknr (@selected_tracks) {
	my @subtracks;
	foreach $langtrack (keys %{$selected_subp_tracks{"t$tracknr"}})
	{
#	print "Language subtitle track: ",$selected_subp_tracks{"t$tracknr"}," ",$selected_subp_tracks{"t$tracknr"}{$langtrack},"\n";
	push @subtracks, $selected_subp_tracks{"t$tracknr"}{$langtrack};
	}
	my $subtracks = join(',',@subtracks);
	print "Subtracks: ", $subtracks,"\n";
    foreach $encprof (@encoding_profiles) {
	$profilemidfix = lc($encprof);
	$profilemidfix =~ s/ //g;
	#print $profilemidfix,"\n";
#	print @{$selected_subp_tracks{t$tracknr}};
	system("$handbrake -i $filename -o $filename.Title$tracknr.$profilemidfix.mp4 -s $subtracks -Z \"$encprof\"");
	}
    }
