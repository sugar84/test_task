package test_task;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Carp;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
#    render_with_layout 'index';
};

get '/page_1' => sub {
    my $sth = database->prepare(
        'select * from books',
    );
    $sth->execute
        or croak $sth->errstr;

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
    template 'comment', {
        comment_url => uri_for("/comment"),
    };

};

#before_template sub {
#    my $tokens = shift;
#
#    $tokens->{"comment_url"} = uri_for( "/comment" );
#};

true;
