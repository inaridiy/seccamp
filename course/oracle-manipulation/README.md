<<<<<<< HEAD

# Oracle Manipulation Attack & Flash Loan

**目次**

- [オラクルとは](#オラクルとは)
- [Oracle Manipulation Attack とは](#oracle-manipulation-attackとは)
- [Oracle Manipulation Attack の具体例](#oracle-manipulation-attackの具体例)
  - [演習](#演習)
- [Oracle Manipulation Attack の対策](#oracle-manipulation-attackの対策)
  - [Time Weighted Average Pricing (TWAP)](#time-weighted-average-pricing-twap)
  - [非中央集権型オラクル](#非中央集権型オラクル)
- [Flash Loan とは](#flash-loanとは)
  - [演習](#演習-1)
- [Flash Loan を利用した Oracle Manipulation Attack](#flash-loanを利用したoracle-manipulation-attack)
  - [演習](#演習-2)

## オラクルとは

Oracle Manipulation Attack の説明をする前に、簡単にオラクル（oracle）について説明します。

ブロックチェーンにおけるオラクルとは、狭義には、オンチェーン（= チェーン内）のスマートコントラクトに、オフチェーン（= チェーン外）の情報を提供するプロトコルのことです。
広義には、オンチェーンだけで収集できる情報を加工して提供する関数やコントラクトもオラクルと呼びます。

ブロックチェーンの仕組み上、コントラクトはブロックチェーンの外で起こっている情報を得るために、オフチェーンの主体に依存する必要があります。
例えば、現実世界の天気や株式の価格などは、ブロックチェーン上に存在しないため、誰かが提供する必要があります。
これをオラクル問題と呼びます。

オラクル問題を非中央集権的に解決するために、オフチェーンの情報をオンチェーンに非中央集権的にコミットするプロトコルがあり、非中央集権型オラクル（Decentralized Oracle）と呼ばれます。
代表的な非中央集権型オラクルのプロトコルに[Chainlink](https://chain.link/)があります。
非中央集権型オラクルについては、後で詳しく説明します。

## Oracle Manipulation Attack とは

Oracle Manipulation Attack とは、オラクルを故意に操作することでオラクルを利用するプロトコルからトークンの奪取などを行う攻撃の総称です。
特に、オラクルの広義の意味に含まれる「オンチェーンだけで収集できる情報を加工して提供する関数やコントラクト」は適切な利用を行わないと、この種の攻撃に脆弱になりやすいです。

## Oracle Manipulation Attack の具体例

Oracle Manipulation Attack の単純な例を説明します。

まず、ユーザー、レンディングプロトコル、オラクルの 3 つのパーティーがいるとしましょう。
ユーザーは、レンディングプロトコルにいくらかの ETH をデポジットすれば、ある閾値までの USDC を借りることができます。
レンディングプロトコルは、USDC/ETH の価格を提供するオラクルを利用して、その閾値を決定します。
オラクルは具体的には、Uniswap などの AMM を想定してもらって構いません。

悪意のない一般ユーザーがレンディングプロトコルから資産を借りる流れは以下の図のようになります。
（通常の矢印がアクションで、点線の矢印が単なる返り値を表しています。）

```mermaid
sequenceDiagram
    participant User
    participant Lending
    participant Oracle

	User ->> Lending: 10 ETHデポジット
	User ->>+ Lending: 15,000 USDC貸して
	Lending ->>+ Oracle: USDC/ETHの値は？
	Oracle -->>- Lending: 2,000 USDC/ETH
	Note over Lending: Collateral Factor (75%)による条件チェック<br>2,000 * 10 * 0.75 = 15,000 USDC
	Lending ->>- User: 15,000 USDC送金
```

さて、ここでオラクルを操作することで何か攻撃を行うことはできないでしょうか？

もしオラクルが提供する価格を操作できるとしましょう。
そうすると、本来借りれるはずの額よりも大きな額の USDC を借りれてしまいます。
例えば、USDC/ETH の価格が現在の倍の 4,000 USDC/ETH に出来たら、30,000 USDC 借りることが出来ます。
攻撃者はその USDC を返さなければ、結果として、30,000 USDC - 2,000 USDC/ETH \* 10 ETH = 10,000 USDC を利益にできてしまいます。

図に表すと以下の流れになります。

```mermaid
sequenceDiagram
    participant Attacker
    participant Lending
    participant Oracle

	Attacker ->> Oracle: (何かしらの操作)
	Attacker ->> Lending: 10 ETHデポジット
	Attacker ->>+ Lending: 30,000 USDC貸して
	Lending ->>+ Oracle: USDC/ETHの値は？
	Oracle -->>- Lending: 4,000 USDC/ETH
	Note over Lending: Collateral Factor (75%)による条件チェック<br>4,000 * 10 * 0.75 = 30,000 USDC
	Lending ->>- Attacker: 30,000 USDC送金
```

それでは、オラクルへの具体的な操作は何が考えられるでしょうか？

オラクルの実態は取引所なので、ETH を大量に買い上げれば USDC/ETH の値が上がるでしょう。

その取引所の価格決定アルゴリズムが $xy = k$ 型で、USDC-ETH プールにある USDC と ETH の総量がそれぞれ、20,000,000 USDC と 10,000 ETH だとします。
もし 2,000 USDC/ETH から 4,000 USDC/ETH になったときの ETH の量を $x$ とすれば、 $4000 x^2 = 20000000 \times 10000$ を満たします。
$x$ を求めると $7071$ 程度になります。
一方で USDC の量は、 $4000x = 28284000$ 程度です。
つまり、8,284,000 USDC を所持していれば価格を 4,000 USDC/ETH に釣り上げることが可能です。

USDC-ETH プールの交換手数料を 0.3 %とすると、ざっくりと 8,284,000 USDC _ 0.3 % _ 2 回 = 49,704 USDC の手数料がかかります。
攻撃者の利益はレンディングプロトコルが持つ USDC の総量の 1/3 であるため、その総量が約 49,704 \* 3 = 149,112 USDC 以上であれば、攻撃者は利益を得られることになります。

最終的に残った ETH を USDC に戻せば攻撃完了です。

この攻撃の流れを図に表すと次のようになります。
8,284,000 や 7,071 のような数値は $x,y$ などの記号にしています。

```mermaid
sequenceDiagram
    participant Attacker
    participant Lending
    participant AMM

	Attacker ->>+ AMM: x USDCをETHに交換して
	AMM ->>- Attacker: y ETH送金
	Attacker ->> Lending: 100 ETHデポジット
	Attacker ->>+ Lending: 300,000 USDC貸して
	Lending ->>+ AMM: USDC/ETHの値は？
	AMM -->>- Lending: 4,000 USDC/ETH
	Note over Lending: Collateral Factor (75%)による条件チェック<br>4,000 * 100 * 0.75 = 300,000 USDC
	Lending ->>- Attacker: 300,000 USDC送金
	Attacker ->>+ AMM: y' ETHをUSDCに交換して
	AMM ->>- Attacker: x' USDC送金
```

この攻撃では、一つ攻撃者にとって問題点があります。
それは、攻撃者が 8,284,000 USDC を用意しなくてはならない点です。
しかし、後述する Flash Loan と組み合わせることで、攻撃者は無一文でも攻撃を行うことができます（厳密にはトランザクション手数料分の ETH を保持している必要があります）。

### 演習

問題ディレクトリ: [challenge-oracle-manipulation](challenge-oracle-manipulation)

プレイヤーは`A`トークンを初期状態で 9,000,000 持っています。
`Challenge.sol`の`LendingPool`コントラクトに対して Oracle Manipulation Attack を行い、`A`トークンを全て排出して、プレイヤーのトークン`A`の総量を 9,100,000 以上にしてください。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/oracle-manipulation/challenge-oracle-manipulation/Challenge.t.sol
```

## Oracle Manipulation Attack の対策

Oracle Manipulation Attack の対策として、「Time Weighted Average Pricing (TWAP)」と「非中央集権型オラクル」の 2 つの技術を紹介します。

### Time Weighted Average Pricing (TWAP)

TWAP は、複数のブロックの価格の平均を取ることで価格を決定するアルゴリズムです。
TWAP は Uniswap などのプロトコルで提供されています。

例えば、ある時点 $i$ での価格を $P_i$ とすると、 $[a,a+1,\ldots,b-1]$ の TWAP は次のように表せます。

$$\mathrm{TWAP} = \frac{P_{a}+P_{a+1}+\cdots + P_{b-1}}{b-a}$$

この TWAP を導入することで、先程紹介したような Oracle Manipulation Attack を防ぐことができます。

まず、TWAP を導入すれば、現在のトランザクション（あるいはブロック）の時点での価格だけ操作しても、価格を適正価格から大きく乖離できずに攻撃が失敗します。
具体的には、ある時点での価格操作の影響が $\frac{1}{b-a}$ になってしまいます。

次に、そもそも現在のブロックの価格が TWAP の計算に含まれないような TWAP の場合は、そもそも価格への影響はありません。

さらに、攻撃を 2 つ以上のトランザクションに分けて TWAP を操作しようとしても、すぐに他のユーザーによるアービトラージが行われ、適正価格に修正されてしまいます。
適正価格に修正されると、何度も不利な価格でスワップすることになります。
結局、そのような攻撃は非常に高いコストがかかるため、攻撃しても損するだけでインセンティブがありません。

特に、Oracle Manipulation Attack は後述する Flash Loan と組み合わせられることがほとんどであり、Flash Loan を利用すると 1 トランザクションで攻撃を完結させないといけないため、TWAP は強力な対策の一つです。

また、TWAP は価格決定アルゴリズムの中では非常にシンプルであるため、オンチェーンで実装する上で相性が良いというメリットもあります。

ただし、急激な価格変化にすぐに追いつけないという性質はあります。

### 非中央集権型オラクル

Chainlink などは、複数のある程度信頼できるパーティーからの価格データを収集し、そのデータをオンチェーンにコミットするプロトコルを非中央集権的に運用しています。
この非中央集権型オラクルを利用することでも、先程紹介したような Oracle Manipulation Attack を防ぐことがきます。

Chainlink のノードがオンチェーンに価格データをコミットしなくてはならないため、チェーンが混雑しているときは、価格更新トランザクションがすぐに実行されない可能性があります。

## Flash Loan とは

Flash Loan とは、トランザクションの終了までに借りた資産が返却される限り、無担保で資産を借入できるローンのことです。
借り手は、そのトランザクション内で借りた資産をどのように扱っても良いです。
手数料は発生しますが、借りた期間に基づく利子はありません。

Flash Loan は Uniswap を始めとする様々な取引所で提供されています。

例えば、10,000 WETH を借りる Flash Loan は次のようなイメージです。

```mermaid
sequenceDiagram
    participant User
    participant FlashLoanProvider

	User ->>+ FlashLoanProvider: 10,000 WETH借して
	FlashLoanProvider ->>+ User: 10,000 WETH
	Note over User: 任意の処理
	User ->>- FlashLoanProvider: (10,000 + fee) WETH
	FlashLoanProvider -->>- User: (Flash Loan終了)
```

### 演習

問題ディレクトリ: [challenge-flash-loan](challenge-flash-loan)

Uniswap V2 のフラッシュローン（Flash Swap と呼びます）を使って、`Flag`コントラクトの`solved`フラグを立ててください。
Flash Swap の使い方は、[Uniswap のドキュメント](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps)を参照してください。

今までの演習問題と異なり、メインチェーンをフォークしていることに注意してください。

Flash Loan を行う際に使えるアドレスを参考までに載せておきます（これらアドレスを使わなくても構いません）。

- WETH のアドレス: `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`
- USDC-WETH Pair のアドレス: `0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc`

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/oracle-manipulation/challenge-flash-loan/Challenge.t.sol
```

## Flash Loan を利用した Oracle Manipulation Attack

最初の紹介した Oracle Manipulation Attack では、攻撃者が初期状態で大量の USDC を持っている必要がありました。
しかし、今紹介した Flash Loan を利用することで、攻撃に必要な資産を準備する必要はもうありません。

Flash Loan と組み合わせたときの Oracle Manipulation Attack は次のようなイメージになります。

```mermaid
sequenceDiagram
	participant FlashLoanProvider
    participant Attacker
    participant Lending
    participant AMM

	Attacker ->>+ FlashLoanProvider: x USDC貸して
	FlashLoanProvider ->>+ Attacker: x USDC送金
	Attacker ->>+ AMM: x USDCをETHに交換して
	AMM ->>- Attacker: y ETH送金
	Attacker ->> Lending: 100 ETHデポジット
	Attacker ->>+ Lending: 300,000 USDC貸して
	Lending ->>+ AMM: USDC/ETHの値は？
	AMM -->>- Lending: 4,000 USDC/ETH
	Note over Lending: Collateral Factor (75%)による条件チェック<br>4,000 * 100 * 0.75 = 300,000 USDC
	Lending ->>- Attacker: 300,000 USDC送金
	Attacker ->>+ AMM: y' ETHをUSDCに交換して
	AMM ->>- Attacker: x' USDC送金
	Attacker ->>- FlashLoanProvider: (x + fee) USDC送金
	FlashLoanProvider -->>- Attacker: (Flash Loan終了)
```

### 演習

問題ディレクトリ: [challenge-oracle-manipulation-with-flash-loan](challenge-oracle-manipulation-with-flash-loan)

最初の演習と異なり、プレイヤーは`A`トークンを初期状態で所持していません。
今回の問題でもメインネットをフォークしています。
それに加えて、`A`トークンに`USDC`が、`B`トークンに`WETH`が割り当てられています。

`Challenge.sol`の`LendingPool`コントラクトに対して、Flash Loan を用いた Oracle Manipulation Attack を行い`USDC`を全て排出して、プレイヤーの`USDC`の総量を 100,000 以上にしてください。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/oracle-manipulation/challenge-oracle-manipulation-with-flash-loan/Challenge.t.sol
```

=======

# Oracle Manipulation Attacks & Flash Loans

**目次**

- [オラクルとは](#オラクルとは)
- [Oracle Manipulation Attack とは](#oracle-manipulation-attackとは)
- [Oracle Manipulation Attack の具体例](#oracle-manipulation-attackの具体例)
  - [演習](#演習)
- [Oracle Manipulation Attack の対策](#oracle-manipulation-attackの対策)
  - [Time Weighted Average Pricing (TWAP)](#time-weighted-average-pricing-twap)
  - [非中央集権型オラクル](#非中央集権型オラクル)
- [Flash Loan とは](#flash-loanとは)
  - [演習](#演習-1)
- [Flash Loan を利用した Oracle Manipulation Attack](#flash-loanを利用したoracle-manipulation-attack)
  - [演習](#演習-2)

## オラクルとは

Oracle Manipulation Attack の説明をする前に、簡単にオラクル（oracle）について説明します。

ブロックチェーンにおけるオラクルとは、狭義には、オンチェーン（= チェーン内）のスマートコントラクトに、オフチェーン（= チェーン外）の情報を提供するプロトコルのことです。
広義には、オンチェーンだけで収集できる情報を加工して提供する関数やコントラクトもオラクルと呼びます。

ブロックチェーンの仕組み上、コントラクトはブロックチェーンの外で起こっている情報を得るために、オフチェーンの主体に依存する必要があります。
例えば、現実世界の天気や株式の価格などは、ブロックチェーン上に存在しないため、誰かが提供する必要があります。
これをオラクル問題と呼びます。

オラクル問題を非中央集権的に解決するために、オフチェーンの情報をオンチェーンに非中央集権的にコミットするプロトコルがあり、非中央集権型オラクル（Decentralized Oracle）と呼ばれます。
代表的な非中央集権型オラクルのプロトコルに[Chainlink](https://chain.link/)があります。
非中央集権型オラクルについては、後で詳しく説明します。

## Oracle Manipulation Attack とは

Oracle Manipulation Attack とは、オラクルを故意に操作することでオラクルを利用するプロトコルからトークンの奪取などを行う攻撃の総称です。
特に、オラクルの広義の意味に含まれる「オンチェーンだけで収集できる情報を加工して提供する関数やコントラクト」は適切な利用を行わないと、この種の攻撃に脆弱になりやすいです。

## Oracle Manipulation Attack の具体例

Oracle Manipulation Attack の単純な例を説明します。

まず、ユーザー、レンディングプロトコル、オラクルの 3 つのパーティーがいるとしましょう。
ユーザーは、レンディングプロトコルにいくらかの ETH をデポジットすれば、ある閾値までの USDC を借りることができます。
レンディングプロトコルは、USDC/ETH の価格を提供するオラクルを利用して、その閾値を決定します。
オラクルは具体的には、Uniswap などの AMM を想定してもらって構いません。

悪意のない一般ユーザーがレンディングプロトコルから資産を借りる流れは以下の図のようになります。
（通常の矢印がアクションで、点線の矢印が単なる返り値を表しています。）

```mermaid
sequenceDiagram
    participant User
    participant Lending
    participant Oracle

	User ->> Lending: 10 ETHデポジット
	User ->>+ Lending: 15,000 USDC貸して
	Lending ->>+ Oracle: USDC/ETHの値は？
	Oracle -->>- Lending: 2,000 USDC/ETH
	Note over Lending: Collateral Factor (75%)による条件チェック<br>2,000 * 10 * 0.75 = 15,000 USDC
	Lending ->>- User: 15,000 USDC送金
```

さて、ここでオラクルを操作することで何か攻撃を行うことはできないでしょうか？

もしオラクルが提供する価格を操作できるとしましょう。
そうすると、本来借りれるはずの額よりも大きな額の USDC を借りれてしまいます。
例えば、USDC/ETH の価格が現在の倍の 4,000 USDC/ETH に出来たら、30,000 USDC 借りることが出来ます。
攻撃者はその USDC を返さなければ、結果として、30,000 USDC - 2,000 USDC/ETH \* 10 ETH = 10,000 USDC を利益にできてしまいます。

図に表すと以下の流れになります。

```mermaid
sequenceDiagram
    participant Attacker
    participant Lending
    participant Oracle

	Attacker ->> Oracle: (何かしらの操作)
	Attacker ->> Lending: 10 ETHデポジット
	Attacker ->>+ Lending: 30,000 USDC貸して
	Lending ->>+ Oracle: USDC/ETHの値は？
	Oracle -->>- Lending: 4,000 USDC/ETH
	Note over Lending: Collateral Factor (75%)による条件チェック<br>4,000 * 10 * 0.75 = 30,000 USDC
	Lending ->>- Attacker: 30,000 USDC送金
```

それでは、オラクルへの具体的な操作は何が考えられるでしょうか？

オラクルの実態は取引所なので、ETH を大量に買い上げれば USDC/ETH の値が上がるでしょう。

その取引所の価格決定アルゴリズムが $xy = k$ 型で、USDC-ETH プールにある USDC と ETH の総量がそれぞれ、20,000,000 USDC と 10,000 ETH だとします。
もし 2,000 USDC/ETH から 4,000 USDC/ETH になったときの ETH の量を $x$ とすれば、 $4000 x^2 = 20000000 \times 10000$ を満たします。
$x$ を求めると $7071$ 程度になります。
一方で USDC の量は、 $4000x = 28284000$ 程度です。
つまり、8,284,000 USDC を所持していれば価格を 4,000 USDC/ETH に釣り上げることが可能です。

USDC-ETH プールの交換手数料を 0.3 %とすると、ざっくりと 8,284,000 USDC _ 0.3 % _ 2 回 = 49,704 USDC の手数料がかかります。
攻撃者の利益はレンディングプロトコルが持つ USDC の総量の 1/3 であるため、その総量が約 49,704 \* 3 = 149,112 USDC 以上であれば、攻撃者は利益を得られることになります。

最終的に残った ETH を USDC に戻せば攻撃完了です。

この攻撃の流れを図に表すと次のようになります。
8,284,000 や 7,071 のような数値は $x,y$ などの記号にしています。

```mermaid
sequenceDiagram
    participant Attacker
    participant Lending
    participant AMM

	Attacker ->>+ AMM: x USDCをETHに交換して
	AMM ->>- Attacker: y ETH送金
	Attacker ->> Lending: 100 ETHデポジット
	Attacker ->>+ Lending: 300,000 USDC貸して
	Lending ->>+ AMM: USDC/ETHの値は？
	AMM -->>- Lending: 4,000 USDC/ETH
	Note over Lending: Collateral Factor (75%)による条件チェック<br>4,000 * 100 * 0.75 = 300,000 USDC
	Lending ->>- Attacker: 300,000 USDC送金
	Attacker ->>+ AMM: y' ETHをUSDCに交換して
	AMM ->>- Attacker: x' USDC送金
```

この攻撃では、一つ攻撃者にとって問題点があります。
それは、攻撃者が 8,284,000 USDC を用意しなくてはならない点です。
しかし、後述する Flash Loan と組み合わせることで、攻撃者は無一文でも攻撃を行うことができます（厳密にはトランザクション手数料分の ETH を保持している必要があります）。

### 演習

問題ディレクトリ: [challenge-oracle-manipulation](challenge-oracle-manipulation)

プレイヤーは`A`トークンを初期状態で 9,000,000 持っています。
`Challenge.sol`の`LendingPool`コントラクトに対して Oracle Manipulation Attack を行い、`A`トークンを全て排出して、プレイヤーのトークン`A`の総量を 9,100,000 以上にしてください。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/oracle-manipulation/challenge-oracle-manipulation/Challenge.t.sol
```

## Oracle Manipulation Attack の対策

Oracle Manipulation Attack の対策として、「Time Weighted Average Pricing (TWAP)」と「非中央集権型オラクル」の 2 つの技術を紹介します。

### Time Weighted Average Pricing (TWAP)

TWAP は、複数のブロックの価格の平均を取ることで価格を決定するアルゴリズムです。
TWAP は Uniswap などのプロトコルで提供されています。

例えば、ある時点 $i$ での価格を $P_i$ とすると、 $[a,a+1,\ldots,b-1]$ の TWAP は次のように表せます。

$$\mathrm{TWAP} = \frac{P_{a}+P_{a+1}+\cdots + P_{b-1}}{b-a}$$

この TWAP を導入することで、先程紹介したような Oracle Manipulation Attack を防ぐことができます。

まず、TWAP を導入すれば、現在のトランザクション（あるいはブロック）の時点での価格だけ操作しても、価格を適正価格から大きく乖離できずに攻撃が失敗します。
具体的には、ある時点での価格操作の影響が $\frac{1}{b-a}$ になってしまいます。

次に、そもそも現在のブロックの価格が TWAP の計算に含まれないような TWAP の場合は、そもそも価格への影響はありません。

さらに、攻撃を 2 つ以上のトランザクションに分けて TWAP を操作しようとしても、すぐに他のユーザーによるアービトラージが行われ、適正価格に修正されてしまいます。
適正価格に修正されると、何度も不利な価格でスワップすることになります。
結局、そのような攻撃は非常に高いコストがかかるため、攻撃しても損するだけでインセンティブがありません。

特に、Oracle Manipulation Attack は後述する Flash Loan と組み合わせられることがほとんどであり、Flash Loan を利用すると 1 トランザクションで攻撃を完結させないといけないため、TWAP は強力な対策の一つです。

また、TWAP は価格決定アルゴリズムの中では非常にシンプルであるため、オンチェーンで実装する上で相性が良いというメリットもあります。

ただし、急激な価格変化にすぐに追いつけないという性質はあります。

### 非中央集権型オラクル

Chainlink などは、複数のある程度信頼できるパーティーからの価格データを収集し、そのデータをオンチェーンにコミットするプロトコルを非中央集権的に運用しています。
この非中央集権型オラクルを利用することでも、先程紹介したような Oracle Manipulation Attack を防ぐことがきます。

Chainlink のノードがオンチェーンに価格データをコミットしなくてはならないため、チェーンが混雑しているときは、価格更新トランザクションがすぐに実行されない可能性があります。

## Flash Loan とは

Flash Loan とは、トランザクションの終了までに借りた資産が返却される限り、無担保で資産を借入できるローンのことです。
借り手は、そのトランザクション内で借りた資産をどのように扱っても良いです。
手数料は発生しますが、借りた期間に基づく利子はありません。

Flash Loan は Uniswap を始めとする様々な取引所で提供されています。

例えば、10,000 WETH を借りる Flash Loan は次のようなイメージです。

```mermaid
sequenceDiagram
    participant User
    participant FlashLoanProvider

	User ->>+ FlashLoanProvider: 10,000 WETH借して
	FlashLoanProvider ->>+ User: 10,000 WETH
	Note over User: 任意の処理
	User ->>- FlashLoanProvider: (10,000 + fee) WETH
	FlashLoanProvider -->>- User: (Flash Loan終了)
```

### 演習

問題ディレクトリ: [challenge-flash-loan](challenge-flash-loan)

Uniswap V2 のフラッシュローン（Flash Swap と呼びます）を使って、`Flag`コントラクトの`solved`フラグを立ててください。
Flash Swap の使い方は、[Uniswap のドキュメント](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps)を参照してください。

今までの演習問題と異なり、メインチェーンをフォークしていることに注意してください。

Flash Loan を行う際に使えるアドレスを参考までに載せておきます（これらアドレスを使わなくても構いません）。

- WETH のアドレス: `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`
- USDC-WETH Pair のアドレス: `0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc`

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/oracle-manipulation/challenge-flash-loan/Challenge.t.sol
```

## Flash Loan を利用した Oracle Manipulation Attack

最初の紹介した Oracle Manipulation Attack では、攻撃者が初期状態で大量の USDC を持っている必要がありました。
しかし、今紹介した Flash Loan を利用することで、攻撃に必要な資産を準備する必要はもうありません。

Flash Loan と組み合わせたときの Oracle Manipulation Attack は次のようなイメージになります。

```mermaid
sequenceDiagram
	participant FlashLoanProvider
    participant Attacker
    participant Lending
    participant AMM

	Attacker ->>+ FlashLoanProvider: x USDC貸して
	FlashLoanProvider ->>+ Attacker: x USDC送金
	Attacker ->>+ AMM: x USDCをETHに交換して
	AMM ->>- Attacker: y ETH送金
	Attacker ->> Lending: 100 ETHデポジット
	Attacker ->>+ Lending: 300,000 USDC貸して
	Lending ->>+ AMM: USDC/ETHの値は？
	AMM -->>- Lending: 4,000 USDC/ETH
	Note over Lending: Collateral Factor (75%)による条件チェック<br>4,000 * 100 * 0.75 = 300,000 USDC
	Lending ->>- Attacker: 300,000 USDC送金
	Attacker ->>+ AMM: y' ETHをUSDCに交換して
	AMM ->>- Attacker: x' USDC送金
	Attacker ->>- FlashLoanProvider: (x + fee) USDC送金
	FlashLoanProvider -->>- Attacker: (Flash Loan終了)
```

### 演習

問題ディレクトリ: [challenge-oracle-manipulation-with-flash-loan](challenge-oracle-manipulation-with-flash-loan)

最初の演習と異なり、プレイヤーは`A`トークンを初期状態で所持していません。
今回の問題でもメインネットをフォークしています。
それに加えて、`A`トークンに`USDC`が、`B`トークンに`WETH`が割り当てられています。

`Challenge.sol`の`LendingPool`コントラクトに対して、Flash Loan を用いた Oracle Manipulation Attack を行い`USDC`を全て排出して、プレイヤーの`USDC`の総量を 100,000 以上にしてください。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/oracle-manipulation/challenge-oracle-manipulation-with-flash-loan/Challenge.t.sol
```

> > > > > > > 1893cfbb57801e8e23744935553aa2e89eb8c99d
