# EstCrawler
#
# $Id$
#
# This software is provided as-is. You may use it for commercial or 
# personal use. If you distribute it, please keep this notice intact.
#
# Copyright (c) 2007 Hirotaka Ogawa

package MT::Plugin::EstCrawler;
use strict;
use base qw(MT::Plugin);

use MT;
use File::Basename qw(dirname);
use File::Spec;

our $VERSION = '0.01';
our $_OPTIMIZE = 0;

my $plugin = __PACKAGE__->new({
    id                     => 'est_crawler',
    name                   => 'EstCralwer',
    description            => q(<MT_TRANS phrase="EstCralwer automatically updates HyperEstraier database when posting and deleting entries.">),
    doc_link               => 'http://code.as-is.net/public/wiki/EstCrawler',
    author_name            => 'Hirotaka Ogawa',
    author_link            => 'http://as-is.net/blog/',
    version                => $VERSION,
    system_config_template => 'system_config.tmpl',
    settings               => new MT::PluginSettings([
	['est_db_path', {
	    Default => File::Spec->catdir(dirname(__FILE__), 'db'),
	    Scope   => 'system'
	}],
    ]),
    l10n_class             => 'EstCrawler::L10N',
});
MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
	callbacks => {
	    'MT::Entry::post_save'   => \&post_save_entry,
	    'MT::Page::post_save'    => \&post_save_entry,
	    'MT::Entry::post_remove' => \&post_remove_entry,
	    'MT::Page::post_remove'  => \&post_remove_entry,
	},
	applications => {
	    cms => {
		list_actions => {
		    entry => {
			estraier_entry => {
			    label      => $plugin->translate('Add to Estraier DB'),
			    code       => \&entry_list_action,
			    permission => 'administer',
			},
		    },
		    page => {
			estraier_page => {
			    label      => $plugin->translate('Add to Estraier DB'),
			    code       => \&entry_list_action,
			    permission => 'administer',
			},
		    },
		},
		menus => {
		    'estraier' => {
			label     => 'Estraier',
			order     => 900,
			permission => 'administer',
		    },
		    'estraier:scanall' => {
			label     => $plugin->translate('Scan All'),
			dialog    => 'estraier_scanall',
			order     => 100,
			permission => 'administer',
		    },
		    'estraier:cleanup' => {
			label     => $plugin->translate('Clean Up'),
			dialog    => 'estraier_cleanup',
			order     => 200,
			permission => 'administer',
		    },
		},
		methods => {
		    'estraier_scanall' => \&estraier_scanall,
		    'estraier_cleanup' => \&estraier_cleanup,
		},
	    },
	},
    });
}

sub load_tmpl {
    my $plugin = shift;
    my $tmpl = $plugin->SUPER::load_tmpl(@_);
    $tmpl->text($plugin->translate_templatized($tmpl->text));
    $tmpl;
}

sub post_save_entry {
    my $class = shift;
    my ($app, $entry) = @_;
    return unless $entry->isa('MT::Entry');

    if ($entry->status == MT::Entry::RELEASE()) {
	MT::Util::start_background_task(sub { add_entry($entry) });
    } else {
	MT::Util::start_background_task(sub { delete_entry($entry) });
    }
}

sub post_remove_entry {
    my $class = shift;
    my ($app, $entry) = @_;
    return unless $entry->isa('MT::Entry');
    MT::Util::start_background_task(sub { delete_entry($entry) });
}

sub entry_list_action {
    my $app = shift;
    return $app->trans_error("Permission denied.")
	unless $app->user->is_superuser;
    MT::Util::start_background_task(sub { add_multiple_entries(@_) });
    $app->call_return;
}

use Estraier;

sub add_entry {
    my $entry = shift;
    my $db = new Database();
    my $dbpath = $plugin->get_config_value('est_db_path');
    $db->open($dbpath, Database::DBWRITER | Database::DBCREAT)
	or $plugin->trans_error("Cannot open Estraier DB.");
    $db->put_doc(entry_to_doc($entry), Database::PDCLEAN)
	or $plugin->trans_error("Cannot add an entry to Estraier DB.");
    $db->optimize() if $_OPTIMIZE;
    $db->close()
	or $plugin->trans_error("Cannot close Estraier DB.");
}

sub add_multiple_entries {
    my @ids = @_;
    my $db = new Database();
    my $dbpath = $plugin->get_config_value('est_db_path');
    $db->open($dbpath, Database::DBWRITER | Database::DBCREAT)
	or $plugin->trans_error("Cannot open Estraier DB.");
    my $iter = MT::Entry->load_iter({
	id => \@ids,
	status => MT::Entry::RELEASE(),
    });
    while (my $entry = $iter->()) {
	$db->put_doc(entry_to_doc($entry), Database::PDCLEAN);
    }
    $db->optimize() if $_OPTIMIZE;
    $db->close()
	or $plugin->trans_error("Cannot close Estraier DB.");
}

