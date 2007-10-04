# $Id$
package EstCrawler::L10N::ja;

use strict;
use base 'EstCrawler::L10N';
use vars qw( %Lexicon );

our %Lexicon = (
    'EstCralwer automatically updates HyperEstraier database when posting and deleting entries.' => 'EstCrawlerは、エントリをまとめてHyperEstraierのデータベースに追加したり、エントリの追加・削除に応じてHyperEstraierのデータベースを自動的に更新したりする機能を提供します。',
    'Add to Estraier DB' => 'Estraier DBに追加',
    'Scan All' => '全エントリをスキャン',
    'Clean Up' => 'クリーンアップ',
    'Estraier DB Path' => 'Estraier DBのパス',
    'EstCrawler - Clean Up' => 'EstCrawler - クリーンアップ',
    'EstCrawler - Scan All' => 'EstCrawler - 全エントリをスキャン',
    'Not yet implemented.' => '未実装です。',
    'Successfully scanned all entries.' => '全エントリのスキャンを完了しました。',
);

1;
