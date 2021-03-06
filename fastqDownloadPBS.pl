#!/usr/bin/perl -w
# This is most complicated situation for RRBS or BS alignment since both single end and pair-end fastq were created in a project.
# Run the script to the Bam directory of the bismark
# Contact: Shicheng Guo
# Version 1.3
# Update: Jan/19/2016

use strict;
use Cwd;
my $dir=getcwd;

die "\n-----------------------------------------------------------------------\n
Usage: perl $0 SamConfig.txt submit\n

The script will catch the SRR ID from SamConfig.txt files and then creat downlad bash.
SamConfig.txt: Please Download SamConfig from http://www.ebi.ac.uk/ena/data/view/SRP028600
-----------------------------------------------------------------------------\n\n" if scalar(@ARGV<2);

my $sraFiles=shift @ARGV;
my $submit=shift @ARGV;
my $project="Fastq";
my $analysis="";
my $ppn=1;
my $walltime="168:00:00";
my $queue="hotel"; # hotel

open F,$sraFiles;
while(<F>){
    chomp;
    next if /SRRID|ID/;
    next if /^\s+$/;
    if(/(SRR\d+)/){
    my $id=$1;
    # next if -e "$id.fastq.gz"; # SRR1035764.fastq.gz
    my $job_file_name = $id . ".fastq.download.job";
    my $status_file = $id.".status";
    my $curr_dir = $dir;
    open(OUT, ">$job_file_name") || die("Error in opening file $job_file_name.\n");
    print OUT "#!/bin/csh\n";
    print OUT "#PBS -N $job_file_name\n";
    print OUT "#PBS -q $queue\n";  # glean is free, pdafm
    print OUT "#PBS -l nodes=1:ppn=$ppn\n";
    print OUT "#PBS -l walltime=$walltime\n";
    print OUT "#PBS -o ".$id.".download.log\n";
    print OUT "#PBS -e ".$id.".download.err\n";
    print OUT "#PBS -V\n";
    print OUT "#PBS -M shihcheng.guo\@gmail.com \n";
    print OUT "#PBS -m abe\n";
    print OUT "#PBS -A k4zhang-group\n";
    print OUT "cd $curr_dir\n";
    print OUT "fastq-dump --split-files --gzip $id\n";    
    close(OUT);
    if($submit eq 'submit'){
    system("qsub $job_file_name");
   }
}
}


