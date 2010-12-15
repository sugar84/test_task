package test_task;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Data::Dumper;
use Carp;

our $VERSION = '0.2';

## Config
set number_of_pages => 3;
# in real app it will be taken from db

##
## Subroutins
##

# insert into database posted comment
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

# fetch from database requested content
sub fetch_from_base {
    my ($page_id) = @_;

## alternative work with DB
## (it's needed to be rewritten and additional operations with hashes)
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
    my (%data);

    my $sth = database->prepare(
        "SELECT id_page, title_page, content_page FROM pages 
            WHERE id_page = $page_id"
    ) or croak database->errstr;
    
    $sth->execute
        or croak $sth->errstr;
    $data{"page"} = $sth->fetchrow_hashref;

    $sth = database->prepare(
        "SELECT id, parent, page_number, content, username, title 
            FROM comments WHERE page_number = $page_id"
    ) or croak database->errstr;
    
    $sth->execute
        or croak $sth->errstr;
    $data{"comment_hash"} = $sth->fetchall_hashref("id");

    return ( \%data );
}

# transform plain hash data structure of comments to recursive representation
sub trans_comments_struct {
    my ($recs_ref) = @_;
    
    my @top_level;
    foreach my $key (sort {$a <=> $b} keys %$recs_ref) {
        my $parent = $recs_ref->{$key}{"parent"} ;
        
        if ($parent == 0) {
            push @top_level, $recs_ref->{$key};
        }
        else {
            push @{ $recs_ref->{$parent}{"child"} }, $recs_ref->{$key};
        }
    }

    return( \@top_level );
}

## Hooks

# section for hooks after, before and before_template

##
## Routes
##

get "/" => sub {
    template "index";
};

get "/page/:id" => sub {
    my $page_id = params->{id};

    # handle the undefined pages
    if ( $page_id !~ /^\d+$/ or $page_id > setting("number_of_pages") ) {
        session( err_message => "page doesn't exist" );
        return redirect uri_for( "/error" );
    }

    # get data from base, and tranform it to needed structure
    my $content_ref = fetch_from_base($page_id);
    $content_ref->{"comment_arr"} = trans_comments_struct( 
        $content_ref->{"comment_hash"} 
    );
    my $page_title  = $content_ref->{"page"}{"title_page"};

    template "base", { 
        records    => $content_ref->{"page"},
        page_title => $page_title,
        comments   => $content_ref->{"comment_arr"},
        path       => request->path,
    };
};

post "/page/:id" => sub {
    # take params for next using it in posting
    session( comment_page    => params->{"id"} );
    session( comment_to      => params->{"comment_to"} );
    session( comment_title   => params->{"comment_title"} );
    session( to_author       => params->{"to_author"} );
    session( what_comment    => params->{"what_comment"} );

    redirect uri_for( "/comment" );
};

get "/error" => sub {
    # recieve error message form route handler
    my $err_message = session("err_message");
    session( err_message => undef );

    template "error", {
        message => $err_message,
        url_to  => uri_for("/"),
    };
};

get "/comment" => sub {
    my $comment_mess;
    
    # check what is user comments for: page or another comment
    if (defined session("what_comment")) {
        if ( session("what_comment") eq "page") {
            $comment_mess = "You comment page '" . session("comment_title") . "'";
        }
        elsif ( session("what_comment") eq "comment" ) {
            $comment_mess = "You comment message of " . session("to_author");
        }
    }
    else {
        return redirect uri_for("/");
    }

    template "comment", {
        comment_mess  => $comment_mess, 
        comment_to    => session("comment_to"),
        comment_page  => session("comment_page"),
        comment_title => session("comment_title"),
        to_url        => uri_for("/"),
    };
};

post "/comment" => sub {
    # set params translte them later to row and insert it into the base
    my %params = (
        title    => params->{"title"},
        username => params->{"username"},
        content  => params->{"text"},
        page     => session("comment_page"),
        parent   => session("comment_to"),
    );
    # translate \n to <br />
    $params{"content"} =~ s|\n|<br />|g;
        
    my $res = add_to_base( \%params );
    
    session( what_comment => undef );
    session( comment_page => undef );
    session( comment_to   => undef );
        
    template "posted", {
        title       => $res,
        username    => params->{"username"},
        url_to      => uri_for("/"),
    };
};

true;
