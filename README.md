# BeatSaber PlayListTool

<img src="https://user-images.githubusercontent.com/14249877/149654844-5f67b7f3-71cc-4a93-9619-4cba55582361.png" width="589" height="529">

このツールは以下の4つの機能があります。

1. ScoreSaberのユーザのスコアリストを取り込んで、プレイリストに変換します。

    ※この機能はコマンドラインにオプション指定することで、GUI画面を出さずに
    バッチファイルなどで自動処理が可能です。

2. ScoreSaberのユーザのスコアリストを取り込んで、TSV(CSV)ファイルに保存し、
 GoogleのスプレッドシートやEXCEL等に取り込みが可能です。

3. BeatSaberのプレイリストを、TSV(CSV)ファイルに変換して保存し、
スプレッドシート等で編集可能です。

4. スプレッドシートやEXCELの曲IDリストからBeatSaber用のプレイリストを作成します。
スプレッドシート等でクリップボードにコピーしたリストから、BeatSaber用の
プレイリストを生成して保存します。

# ダウンロード
[最新リリース](https://github.com/rynan4818/PlayListTool/releases)から、ダウンロードして下さい。
# インストール・使用方法

[BeatSaber PlayList TOOL の説明](https://docs.google.com/document/d/1ws1JUhqsRc-7NcBkgwIAT9jMnaTvSlcR1WGLQf9M-_8/edit?usp=sharing)
を参照して下さい。

# ライセンスと著作権について

PlayListTool はプログラム本体と各種ライブラリから構成されています。

PlayListTool のソースコード及び各種ドキュメントについての著作権は作者であるリュナン(Twitter [@rynan4818](https://twitter.com/rynan4818))が有します。
ライセンスは MIT ライセンスを適用します。

それ以外の PlayListTool.exe に内包しているrubyスクリプトやバイナリライブラリは、それぞれの作者に著作権があります。配布ライセンスは、それぞれ異なるため詳細は下記の入手元を確認して下さい。

# 開発環境、各種ライブラリ入手先

各ツールの入手先、開発者・製作者（敬称略）、ライセンスは以下の通りです。

PlayListTool.exe に内包している具体的なライブラリファイルの詳細は [Exerbレシピファイル](source/core_cui.exy) を参照して下さい。

## Ruby本体入手先
- ActiveScriptRuby(1.8.7-p330)
- https://www.artonx.org/data/asr/
- 製作者:arton
- ライセンス：Ruby Licence

## GUIフォームビルダー入手先
- FormDesigner for Project VisualuRuby Ver 040323
- https://ja.osdn.net/projects/fdvr/  (オリジナル)
- https://github.com/rynan4818/formdesigner   (改造版＆exe化配布)
- 開発者:雪見酒
- ライセンス：Ruby Licence

## 使用拡張ライブラリ、ソースコード

### Ruby本体 1.8.7-p330              #開発はActiveScriptRuby(1.8.7-p330)を使用
- https://www.ruby-lang.org/ja/
- 開発者:まつもとゆきひろ
- ライセンス：Ruby Licence

### Exerb                            #開発はActiveScriptRuby(1.8.7-p330)同封版を使用
- http://exerb.osdn.jp/man/README.ja.html
- 開発者:加藤勇也
- ライセンス：LGPL

### gem                              #開発はActiveScriptRuby(1.8.7-p330)同封版を使用
- https://rubygems.org/
- ライセンス：Ruby Licence

### VisualuRuby                      #開発はActiveScriptRuby(1.8.7-p330)同封版を使用 ※swin.soを改造
- http://www.osk.3web.ne.jp/~nyasu/software/vrproject.html
- 開発者:にゃす
- ライセンス：Ruby Licence

### json-1.4.6-x86-mswin32
- https://rubygems.org/gems/json/versions/1.4.6
- https://rubygems.org/gems/json/versions/1.4.6-x86-mswin32
- 開発者:Florian Frank
- ライセンス：Ruby Licence

### DLL

#### libiconv 1.11  (iconv.dll)       #ExerbでPlayListTool.exeに内包
- https://www.gnu.org/software/libiconv/
- Copyright (C) 1998, 2019 Free Software Foundation, Inc.
- ライセンス：LGPL
