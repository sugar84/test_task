#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use YAML;

my $path = "./config.yml";
my $sql = qq(
    INSERT INTO pages (id_page, title_page, content_page) VALUES (?, ?, ?)
);

my @contents = (
    [ 1, "Some header", qq(
        <p>Very short story about small girl, called Red Hat</p>
        <p>She delivered to Babushka, her friend, 'pirojki s kapustoi'</p>
    ), ],
    [ 2, "Another header", qq(
        <p>More long story</p>
        <p>It talks about knight</p>
        <p>He wasn't a common knight</p>
        <p>He was the Dragon-Knight</p>
        <p>In day he was a knight that fights with evils everywhere</p>
        <p>But in the night he was transfering to Dragon, that burns out
        all evils in his kingdom</p>
    ), ],
    [ 3, "Yet another header", qq(
        <p>This long boring story</p>
        <p>It's about the Hedgehog and 40 bandits</p>
        <p>Once upon a time the Hedgehog was walking around the forest when
         he met 40 bandits</p>
        <p>Hello 1 bandit, he says </p>
        <p>Hello the Hedgehog, 1 bandit says </p>
        <p>Hello 2 bandit, he says </p>
        <p>Hello the Hedgehog, 2 bandit says </p>
        <p>Hello 3 bandit, he says </p>
        <p>Hello the Hedgehog, 3 bandit says </p>
        <p>Hello 4 bandit, he says </p>
        <p>Hello the Hedgehog, 4 bandit says </p>
        <p>Hello 5 bandit, he says </p>
        <p>Hello the Hedgehog, 5 bandit says </p>
        <p>Hello 6 bandit, he says </p>
        <p>Hello the Hedgehog, 6 bandit says </p>
        <p>Hello 7 bandit, he says </p>
        <p>Hello the Hedgehog, 7 bandit says </p>
        <p>Hello 8 bandit, he says </p>
        <p>Hello the Hedgehog, 8 bandit says </p>
        <p>---</p>
        <p>I said, that boring story and I stop talking it</p>
        <p>that's all</p>
    ), ],
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

my $sth = $dbh->prepare( $sql )
    or die $dbh->errstr;
foreach my $rec_ref (@contents) {
    $sth->execute( @{$rec_ref} )
        or die $dbh->errstr;
}

print "that's ok!! \n"
