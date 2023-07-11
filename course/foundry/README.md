# Introduction to Foundry

このゼミでは、開発ツールとして[Foundry](https://github.com/foundry-rs/foundry)を使います。
Foundry は[Paradigm](https://www.paradigm.xyz/)が主導して開発をしている Rust 製の OSS です。
このページでは Foundry の概要とよく使うコマンドの一つである`forge test`について簡単に紹介します。
最後に演習があります。

**目次**

- [インストール](#インストール)
- [使ってみる](#使ってみる)
  - [プロジェクトの作成](#プロジェクトの作成)
  - [プロジェクトの構成](#プロジェクトの構成)
  - [コントラクトのテスト](#コントラクトのテスト)
  - [`forge test`の`-v`オプション](#forge-testの-vオプション)
- [演習](#演習)
  - [演習 1: Counter のデクリメントの実装](#演習1-counterのデクリメントの実装)
  - [演習 2: Fungible トークンの transfer の実装](#演習2-fungibleトークンのtransferの実装)
  - [演習 3: Fungible トークンの transferFrom と approve の実装](#演習3-fungibleトークンのtransferfromとapproveの実装)

## インストール

ドキュメントの下記ページ（「Using Foundryup」の節）の指示に従ってインストールしてください。

https://book.getfoundry.sh/getting-started/installation#using-foundryup

2023-06-13 時点では以下のコマンドを実行することでインストールできます。

```
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Foundryup は、Foundry を使って開発を行うためのツールをまとめてインストールする CLI アプリケーションです。Rust における Rustup と同じです。

`foundryup`を実行すると、以下の 4 つのツール（コマンド）がインストールされます。

- `forge`: コントラクトをビルド・テストするツール
- `cast`: ブロックチェーンと対話するツール
- `anvil`: テストと組み合わせて使いやすい Ethereum ノード
- `chisel`: Solidity のインタラクティブシェル

各コマンドに対して一言で説明しましたが、まだピンとこないかもしれません。
まだわからなくても大丈夫です。使っていくと自然にわかるようになります。

## 使ってみる

### プロジェクトの作成

まずは、作業ディレクトリで以下のコマンドを実行してください。
`hello_foundry`というディレクトリ（プロジェクト）が作成されます。

```
forge init hello_foundry
```

### プロジェクトの構成

`hello_foundry`以下のファイル構成について説明します。
`tree -L 2`は深さ 2 までのディレクトリとファイルを表示するコマンドです。

```
$ tree -L 2
.
├── foundry.toml
├── lib
│   └── forge-std
├── script
│   └── Counter.s.sol
├── src
│   └── Counter.sol
└── test
    └── Counter.t.sol

6 directories, 4 files
```

まず、`src`がデプロイするコントラクトを置くディレクトリです。
`Counter.sol`は、デフォルトで配置されるサンプルコントラクトのファイルです。

`test`がその名の通り、`src`ディレクトリのコントラクトをテストするためのコントラクトを置くディレクトリです。

`script`は、オンチェーンと対話するためのコントラクトを置きます。
基本的には、`src`ディレクトリに置かれたコントラクトをデプロイしたいときに使います。
デプロイして、そのデプロイしたコントラクトにコールをしたり、既にデプロイ済みの別のコントラクトに何かコールをして初期設定をしたり、などです。

`lib`は、`src`/`test`/`script`で置かれているコントラクトで利用したいライブラリを配置するディレクトリです。
Foundry ではライブラリはサブモジュールとして管理されます。
初期状態では、`forge-std`という Forge のためのスタンダードライブラリがインストールされており、テストするときに重宝します。

`foundry.toml`はプロジェクトの設定について書かれています。
`src`ディレクトリの名前を変えたいときや、ブロックチェーンのパラメータを変更したいときなどに使えます。

### コントラクトのテスト

コントラクトをテストするためには、以下のコマンドを実行します。

```
forge test
```

結果は以下のようになります。

```
$ forge test
[⠆] Compiling...
[⠰] Compiling 21 files with 0.8.18
[⠘] Solc 0.8.18 finished in 4.05s
Compiler run successful!

Running 2 tests for test/Counter.t.sol:CounterTest
[PASS] testIncrement() (gas: 28334)
[PASS] testSetNumber(uint256) (runs: 256, μ: 27553, ~: 28409)
Test result: ok. 2 passed; 0 failed; finished in 32.06ms
```

`Counter.t.sol`の 2 つのテストが実行され、どちらも`PASS`しているのがわかります。

`Counter.t.sol`の中身は以下です。

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
```

`forge test`を実行すると以下のような処理が独立して走るイメージを持ってください。

- `setUp()`の実行 -> `testIncrement()`の実行
- `setUp()`の実行 -> `testSetNumber(乱数)`の実行
- `setUp()`の実行 -> `testSetNumber(乱数)`の実行
- ...
- `setUp()`の実行 -> `testSetNumber(乱数)`の実行

まず、各`test`関数の実行ごとに`setUp`関数が実行されます。
`testSetNumber`関数においては引数`uint256 x`があるため、fuzzing によるテストが実行されます。
先程の`forge test`の結果で、`[PASS] testSetNumber(uint256) (runs: 256, μ: 27553, ~: 28409)`とログが出ていましたが、`testSetNumber`が 256 回実行されたということです。

`setUp`で、`src`ディレクトリにある`Counter`コントラクトが作成され、`setNumber(0)`が実行されますが、これは要は`Counter`コントラクトの初期設定であり、その初期設定が終わったら、`test`関数でテストを行うという流れです。
`assertEq`は、`forge-std`の`Test`コントラクトの関数であり、ここで意図した状態遷移が行われたかのチェックを行っています。

### `forge test`の`-v`オプション

`forge test`でよく使うオプションとして`-v`オプションがあります。

verbosity の略で、コントラクトのコールをどれだけ詳細に表示するか、また、その詳細に表示する条件について決めるものです。

`-vv`,`-vvv`,`-vvvv`,`-vvvvv`の 4 つのオプションが設定可能です。

```
Verbosity levels:
- 2: Print logs for all tests
- 3: Print execution traces for failing tests
- 4: Print execution traces for all tests, and setup traces for failing tests
- 5: Print execution and setup traces for all tests
```

試しに`forge test -vvvvv`を実行してみてください。以下のような結果が得られます。

```
$ forge test -vvvvv
[⠔] Compiling...
No files changed, compilation skipped

Running 2 tests for test/Counter.t.sol:CounterTest
[PASS] testIncrement() (gas: 28334)
Traces:
  [106719] CounterTest::setUp()
    ├─ [49499] → new Counter@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   └─ ← 247 bytes of code
    ├─ [2390] Counter::setNumber(0)
    │   └─ ← ()
    └─ ← ()

  [28334] CounterTest::testIncrement()
    ├─ [22340] Counter::increment()
    │   └─ ← ()
    ├─ [283] Counter::number() [staticcall]
    │   └─ ← 1
    └─ ← ()

[PASS] testSetNumber(uint256) (runs: 256, μ: 27476, ~: 28409)
Traces:
  [106719] CounterTest::setUp()
    ├─ [49499] → new Counter@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   └─ ← 247 bytes of code
    ├─ [2390] Counter::setNumber(0)
    │   └─ ← ()
    └─ ← ()

  [28409] CounterTest::testSetNumber(3753)
    ├─ [22290] Counter::setNumber(3753)
    │   └─ ← ()
    ├─ [283] Counter::number() [staticcall]
    │   └─ ← 3753
    └─ ← ()

Test result: ok. 2 passed; 0 failed; finished in 20.22ms
```

各関数がどのようなパラメータで呼ばれたか等、詳細な情報が表示されるので、デバッグによく使います。
特に`-vvv`は失敗したテストに対してのみトレースが表示されることから使うことが多いです。

## 演習

### 演習 1: Counter のデクリメントの実装

以下のコマンドを実行して全てのテストがパスするように、`challenge-counter/Counter.sol`の`decrement`関数を実装してください。

```
forge test -vvv --match-path course/foundry/challenge-counter/Counter.t.sol
```

### 演習 2: Fungible トークンの`transfer`の実装

以下のコマンドを実行してテスト`testTransfer`がパスするように、Fungible トークン`challenge-token/Token.sol`の`transfer`関数を実装してください。
`transferFrom`関数と`approve`関数はまだ実装しなくても大丈夫です。
`transfer`関数の挙動は、[ERC-20 トークンの仕様](https://eips.ethereum.org/EIPS/eip-20)を参考にしてください。

```
forge test -vvv --match-path course/foundry/challenge-token/Token.t.sol --match-test testTransfer --no-match-test testTransferFrom
```

以下の点に気をつけてください。

- トークンの送金が成功したら`true`、失敗したら`false`を返すのではなくリバートさせてください。

### 演習 3: Fungible トークンの`transferFrom`と`approve`の実装

演習 2 の続きです。
以下のコマンドを実行して全てのテストがパスするように、`challenge-token/Token.sol`の`transferFrom`関数と`approve`関数を実装してください。
各関数の挙動は[ERC-20 トークンの仕様](https://eips.ethereum.org/EIPS/eip-20)を参考にしてください。

```
forge test -vvv --match-path course/foundry/challenge-token/Token.t.sol
```

以下の点に気をつけてください。

- infinite approval を実装してください。すなわち`allowance`が`type(uint256).max`に設定された場合、`transferFrom`が実行されても`allowance`を変化させないでください。
- Alice, Bob, Charlie がいる場合に、Charlie が Alice のトークンを Bob へ送金する場合もあります。
