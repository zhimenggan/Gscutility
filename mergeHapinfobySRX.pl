#!/usr/bin/perl -w

# A perl script to build config file for SRS Bam Merge
# Contact: Shihcheng.Guo@Gmail.com
# Version 1.3
# Go to http://sra.dnanexus.com/studies/SRP028600/samples
# Select SRS and Click Related RUNS then get the Table as the input

use strict;
use warnings;
use Cwd;

my $file=shift @ARGV;
my %SRA;
open F,$file;
while(<F>){
chomp;
if(/(SRR\d+)/){
	my $SRR=$1;
	if(/(SRX\d+)/){
		my $SRX=$1;
		print "$SRR\t$SRX\n";
		push @{$SRA{$SRX}},$SRR;
		}
	}
}

system("rm ../mergeHapinfo/*hapinfo.txt");


foreach my $SRX(sort keys %SRA){
        foreach my $SRR (@{$SRA{$SRX}}){
        system("cat $SRR*.hapInfo.txt >> ../mergeHapinfo/$SRX.hapinfo.txt");
        }
        print "\n";
}
