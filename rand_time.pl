#!/usr/bin/perl
my $sleep_var = 600 ;
my $sleep_base = 600 ; 

## Do forever with 15 min random delay
## That means ca 4 x hour \approx 100 per 24 hrs
while (1) {
   my $runTask = `perl flickr_photo_recent.pl`;
   sleep (int(rand($sleep_var )) + $sleep_base);

}

