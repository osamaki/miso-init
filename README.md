# miso-init

`miso-init` は、[miso](https://github.com/dmjio/miso) を使った Haskell フロントエンドプロジェクトを素早く始めるための初期化コマンドです。

現時点では、Nix を使わずに `ghc-wasm` の bootstrap toolchain で WebAssembly 向け miso アプリを生成することに絞っています。

## できること

- `miso` の最小構成アプリを生成する
- `wasm32-wasi-cabal` でビルドできる `cabal.project` と `.cabal` を生成する
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

`bin/build-web.sh` は `public/` にブラウザ配信用ファイルを出力します。

## 開発方針

このリポジトリは、miso を使った Haskell フロントエンド開発を始めるまでの手間を減らす補助コマンドを育てることを目的にしています。

当面の対象は次の通りです。

- non-Nix `ghc-wasm` bootstrap toolchain
- `cabal` ベースの最小構成
- ブラウザで確認できる WebAssembly 出力
