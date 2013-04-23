# EstCrawlerプラグイン

Hyper Estraierのデータベースを管理するためのプラグイン。

EstCrawlerは、エントリをまとめてHyper Estraierのデータベースに追加したり、エントリの追加・削除に応じてHyper Estraierのデータベースを自動的に更新したりする機能を提供します。MT4専用。

## 更新履歴

 * 0.01 (2007-10-05 18:07:33 +0900):
   * 公開。

## 概要

EstCrawlerは、エントリをまとめてHyper Estraierのデータベースに追加したり、エントリの追加・削除に応じてHyper Estraierのデータベースを自動的に更新したりする機能を提供します。要は、Movable Typeのエントリの情報とHyper Estraierデータベースを同期することを目的としたプラグインです。

## 使い方

プラグインをインストールするには、パッケージに含まれる!EstCrawlerディレクトリをMovable Typeのプラグインディレクトリ内にアップロードもしくはコピーしてください。正しくインストールできていれば、Movable Typeのメインメニューにプラグインが新規にリストアップされます。

システムのプラグイン設定画面から、Hyper Estraierデータベースの置かれるディレクトリを指定することができます。デフォルトでは

    /PATH/TO/MT/plugins/EstCrawler/db

にデータベースを作成します。

### 基本的な振る舞い

 * エントリの追加時: 追加したエントリが公開状態ならばHyper Estraierデータベースに追加します。
 * エントリの削除時: エントリがHyper Estraierデータベースに見つかれば削除します。
 * エントリの状態変更時: エントリの状態が公開状態なら、Hyper Estraierデータベースのエントリを更新します。エントリの状態が非公開状態なら、HyperEstraierデータベースから削除します。

### その他の機能

CMSのメニューやアクションメニューからHyper Estraierデータベースへの指示ができます。詳しくは調べてみてください。

## See Also

## License

This code is released under the Artistic License. The terms of the Artistic License are described at [http://www.perl.com/language/misc/Artistic.html]().

## Author & Copyright

Copyright 2007, Hirotaka Ogawa (hirotaka.ogawa at gmail.com)
