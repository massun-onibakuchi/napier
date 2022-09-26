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
        // forked contracts
        DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        ADAI: "0x028171bCA77440897B824Ca71D1c56caC55b68A3",
        // locally deployed contracts
        AaveV2Adapter: "0xAD2935E147b61175D5dc3A9e7bDa93B0975A43BA",
        NapierPoolFactory: "0x4951A1C579039EbfCBA0BE33D2cd3A6D30b0f802",
        Tranche: "0x2e8880cAdC08E9B438c6052F5ce3869FBd6cE513",
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