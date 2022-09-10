# Napier Finance 

NOTE: This code is not audited and should not be used in production environment.
This is the official repository for MEV Hackathon 2022 with Encode Club

## Summary  

Napier Finance is a fully decentralized yield stripping protocol that enables users to trade fixed and variable rates efficiently. Napier is building the Napier Space AMM, the most capital efficient AMM featuring permissionless listings and unified liquidity. Napier Finance opens up new options for DeFi yields without the need for trusted intermediaries.

The specificity of Napier Finance is that it processes multiple principal tokens (that has same underlying asset, same maturity, different with yield sources) as a single principal token. 
You don't to use Aave, Compound, Yearn and other AMM separatly to diversify your strategies. You can use Napier Finance and save gas fees and benefit from different yield strategies in a single transaction. 

With Unified liquidity Napier Finance will bring significant capital efficiency improvements to existing YieldSpaces.



![PoPV](./docs/Processing.png)

## Requirements 

[Foundry](https://book.getfoundry.sh/)

- Compiling : ``` forge build ```
- Testing :  ``` forge test -vvv --fork-url=$RPC_URL --fork-block-number=<block number> ``` 

## Napier Space AMM

![PoPV](./docs/NapierSpace.png)


## Napier v1 protocol 

- Yield Striping Application  : 

This allows users to decompose their Interest-bearing Token into a Principal Token and a Yield Token that represents a claim on Principal and claim on Yield. 
Principal tokens redeem the underlying asset with a yield at maturity 1 for 1, while yield tokens provide the yield accruing on the underlying asset until maturity. 
The existence of PT and YT allows users to safely earn and borrow at fixed rates and trade based on future yields without the risk of liquidation or capital lockup.


![PoPV](./docs/YieldStripping.png)


## Contracts 

 
## Useful Ressources 

[Napier Finance](https://kita71yusuke.gitbook.io/napier-finance/)


# Arbitrage with Napier 

## Problem 

“Liquidity” is one of the most important factors in the financial world. This is the same for DeFi. More attractive profit opportunities attract more liquidity. This is why Napier Finance tackles liquidity provider profitability issues.

## Solution 

 Napier's unique AMM design allows liquidity providers to be expected higher transaction fee revenue compared to traditional yield stripping applications by providing multiple advatanges : 

 Non-liquidation - Napier can be likened to a secondary market for interest rates. Also, the two Napier minted tokens (PT and YT) are fully backed by the underlying asset and the interest accrued from it. As such, there is no risk of default or liquidation.

 Interest Rate Elasticity - As a yield stripping app, Napier does not have its own lending market. As such, the yield is based on the interest rate elasticity of DeFi's existing variable-yield source protocol, giving you the flexibility to customize and create fixed-rate products based on it.

 This second advantages will let traders make arbitrage based on their customized fixed-rate products by using Napier Finance multiple choices thanks to it's elasticity.

 You can for example choose to use :
    [Aave + Compound] as choice 1 
    [Aave + Compound + Yearn ] as choice 2 

Based on these 2 choices, LPs will mint 2 different PT and YT for the same underlying asset , DAI for example :

    choice 1  : nPT and YT 
    choice 2  : nPT and YT 

For each option you will have a different YT and you can based on your strategy apply a profitable arbitrage if possible. 






