#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use YAML;

#######
# Description
#####
#
# This script creates mysql database with predefined tables. 
# Usage:
#  cd app/dir/
#  tool/db_helper
#
# And it will be creating database with tables defined in $sql
# and settings those will be taken from app/dir/config.yaml
#
#######

my $path = "./config.yml";
my %sql  = (
    comments => qq(
        CREATE TABLE IF NOT EXISTS comments (
            id INT AUTO_INCREMENT NOT NULL,
            parent INT NOT NULL,
            page_number INT NOT NULL,
            content TEXT NOT NULL,
            username VARCHAR(15),
            title VARCHAR(30),
            PRIMARY KEY (id)
        );
    ),
    pages => qq(
        CREATE TABLE IF NOT EXISTS pages (
            id_page INT NOT NULL,
            content_page TEXT NOT NULL,
            title_page VARCHAR(30),
            PRIMARY KEY (id_page)
        );
    ),
);
open my $config_h, "<", $path
    or die "can't open config file: $!\n";
my $yaml_data = do { local $/ = undef, <$config_h> };

my $data_ref = Load( $yaml_data );

my $db     = $data_ref->{"plugins"}{"Database"}{"database"};
my $user   = $data_ref->{"plugins"}{"Database"}{"username"};
my $passw  = $data_ref->{"plugins"}{"Database"}{"password"};
my $driver = $data_ref->{"plugins"}{"Database"}{"driver"};

my $dsn = join ":", "dbi", $driver, $db;

my $dbh = DBI->connect($dsn, $user, $passw) 
    or die $DBI::errstr;

my $sth;
foreach my $sql (values %sql) {
    $sth = $dbh->prepare( $sql )
        or die $dbh->errstr;
    $sth->execute
        or die $dbh->errstr;
}

print "that's ok!! \n"
