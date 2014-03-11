#! /usr/bin/perl -w

use strict;
use File::Spec;
use Digest::MD5;

main();

sub main {
    my ($base_dir, $compared_dir) = parse_argv();
    my $base_ref = parse_dir($base_dir);
    my $compared_ref = parse_dir($compared_dir);
    my $res_ref = compare($base_ref, $compared_ref);
    format_head($base_dir, $compared_dir);
    format_out($res_ref);
    return 0;
}

sub format_head {
     my $b_dir = shift;
     my $c_dir = shift;
     printf("%-60s|%-60s\n", " ** $b_dir **", "** $c_dir **");
}

sub format_out {
    my $res_ref = shift;
    my $head = shift || "";

    for my $k (sort keys %$res_ref) {
        my $v = $res_ref->{$k};
        if (ref $v) {
            my $dir = $k;
            $dir =~ s/^d_//;
            printf("%-60s|%-60s\n", "  $head|", "$head|");
            printf("%-60s|%-60s\n", "  $head|-$dir", "$head|-$dir");
            format_out($v, $head."  ");
        }
        else {
            if ($v =~ /^d_(.*)$/) {
                my $dir = $k;
                $dir =~ s/^d_//;
                my $type = $v;
                $type =~ s/^d_//;

                if ($type eq "+") {
                    printf("%-60s|%-60s\n", "  $head|", "$head|");
                    printf("%-60s|%-60s\n", "+d$head|-$dir", "$head|-");
                }
                elsif ($type eq "-") {
                    printf("%-60s|%-60s\n", "  $head|", "$head|");
                    printf("%-60s|%-60s\n", "-d$head|-", "$head|-$dir");
                }
            }
            elsif ($v =~ /^f_(.*)$/) {
                my $file = $k;
                $file =~ s/^f_//;
                my $type = $v;
                $type =~ s/^f_//;

                if ($type eq "+") {
                    printf("%-60s|%-60s\n", "+f$head|-$file", "$head|-");
                }
                elsif ($type eq "-") {
                    printf("%-60s|%-60s\n", "-f$head|-", "$head|-$file");
                }
                elsif ($type eq "*") {
                    printf("%-60s|%-60s\n", "*f$head|-$file", "$head|-$file");
                }
                elsif ($type eq "=") {
                    printf("%-60s|%-60s\n", "=f$head|-$file", "$head|-$file");
                }
            }
        }
    }
}

sub compare {
    my $b_ref = shift;
    my $c_ref = shift;
    my %res;
    for my $k (keys %$b_ref) {

        if (ref $b_ref->{$k}) { #dir
            my $res_k = "d_".$k;
            if (exists $c_ref->{$k}) {
                $res{$res_k} = compare($b_ref->{$k}, $c_ref->{$k});
            }
            else {
                $res{$res_k} = "d_"."+";
            }
        }
        else { #file
            my $res_k = "f_".$k;
            if (exists $c_ref->{$k}) {
                if ($b_ref->{$k} eq $c_ref->{$k}) {
                    $res{$res_k} = "f_"."=";
                }
                else {
                    $res{$res_k} = "f_"."*";
                }
            }
            else {
                $res{$res_k} = "f_"."+";
            }

        }
    }

    for my $k (keys %$c_ref) {

        if (ref $c_ref->{$k}) { #dir
            my $res_k = "d_".$k;
            if (exists $b_ref->{$k}) {
            }
            else {
                $res{$res_k} = "d_"."-";
            }
        }
        else { #file
            my $res_k = "f_".$k;
            if (exists $b_ref->{$k}) {
            }
            else {
                $res{$res_k} = "f_"."-";
            }
        }
    }
    return \%res;
}


sub cal_md5 {
    my $file = shift;
    my $md5 = Digest::MD5->new;
    open my $FILE, "< $file" or die "Cannot open $file";
    while (<$FILE>) {
        $md5->add($_);
    }
    close $FILE;
    return $md5->hexdigest;
}

sub parse_dir {
    my $dir = shift;
    my %files_attr;
    opendir my $DIR, $dir or die "Cannot opendir: $dir\n";
    for my $file (readdir $DIR) {
        next if $file =~ /^\.\.?$/;
        my $path =  File::Spec->catfile($dir, $file);
        if (-f $path) {
            $files_attr{$file} = cal_md5($path);
        }
        elsif (-d $path) {
            $files_attr{$file} = parse_dir($path);
        }
    }
    closedir $DIR;
    return \%files_attr;
}

sub parse_argv {
    if (@ARGV != 2) {
        _usage("Argvs Nums Error");
    }

    for (@ARGV) {
        _usage("Cannot find dir [$_]")
            unless -d $_;
    }
    return @ARGV;
}

sub _usage {
    print shift, "\n";
    print "Usage: perl $0 <BASE_DIR> <COMPARED_DIR>\n";
    exit -1;
}

