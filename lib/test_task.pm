package test_task;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Data::Dumper;
use Carp;

our $VERSION = '0.2';

my ($error_mess, $page);
my $number_of_pages = 3;

sub add_to_base {
    my ($row_ref) = @_;
    
    my $sth = database->prepare(
        'INSERT INTO comments (parent, page_number, username,
            title, content) VALUES (?, ?, ?, ?, ?)'
    ) or croak database->errstr;
    $sth->execute(
        $row_ref->{"parent"}, $row_ref->{"page"}, $row_ref->{"username"},
        $row_ref->{"title"}, $row_ref->{"content"},
    ) or croak $sth->errstr;

    return "that's ok";
}

sub fetch_from_base {
    my ($page_id) = @_;

## alternative work with DB
#
#   my $sth = database->prepare(
#        "SELECT comments.*, pages.* FROM (pages INNER JOIN comments ON 
#            pages.id_page = comments.page_number) WHERE pages.id_page = $page_id"
#    ) or croak database->errstr;
#    $sth->execute
#        or croak $sth->errstr;
#
#    my $all = $sth->fetchall_hashref("id_page");
#    if (not values %{$all}) {
#        $sth = database->prepare(
#            "SELECT id_page, content_page, title_page FROM pages 
#                WHERE id_page = $page_id") 
#            or croak $sth->errstr;
#        $sth->execute
#            or croak $sth->errstr;
#        $all = $sth->fetchall_hashref("id_page");
#    }
    my $sth = database->prepare(
        "SELECT id_page, title_page, content_page FROM pages 
            WHERE id_page = $page_id"
    ) or croak database->errstr;
    $sth->execute
        or croak $sth->errstr;
    my $page_ref = $sth->fetchrow_hashref;

    $sth = database->prepare(
        "SELECT id, parent, page_number, content, username, title 
            FROM comments WHERE page_number = $page_id"
    ) or croak database->errstr;
    $sth->execute
        or croak $sth->errstr;
    my $comments_ref= $sth->fetchall_hashref("id");

    my $all_ref = { comment => $comments_ref, page => $page_ref };

    return ( $all_ref );
}

get '/' => sub {
    template 'index';
};

get '/page/:id' => sub {
    my $page_id = params->{id};

    if ($page_id !~ /\d+/ or $page_id > $number_of_pages) {
        session( err_message => "page doesn't exist" );
        return redirect uri_for( "/error" );
    }

    my $content_ref = fetch_from_base($page_id);
    my $page_title  = $content_ref->{"page"}{"title_page"};

    template "base", { 
        records    => $content_ref->{"page"},
        page_title => $page_title,
        comments   => $content_ref->{"comment"},
        path       => request->path,
    };
};

post '/page/:id' => sub{
    session( comment_page    => params->{"id"} );
    session( comment_to      => params->{"comment_to"} );
    session( page_title      => params->{"page_title"} );
    session( to_author       => params->{"to_author"} );
    session( what_comment    => params->{"what_comment"} );

    redirect uri_for("/comment");
};

get '/error' => sub {
    my $err_message = session("err_message");
    session( err_message => undef );

    template 'error', {
        message => $err_message,
        url_to  => uri_for("/"),
    };
};

get '/comment' => sub {
    my $comment_mess;
    if ( session("what_comment") eq "page") {
        $comment_mess = "You comment page '" . session("page_title") . "'";
    }
    elsif ( session("what_comment") eq "comment" ) {
        $comment_mess = "You comment message of " . session("to_author");
    }
    session( what_comment => undef );

    template 'comment', {
        comment_mess => $comment_mess, 
        comment_to   => session("comment_to"),
        comment_page => session("comment_page"),
        comment_url  => uri_for("/comment"),
    };
};

post "/comment" => sub {
    my %params = (
        title    => params->{"title"},
        username => params->{"username"},
        content  => params->{"text"},
        page     => session("comment_page"),
        parent   => session("comment_to"),
    );
        
    my $res = add_to_base( \%params );
    
    session( comment_page => undef );
    session( comment_to   => undef );
        
    return template "posted", {
        title     => $res,
        username  => params->{"username"},
        text      => params->{"text"},
        url_to    => uri_for("/"),
    };
};

true;
