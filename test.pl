#!/usr/bin/perl
 
use strict;
use warnings;
use Net::DNS::Nameserver;
use Time::HiRes qw( gettimeofday tv_interval );
 
my $t0;
 
sub reply_handler {
    my ( $qname, $qclass, $qtype, $peerhost, $query, $conn ) = @_;
    my ( $rcode, @ans, @auth, @add );
    
    print "Received query from $peerhost to " . $conn->{sockhost} . "\n";
    $query->print;
    
    # mark the answer as authoritative (by setting the 'aa' flag)
    my $headermask = {aa => 1, qr => 1, rd => 1};
    
    # specify EDNS options  { option => value }
    my $optionmask = {};
    
    if ( ($qtype eq "TXT" || $qtype eq "CNAME") && $qname eq "rtt.net.cs.tuat.ac.jp"){
        $t0 = [gettimeofday];
        
        my ( $ttl, $s, $ms ) = ( 5, gettimeofday );
        
        my $strtime = join('.', @$t0);
        my $cname = Net::DNS::RR->new("rtt.net.cs.tuat.ac.jp $ttl IN CNAME $strtime.rtt.net.cs.tuat.ac.jp");
        push @ans, $cname;
        #my $ns = Net::DNS::RR->new("$strtime.rtt2.rtt1.net.cs.tuat.ac.jp $ttl IN A rtt.rtt.net.cs.tuat.ac.jp");
        #push @auth, $ns;
        #my $rr = Net::DNS::RR->new("$strtime.rtt2.rtt1.net.cs.tuat.ac.jp $ttl IN A 54.250.152.233");
        #my $rr = Net::DNS::RR->new("rtt.net.cs.tuat.ac.jp $ttl IN NS $strtime.rtt2.net.cs.tuat.ac.jp");
        #push @auth, $rr;
        #my $arec = Net::DNS::RR->new("$strtime.rtt2.net.cs.tuat.ac.jp $ttl IN A $conn->{sockhost}");
        #push @add, $arec;
        $rcode = "NOERROR";
        return( $rcode, \@ans, \@auth, \@add, $headermask, $optionmask)
                
    } #elsif($qtype eq "A" && $qname =~ /rtt.rtt.net.cs.tuat.ac.jp/){
       # my $arec = Net::DNS::RR->new("$qname 1 IN A $conn->{sockhost}");
        #push @ans, $arec;
        #$rcode = "NOERROR";
        #return( $rcode, \@ans, \@auth, \@add, $headermask, $optionmask)
   # }
      
      elsif( $qtype eq "TXT" && $qname =~ /rtt.net.cs.tuat.ac.jp/){
    
        my @packet = split(/\./, $qname);
        my $time = [$packet[0], $packet[1]];
        
        my $elapsed = tv_interval($time);
        
        
        my $ttl = 1;
        my $rr = Net::DNS::RR->new("$qname $ttl $qclass $qtype $elapsed");
        push @ans, $rr;
        $rcode = "NOERROR";
        
    } else {
        $rcode = "NXDOMAIN";
    }
    return ( $rcode, \@ans, \@auth, \@add, $headermask, $optionmask );
}
 
 
 
 
my $ns = new Net::DNS::Nameserver(
                                  LocalPort    => 53,
                                  LocalAddr    => '165.93.176.2',
                                  ReplyHandler => \&reply_handler,
                                  Verbose      => 0
                                  ) || die "couldn't create nameserver object\n";
 
$ns->main_loop;
