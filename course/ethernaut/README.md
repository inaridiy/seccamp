# Ethernaut with Foundry

[Ethernaut](https://ethernaut.openzeppelin.com/)とは、Solidity で書かれたコントラクトを攻撃することで脆弱性を学べる Web サイトです。
OpenZeppelin がホストしています。
攻撃とは言っても、中には単なるパズルもあり、Solidity や EVM について理解を深めることができます。

この資料では、実際に Foundry を使って Ethernaut の問題を解いてみることで、`forge script`コマンドを利用したオンチェーンのコントラクトとの対話・攻撃の流れを学びます。

**目次**

- [Foundry を使用した Ethernaut の解法](#foundryを使用したethernautの解法)
  - [Foundry で問題を解く流れ](#foundryで問題を解く流れ)
  - [`forge script`について](#forge-scriptについて)
- [解いてみる](#解いてみる)
  - [Gatekeeper シリーズ](#gatekeeperシリーズ)
  - [13. Gatekeeper One](#13-gatekeeper-one)
  - [14. Gatekeeper Two](#14-gatekeeper-two)
  - [28. Gatekeeper Three](#28-gatekeeper-three)

## Foundry を使用した Ethernaut の解法

（Foundry について知りたい方は、このリポジトリの[course/foundry](../foundry)により詳しい説明があるので、そちらを参照してください。）

### Foundry で問題を解く流れ

まず、Ethernaut は、問題ごとにプレイヤー専用のコントラクト（インスタンスと呼ばれる）が、オンチェーンにデプロイされます。
厳密には、そのインスタンスを生成するトランザクションはプレイヤーが発行します。

そして、プレイヤーは一つあるいは複数のトランザクションを発行して、インスタンスに攻撃を行います。
この際、必要ならばコントラクトのデプロイも行う必要があります。

そのため、おすすめの問題を解く流れとしては、次のようになります。

1. `forge test`コマンドで、問題コントラクトに対してローカルで攻撃が成功するかテストする
2. 成功したら、`forge script`コマンドで、その攻撃トランザクションをオンチェーンに発行する

### `forge script`について

`forge script`は Solidity で書かれたスクリプトを元にオンチェーンにトランザクションを発行するコマンドです。
基本的には、作成した分散型アプリケーションのコントラクト群をデプロイしたり初期化したりするために使われます。

デプロイする前に、現在のステートをダウンロードして、オンチェーンでのトランザクションの実行をシミュレーションできたり、EIP-1559 を利用するかどうかを設定できたりなどの機能が揃っています。
詳しくは、Foundry ドキュメントの「[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting)」や「[forge script](https://book.getfoundry.sh/reference/forge/forge-script)」を参照してください。

## 解いてみる

### Gatekeeper シリーズ

今回は Gatekeeper シリーズを解きます。
Gatekeeper シリーズは、Gatekeeper One、Gatekeeper Two、Gatekeeper Three の 3 問で構成されています。

3 問全てのコントラクトには`enter`関数があり、この`enter`関数へのコールを成功させることがゴールです。
ただし、`enter`関数には、`gateOne`, `gateTwo`, `gateThree`という 3 つのモディファイアが修飾されており、これらモディファイアの条件を満たさないと`enter`関数の実行を成功できません。
つまり、1 つの問題にゲートという形の小問が 3 つある構成になっています。

テストとスクリプトの雛形は用意してあります。
後は、`Gatekeeper(One|Two|Three)Exploit.sol`の

```
////////// YOUR CODE GOES HERE //////////

////////// YOUR CODE END //////////
```

の部分を埋めて攻撃を完成させるだけです。

どの問題も初見で解くのは中々難しいです。
そのため、1 問目と 2 問目には各ゲートごとにヒントを用意しています。
詰まったらこのヒントを利用することをおすすめします。
補足には知らなくても解けるけど知っておいたほうが良い情報を書いています。

### 13. Gatekeeper One

問題リンク: https://ethernaut.openzeppelin.com/level/0x2a2497aE349bCA901Fea458370Bd7dDa594D1D69

テスト:

```sh
forge test --match-contract GatekeeperOneExploitTest -vvv
```

スクリプト:

```sh
export PRIVATE_KEY=<PRIVATE_KEY>
export RPC_URL=<RPC_URL>
export FOUNDRY_ETH_RPC_URL=$RPC_URL
export INSTANCE_ADDRESS=<INSTANCE_ADDRESS>
```

```sh
forge script GatekeeperOneExploitScript --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" $INSTANCE_ADDRESS -vvv
```

<details>
<summary>gateOneのヒント1</summary>

- `tx.origin`: トランザクションの発行者アドレス。
- `msg.sender`: コントラクトコールの呼び出しアドレス。

</details>

<details>
<summary>gateOneのヒント2</summary>

EOA から`entry`関数を呼び出すと`msg.sender`と`tx.origin`が EOA のアドレスになってしまう。
ということは……？

</details>

<details>
<summary>gateOneの補足</summary>

`tx.origin`は EVM の`ORIGIN`命令にコンパイルされ、`msg.sender`は`CALLER`命令にコンパイルされる。

</details>

<details>
<summary>gateTwoのヒント1</summary>

`gasleft()`は残りのガスを返す。
闇雲に`entry`を呼び出しても 1/8191 の確率でしか成功しない。

</details>

<details>
<summary>gateTwoのヒント2</summary>

コントラクトコールの際にガスを指定することで攻略できないだろうか。

</details>

<details>
<summary>gateTwoのヒント3</summary>

例えば 1000 ガスで関数`foo`を呼び出すには、`foo{gas: 1000}()`とすれば良い。

</details>

<details>
<summary>gateTwoのヒント4</summary>

`enter`関数の実行から`gasleft()`の実行までの間のガス消費量は一定だと予測できる。
ということは、`{gas: amount}`構文を使って、`gasleft() % 8191 == 0`を満たせる`amount`を全探索すればいい

</details>

<details>
<summary>gateTwoのヒント5</summary>

`entry{gas: amount}`を使って全探索すると、`entry`関数がリバートしたときトランザクションもリバートしてしまう。
`entry`関数が失敗しても処理を続行するためには……？

</details>

<details>
<summary>gateTwoの補足</summary>

`gasleft()`は`GAS`命令にコンパイルされる。
`GAS`命令を実行されると、`GAS`命令実行後の残りのガスがスタックにプッシュされる。

</details>

<details>
<summary>gateThreeのヒント1</summary>

`uint64(_gateKey)`が`0x1122334455667788`だったときを考えてみよう。

```
uint32(uint64(_gateKey)): 0x0000000055667788
uint16(uint64(_gateKey)): 0x0000000000007788
```

</details>

<details>
<summary>gateThreeのヒント2</summary>

`tx.origin`はトランザクション発行者のアドレスで 20 バイト（160 ビット）。
`uint160(tx.origin)`はそれを非負整数に直すということ。
その値を`uint16`に変換した値と`uint32(uint64(_gateKey))`を一致させるには……？

</details>

<details>
<summary>解法</summary>

https://github.com/minaminao/ctf-blockchain/blob/main/src/Ethernaut/GatekeeperOne/GatekeeperOneExploit.sol

</details>

### 14. Gatekeeper Two

問題リンク: https://ethernaut.openzeppelin.com/level/0xf59112032D54862E199626F55cFad4F8a3b0Fce9

テスト:

```sh
forge test --match-contract GatekeeperTwoExploitTest -vvv
```

スクリプト:

```sh
export INSTANCE_ADDRESS=<INSTANCE_ADDRESS>
```

```sh
forge script GatekeeperTwoExploitScript --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" $INSTANCE_ADDRESS -vvv
```

<details>
<summary>gateTwoのヒント1</summary>

`assembly { ... }`はインラインアセンブリブロックと呼ばれる。
括弧の中は Yul 言語で記述され、EVM のニーモニックを使用できるようになる。
（詳しくは Solidity ドキュメントの「[インラインアセンブリ](https://solidity-ja.readthedocs.io/ja/latest/assembly.html)」を参照。）

</details>

<details>
<summary>gateTwoのヒント2</summary>

`extcodesize(address)`で`address`のコードサイズを取得する。
`caller()`はコントラクトコールの呼び出しアドレスを取得する。
つまり、`extcodesize(caller())`でコントラクトコールの呼び出しアドレスのコードサイズを取得している。

</details>

<details>
<summary>gateTwoのヒント3</summary>

`gateOne`を満たすためには、コントラクトから`entry`関数を呼ばなくてはいけなかった。
でも、普通にコントラクトから`entry`関数を呼ぶと、`extcodesize(caller())`が`0`にならない。
では、どうしたらいいか……？

</details>

<details>
<summary>gateTwoのヒント4</summary>

`EXTCODESIZE`命令の仕様を詳しく調べてみよう。

</details>

<details>
<summary>gateThreeのヒント1</summary>

`abi.encodePacked(msg.sender)`は、
それの`keccak256`ハッシュを取得している

</details>

<details>
<summary>gateThreeのヒント2</summary>

`bytes32`の値を`bytes8`に変換すると先頭 8 バイトが得られる。

</details>

<details>
<summary>gateThreeのヒント3</summary>

`_gateKey`を逆算するにはどうしたらよいか……？

</details>

<details>
<summary>解法</summary>

https://github.com/minaminao/ctf-blockchain/blob/main/src/Ethernaut/GatekeeperTwo/GatekeeperTwoExploit.sol

</details>

### 28. Gatekeeper Three

問題リンク: https://ethernaut.openzeppelin.com/level/0x03aFA729959cDB6EA3fAD8572b718E88df0594af

テスト:

```sh
forge test --match-contract GatekeeperThreeExploitTest -vvv
```

スクリプト:

```sh
export INSTANCE_ADDRESS=<INSTANCE_ADDRESS>
```

```sh
forge script GatekeeperThreeExploitScript --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" $INSTANCE_ADDRESS -vvv
```

<details>
<summary>解法</summary>

https://github.com/minaminao/ctf-blockchain/blob/main/src/Ethernaut/GatekeeperThree/GatekeeperThreeExploit.sol

</details>
