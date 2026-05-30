# miso-init

`miso-init` は、[miso](https://github.com/dmjio/miso) を使った Haskell フロントエンドプロジェクトを素早く始めるための初期化コマンドです。

現時点では、Nix を使わずに `ghc-wasm` の bootstrap toolchain で WebAssembly 向け miso アプリを生成することに絞っています。

## できること

- `miso` の最小構成アプリを生成する
- `wasm32-wasi-cabal` でビルドできる `cabal.project` と `.cabal` を生成する
- `--miso-ref` / `--miso-version` で利用する miso の参照を選べる
- デフォルトでは既知の安定版 miso に固定し、短縮バージョン指定時だけ最新 release tag を解決する
- ブラウザ実行に必要な `static/index.html` と `static/index.js` を生成する
- `bin/build-web.sh` と `bin/serve.sh` を生成する

## インストール

```sh
git clone https://github.com/osamaki/miso-init.git
cd miso-init
ln -s "$PWD/bin/miso-init" /usr/local/bin/miso-init
```

## 前提

生成されたプロジェクトをビルドするには、`ghc-wasm` の non-Nix bootstrap toolchain が必要です。

```sh
source ~/.ghc-wasm/env
```

有効化できているかは、次のコマンドで確認できます。

```sh
command -v wasm32-wasi-cabal
command -v wasm32-wasi-ghc
wasm32-wasi-ghc --version
```

## 使い方

新しいディレクトリに生成する場合:

```sh
miso-init hello-miso
cd hello-miso
```

カレントディレクトリに生成する場合:

```sh
mkdir hello-miso
cd hello-miso
miso-init
```

既存ファイルがある場所へ上書き生成する場合:

```sh
miso-init --force
```

miso の release tag / git 参照を指定する場合:

```sh
miso-init --miso-version 1.11 hello-miso
miso-init --miso-version 1.11.0 hello-miso
miso-init --miso-ref 2853fb4f26175f51ae7b9aaf0ec683c45070d06e hello-miso
```

デフォルトでは `miso` はフルバージョンの release tag に固定されます。
`--miso-version 1.11` や `--miso-version 1` のように patch version などを省略した場合は、GitHub の tag を参照して、その範囲内の最新 release tag に解決してから `cabal.project` に書き込みます。
この解決にはネットワークアクセスが必要です。オフラインで生成したい場合は `--miso-version 1.11.0` のようにフルバージョンを指定してください。

詳細:

```sh
miso-init --help
```

## 生成される構成

```text
.
├── app/
│   └── Main.hs
├── bin/
│   ├── build-web.sh
│   └── serve.sh
├── static/
│   ├── index.html
│   └── index.js
├── .gitignore
├── cabal.project
└── <package-name>.cabal
```

## ビルドと起動

生成されたプロジェクト内で実行します。

```sh
source ~/.ghc-wasm/env
bin/build-web.sh
bin/serve.sh
```

その後、ブラウザで `http://localhost:8000` を開きます。
ポートを変える場合は、`PORT=8080 bin/serve.sh` または `bin/serve.sh --port 8080` を実行します。

`bin/build-web.sh` は `public/` にブラウザ配信用ファイルを出力します。
`public/` は完全な生成物ディレクトリなので、直接編集しないでください。
画像や CSS など配信したい追加ファイルは `static/` に置くと、ビルド時に `public/` へコピーされます。
既存の `public/` に miso-init の生成 marker がない場合、誤削除を避けるため `bin/build-web.sh` はエラーで停止します。

## 開発時の確認

通常の変更では `make check` を通します。

```sh
make check
```

`make check` は Bash の構文チェックと Bats テストを実行しますが、実際の `ghc-wasm` ビルドは含みません。

生成されるプロジェクト、`bin/build-web.sh`、`cabal.project`、miso 依存指定に関わる変更では、`ghc-wasm` ツールチェーンを有効化して `make smoke` も通します。

```sh
source ~/.ghc-wasm/env
make smoke
```

`make smoke` は一時ディレクトリに生成したアプリを実際の `ghc-wasm` ツールチェーンでビルドし、`public/` 配下のブラウザ配信用ファイル生成まで確認します。

## 開発方針

このリポジトリは、miso を使った Haskell フロントエンド開発を始めるまでの手間を減らす補助コマンドを育てることを目的にしています。

当面の対象は次の通りです。

- non-Nix `ghc-wasm` bootstrap toolchain
- `cabal` ベースの最小構成
- ブラウザで確認できる WebAssembly 出力
