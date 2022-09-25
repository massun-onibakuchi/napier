# Napier Finance - Yield Stripping app featuring the most efficient AMM

NOTE: This code is not audited and should not be used in production environment.
The repository is under continuous development.

## Summary

### Introducing Napier Finance

Napier Finance is a fully decentralized yield stripping protocol that enables users to trade fixed and variable rates most efficiently.

The competitive advantage, Napier Space AMM featuring unified liquidity is the most capital efficient AMM for any yield source and Principal token of other protocols.

### Our Solution : Unified Principal Tokens Liquidity

Napier Finance introduces a unique unified liquidity AMM concept to the DeFi yield tokenization space. When providing liquidity, virtually calculate various yield source of Principal Tokens as one Napier Principal Token in the case with same underlying, same maturity, different yield source.

As a result, the LP's average exchange fee APY increases several times. Basically better LP profitability attracts liquidity, which in turn attracts less slippage.

![PoPV](./docs/napiermechanics.png)

In addition, with the more exponential birth of yield-producing protocols, the more Napier's ecosystem is expected to grow.

![PoPV](./docs/napierecosystem.png)

## Requirements

[Foundry](https://book.getfoundry.sh/)

To run tests you need access to an archive node like the free ones from [Alchemy](https://alchemyapi.io/). Create `.env` file and set the environment variables.

```bash
RPC_URL=<Mainnet rpc url>
POLYGON_RPC_URL=<Polygon mainnet rpc url>
```

- Compiling : `forge build`
- Testing : `forge test -vvv`
- Deployments : `forge script scripts/deploy_mainnet.s.sol --broadcast --rpc-url=$RPC_URL`

## Overview

![FF](./docs/napierflowdiagram.png)

#### Tranche

`Tranche` is responsible for issuing/redeeming each Principal Token.
`nPT` is an indexed-token, which is composed of some Prinicipal Tokens with same maturity such as aDAI-PT-1231 and cDAI-PT-1231.

#### NapierPool

`NapierPool` is AMM pool whose pair is nPT and its underlying token. Pools aggregates liquiditites and make a more profit to liquidity providers.
This AMM invariant works well for assets that converge in value over time. (ref: Yield Space)

#### NapierPoolFactory

`NapierPoolFactorly` deploys NapierPool. The pool address is deterministically derived using CREATE2 opecode based on its pair addressess.

#### Adapters

`Adapter` is a yield source wrapper which allows tranche to deposit underlying to lending protocols and withdraw underlying from those.
following adapters are available.

- CompoundAdapter
- AaveV2Adapter
- AaveV3Adapter
- EulerAdapter
- YearnAdapter

## Deployed contracts

### Polygon Mumbai

| Contract            | Address                                    |
| -------------------- | ------------------------------------------ |
| WMATIC               | 0xb685400156cF3CBE8725958DeAA61436727A30c3 |
| Tranche-WMATIC       | 0x08618ec28aed8d77c7eef35ab910f190270b9aa1 |
| AaveV3Adapter-WMATIC | 0xb6555260a3520ff7e8d2579ace6ffd0f8fea1632 |
| NapierPoolFactory    | 0xc31c71178c49b6be3af84a1fdd3fe0a21883d788 |
| NapierPool           | 0x58ab2Af4b8d36acC00b87C5e72be1Ac47582cf67 |

### Goerli

| Contract         | Address                                    |
| ----------------- | ------------------------------------------ |
| DAI               | 0x75Ab5AB1Eef154C0352Fc31D2428Cef80C7F8B33 |
| Tranche-DAI       | 0x9dd54eb8a6346ad877729f91489467dca36637d2 |
| AaveV2Adapter-DAI | 0xec54d0a24ec021985cbe0d046e9ffba37eee2343 |
| NapierPoolFactory | 0x4aab57b52cbf7be3b35f1994243b21120530d939 |
| NapierPool        | 0xCd2E0B6B1F18DDA37d33772D775C48D5D292C296 |

## Feature to be implemented

- Large size order processing like Just-in-time (JIT) liquidity of UniswapV3
- Implementation of price manipulation resistance like Uniswap's TWAP
- Setting yield source tiers according to risk level
- Token economics to optimize pool reserves

## FAQ

- What is Napier Principal token?

Napier Principal Token are tokens that the system calculates various principal tokens as a single principal tokens, in the case with same underlying assets, same maturity, different yield sources). So it is just virtual token and non-transferable token.

- How do Napier set maturity date?

In Napier, all various pools begin maturity at the same time.

- How do “unified liquidity AMM” work?

A more detailed explanation about how providing liquidity works with arithmetic method is written in our [Gitbook](https://kita71yusuke.gitbook.io/napier-finance/).

## Useful Resources

[Napier Finance](https://kita71yusuke.gitbook.io/napier-finance/)
