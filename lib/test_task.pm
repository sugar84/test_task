package test_task;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Carp;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/page_1' => sub {
    my $sth = database->prepare(
        'select * from books',
    );
    $sth->execute
        or croak $sth->errstr;

    template "base", { 
        records => database->fetchall_arrayref,
    };
};

true;
