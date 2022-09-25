const CHAIN_ID_LOCAL = 1337;

interface ContractAddresses {
  DAI: string;
  ADAI: string;
  NapierPoolFactory: string;
  AaveV2Adapter: string;
  Tranche: string;
}

export function getAddressByChainId(chainId: number): ContractAddresses {
  switch (chainId) {
    case CHAIN_ID_LOCAL:
      return {
        DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        ADAI: "0x028171bCA77440897B824Ca71D1c56caC55b68A3",
        AaveV2Adapter: "0x8E45C0936fa1a65bDaD3222bEFeC6a03C83372cE",
        NapierPoolFactory: "0xC32609C91d6B6b51D48f2611308FEf121B02041f",
        Tranche: "0x262e2b50219620226C5fB5956432A88fffd94Ba7",
      };
  }
  return {
    DAI: "",
    ADAI: "",
    AaveV2Adapter: "",
    NapierPoolFactory: "",
    Tranche: "",
  };
}