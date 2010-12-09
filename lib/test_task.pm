package test_task;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Carp;

our $VERSION = '0.1';

my ($comment_on, $error_mess);
my $number_of_pages = 3;

get '/' => sub {
    template 'index';
};

get '/page/:id' => sub {
    my $page_id = params->{id};
    
    if ($page_id !~ /\d+/ or $page_id > $number_of_pages) {
        $error_mess = "uknown page";
        return redirect uri_for( "/error" );
    }
#    elsif ($page_id \cc

    my $sth = database->prepare(
        'select * from books',
    );
    $sth->execute
        or croak $sth->errstr;

    $comment_on = $page_id;
    template "base", { 
        records => $sth->fetchall_hashref("id"),
        test    => "hello there!",
    };
};

get '/error' => sub {
    my $message = $error_mess;
    undef $error_mess;

    template 'error', {
        message => $message,
        url_to  => uri_for("/"),
    };
#    return send_error( "this is error", 401 );
};

get '/comment' => sub {
    my $to_page = $comment_on;
    undef $comment_on;
    
    template 'comment', {
        comment_url => uri_for("/comment"),
        comment_on  => $to_page,
    };
};

true;
