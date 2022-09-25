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
        AaveV2Adapter: "0xd753c12650c280383Ce873Cc3a898F6f53973d16",
        NapierPoolFactory: "0xd30bF3219A0416602bE8D482E0396eF332b0494E",
        Tranche: "0x06b3244b086cecC40F1e5A826f736Ded68068a0F",
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