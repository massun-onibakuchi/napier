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

- Compiling : ``` forge build ```
- Testing :  ``` forge test -vvv --fork-url=$RPC_URL --fork-block-number=<block number> ``` 


## Contracts 


- Adapters :

Adapters hold the logic for stripping yield from yield-bearing assets. 
For the adapters Napier is using non-airdrop Adapter implementations that must inherit BaseAdapter  and override these functions : 

```
scale()
getUnderlyingPrice()
wrapUnderlying()
unwrapTarget()
```

![FF](./docs/napierflowdiagram.png)


## Useful Resources

[Napier Finance](https://kita71yusuke.gitbook.io/napier-finance/)



## Future feature

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

A more detailed explanation about how providing liquidity works with arithmetic method is written in our Gitbook. It’s in "Useful resources chapter" of READme.



