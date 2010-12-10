package test_task;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Data::Dumper;
use Carp;

our $VERSION = '0.2';

my ($comment_on, $error_mess, $page);
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

    my $sth = database->prepare(
        "SELECT comments.*, pages.* FROM (pages INNER JOIN comments ON 
            pages.id_page = comments.page_number) WHERE pages.id_page = $page_id"
    ) or croak database->errstr;
    $sth->execute
        or croak $sth->errstr;

    my $all = $sth->fetchall_hashref("id_page");
    if (not values %{$all}) {
        $sth = database->prepare(
            "SELECT id_page, content_page, title_page FROM pages 
                WHERE id_page = $page_id") 
            or croak $sth->errstr;
        $sth->execute
            or croak $sth->errstr;
        $all = $sth->fetchall_hashref("id_page");
    }
    return Dumper( $all );
}

get '/' => sub {
    template 'index';
};

get '/page/:id' => sub {
    my $page_id = params->{id};
    
    if ($page_id !~ /\d+/ or $page_id > $number_of_pages) {
        $error_mess = "page doesn't exist";
        return redirect uri_for( "/error" );
    }

    my $all = fetch_from_base($page_id);    

    $comment_on = $page_id;
    template "base", { 
#        records => $sth->fetchrow_hashref,
        all => $all,
    }, { 
        layout  => "main_comment"
    };
};

get '/error' => sub {
    my $message = $error_mess;
    undef $error_mess;

    template 'error', {
        message => $message,
        url_to  => uri_for("/"),
    };
};

any ["get", "post"] => '/comment' => sub {
    my $to_page = $comment_on;

    if (request->method() eq "POST") {
        my %params = (
            title    => params->{"title"},
            username => params->{"username"},
            content  => params->{"text"},
            page     => $comment_on,
            parent   => 0
        );
        my $res = add_to_base( \%params );
        undef $comment_on;
        return template "posted", {
            title     => $res,
            username  => params->{"username"},
            text      => params->{"text"},
            url_to    => uri_for("/"),
        };
    }
#    if (not $to_page) {
#        $error_mess = "uknown page";
#        return redirect uri_for( "/error" );
#    }
    
    template 'comment', {
        comment_url => uri_for("/comment"),
        comment_on  => $to_page,
    };
};

true;
