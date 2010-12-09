package test_task;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Carp;

our $VERSION = '0.1';

my $comment_on;

get '/' => sub {
    template 'index';
#    render_with_layout 'index';
};

get '/page/:id' => sub {
    my $sth = database->prepare(
        'select * from books',
    );
    $sth->execute
        or croak $sth->errstr;

    $comment_on = params->{id};
    template "base", { 
        records => $sth->fetchall_hashref("id"),
        test    => "hello there!",
    };
};

get '/error' => sub {
#    if ( session );
    return send_error( "this is error", 401 );

};

get '/comment' => sub {
    my $to_page = $comment_on;
    undef $comment_on;
    
    template 'comment', {
        comment_url => uri_for("/comment"),
        comment_on  => $to_page,
    };
};

#before_template sub {
#    my $tokens = shift;
#
#    $tokens->{"comment_url"} = uri_for( "/comment" );
#};

true;
