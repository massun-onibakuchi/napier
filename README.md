## Botminator                 

🪢🪢 This is the official repository for MEV Hackathon 2022 with Encode Club 🪢🪢


## Description 

Napier Finance is a fully decentralized yield stripping protocol that enables users to trade fixed and variable rates efficiently. Napier is building the Napier Space AMM, the most capital efficient AMM featuring permissionless listings and unified liquidity. Napier Finance opens up new options for DeFi yields without the need for trusted intermediaries.


## Napier Space AMM

![PoPV](./docs/NapierSpace.png)


### Contracts 

AdaptersContractsAave deployed : [Mumbai  contract](https://mumbai.polygonscan.com/address/0x5bEa99Fcdca784bB9EbBF7a070FEB567a55581D5)


### How it works : Proof of Price Variation 


ADD DIAGRAM

 
### Arbitrage Strategies  




### Inspiration 

To reduce the risk of having a sandwich attack AMM DEXs began offering Time Weighted Average Price (TWAP) oracles. TWAP is a pricing methodology that calculates the mean price of an asset during a specified period of time. For example, a “one-hour TWAP” means taking the average price over a defined hour of time. 


Cross-exchange market making :

- Less liquid market : make order 
- More Liquid market : taker order 


### Strategy 

It is important to choose the right dex or in other words the route to be profitable, and for this you have to : 

- Take into account the tax(fees) in the arbitrage while setting up orders. 
- Oracle exchange price feed choice : not necessarily the connected exchange <depends on strategy : more liquid exchange will give you more insight into the potential direction of token price> 


### Analysis Tools 

[Analysis tool for dexs](https://defillama.com/)


### MEV Integration 

- PriceFeed 
- Keepers 

### Advantages 


### Future 

- Friendly user-interface. 
- 
