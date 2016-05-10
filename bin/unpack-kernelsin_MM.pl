#!/usr/bin/perl -W

#
# DooMLoRD modified unpack-bootimg.pl script for Sony/SEMC devices
#
# Info:
# this will unpack kernel.sin to zImage and ramdisk
#
# Supported Devices:
# Xperia devices with Marshmallow firmware

use strict;
use bytes;
use File::Path;

print "\n DooMLoRD modified unpack-bootimg.pl script for Sony/SEMC devices\n";
print "\n Info:\n";
print " this will unpack kernel.sin to zImage and ramdisk\n";
print "\n";
print "\n Supported Devices:\n";
print " Xperia devices with Marshmallow firmware\n";

die "did not specify kernel sin file\n" unless $ARGV[0];

my $kernelsinfile = $ARGV[0];

my $slurpvar = $/;
undef $/;
open (KERNELSINFILE, "$kernelsinfile") or die "could not open boot img file: $kernelsinfile\n";
my $kernelsin = <KERNELSINFILE>;
close KERNELSINFILE;
$/ = $slurpvar;

# chop off the header
$kernelsin =~ /(.*\x00\x00\x00\x00)(\x00\x00\xA0\xE1\x00\x00\xA0\xE1\x00\x00\xA0\xE1\x00\x00\xA0\xE1\x00\x00\xA0\xE1\x00\x00\xA0\xE1\x00\x00\xA0\xE1\x00\x00\xA0\xE1.*)/s;

my $header = $1;
my $bootimg = $2;

open (HEADERFILE, ">$ARGV[0]-header");
print HEADERFILE $header or die;
close HEADERFILE;


# we'll check how many ramdisks are embedded in this image
my $numfiles = 0;

# we look for the hex 1F 8B 08 00 We only look for this number which is the start of a gziped ramdisk
while ($bootimg =~ m/\x1F\x8B\x08\x00/g) {
	$numfiles++;
}

if ($numfiles == 0) {
	die "Could not find any embedded ramdisk images. Are you sure this is a full boot image?\n";
} elsif ($numfiles > 1) {
	die "Found a secondary file after the ramdisk image.  According to the spec (mkbootimg.h) this file can exist, but this script is not designed to deal with this scenario.\n";
}

# split kernel+ramdisk with tail
$bootimg =~ /(.*)(\x1F\x8B\x08\x00.*)/s;

my $kernel = $1;
my $ramdisk_dtimg = $2;

open (KERNELFILE, ">$ARGV[0]-kernel");
print KERNELFILE $kernel or die;
close KERNELFILE;

print "\nkernel written to $ARGV[0]-kernel\n";

# search for dt.img
my $dtimgfound = 0;
while ($ramdisk_dtimg=~ /\x51\x43\x44\x54/g) {
 $dtimgfound=1;
}

my $final_ramdisk; # = $ramdisk_dtimg;

if ($dtimgfound == 1) {

print "FOUND dt.img\n";

# spliting ramdisk & dt.img
$ramdisk_dtimg=~ /(.*\x00)(\x51\x43\x44\x54.*)/s;

$final_ramdisk = $1;
my $dtimg_tail = $2;

# search and split for command line
$dtimg_tail=~ /(.*\x00\x00\x00\x00)(\x01\x00\x00\x00\x00\x00\xE0\x01\x61\x6E\x64\x72\x6F\x69\x64\x62.*)/s;

my $dtimg = $1;
my $final_tail = $2;

open (DTIMGFILE, ">$ARGV[0]-dt.img");
print DTIMGFILE $dtimg or die;
close DTIMGFILE;

print "\ndt.img written to $ARGV[0]-dt.img\n";


open (TAILFILE, ">$ARGV[0]-tail");
print TAILFILE $final_tail or die;
close TAILFILE;

print "\ntail written to $ARGV[0]-tail\n";


}
else {

$final_ramdisk = $ramdisk_dtimg;

}

open (RAMDISKFILE, ">$ARGV[0]-ramdisk.cpio.gz");
print RAMDISKFILE $final_ramdisk or die;
close RAMDISKFILE;

print "\nramdisk written to $ARGV[0]-ramdisk.cpio.gz\n";
if (-e "$ARGV[0]-ramdisk") { 
	rmtree "$ARGV[0]-ramdisk";
	print "\nremoved old directory $ARGV[0]-ramdisk\n";
}

mkdir "$ARGV[0]-ramdisk" or die;
chdir "$ARGV[0]-ramdisk" or die;
system ("gunzip -c ../$ARGV[0]-ramdisk.cpio.gz | cpio -i");

print "\nextracted ramdisk contents to directory $ARGV[0]-ramdisk/\n";