sub delete_entry {
    my $entry = shift;
    my $id = uri_to_id($entry->permalink)
	or $plugin->error($plugin->errstr || $plugin->translate('Cannot find an Estraier entry for entry [ID:_1]', $entry->id));
    if ($id > 0) {
	my $db = new Database();
	my $dbpath = $plugin->get_config_value('est_db_path');
	$db->open($dbpath, Database::DBWRITER | Database::DBCREAT)
	    or $plugin->trans_error("Cannot open Estraier DB.");
	$db->out_doc($id, Database::ODCLEAN)
	    or $plugin->trans_error("Cannot remove an entry from Estraier DB.");
	$db->optimize() if $_OPTIMIZE;
	$db->close()
	    or $plugin->trans_error("Cannot close Estraier DB.");
    }
}

sub estraier_scanall {
    my $app = shift;
    return $app->trans_error("Permission denied.")
	unless $app->user->is_superuser;
    #my $blog_id = $app->param('blog_id');

    MT::Util::start_background_task(
	sub {
	    my $db = new Database();
	    my $dbpath = $plugin->get_config_value('est_db_path');
	    $db->open($dbpath, Database::DBWRITER | Database::DBCREAT)
		or $plugin->trans_error("Cannot open Estraier DB.");
	    my $iter = MT::Entry->load_iter({
		status => MT::Entry::RELEASE(),
		class => '*',
		#$blog_id ? (blog_id => $blog_id) : (),
	    });
	    while (my $entry = $iter->()) {
		$db->put_doc(entry_to_doc($entry), Database::PDCLEAN);
	    }
	    $db->optimize() if $_OPTIMIZE;
	    $db->close()
		or $plugin->trans_error("Cannot close Estraier DB.");
	}
    );

    my $tmpl = $plugin->load_tmpl('dialog_scanall.tmpl');
    return $app->build_page($tmpl);
}

sub estraier_cleanup {
    my $app = shift;
    my $tmpl = $plugin->load_tmpl('dialog_cleanup.tmpl');
    return $app->build_page($tmpl);
}

sub estraier_cleanup_ {
    my $app = shift;
    return $app->trans_error("Permission denied.")
	unless $app->user->is_superuser;
    my $blog_id = $app->param('blog_id');

    # not yet implemented

    $app->call_return;
}

sub uri_to_id {
    my $uri = shift;
    my $db = new Database();
    my $dbpath = $plugin->get_config_value('est_db_path');
    $db->open($dbpath, Database::DBREADER)
	or $plugin->trans_error("Cannot open Estraier DB.");
    my $id = $db->uri_to_id($uri);
    $db->close()
	or $plugin->trans_error("Cannot close Estraier DB.");
    $id;
}

use MT::Util qw(remove_html ts2iso);
sub entry_to_doc {
    my ($entry) = @_;
    my $doc = new Document();

    my $title = remove_html($entry->title) || '';
    my $author = remove_html($entry->author->nickname || $entry->author->name);
    my $cdate = ts2iso($entry->blog, $entry->authored_on);
    my $mdate = ts2iso($entry->blog, $entry->modified_on);
    my $categories = join('', map { '[' . $_->label . ']' } @{$entry->categories})
	if $entry->categories;
    my $tags = join('', map { '[' . $_ . ']' } $entry->tags)
	if $entry->tags;

    # metainfo (attribute, not searchable)
    $doc->add_attr('@uri', $entry->permalink);
    $doc->add_attr('@title', $title);
    $doc->add_attr('@author', $author);
    $doc->add_attr('@cdate', $cdate);
    $doc->add_attr('@mdate', $mdate);
    $doc->add_attr('entry_id', $entry->id);
    $doc->add_attr('blog_id', $entry->blog_id);
    $doc->add_attr('categories', $categories) if $categories;
    $doc->add_attr('tags', $tags) if $tags;

    # document body (searchable)
    my $filters = $entry->text_filters;
    push @$filters, '__default__' unless @$filters;
    $doc->add_text(remove_html(MT->apply_text_filters($entry->text, $filters)) || '');
    $doc->add_text(remove_html(MT->apply_text_filters($entry->text_more, $filters)) || '');

    # metainfo (hidden, searchable)
    $doc->add_hidden_text($title);
    $doc->add_hidden_text($author);
    $doc->add_hidden_text($categories || '');
    $doc->add_hidden_text($tags || '');
    $doc->add_hidden_text(remove_html($entry->keywords) || '');
    $doc;
}

1;
