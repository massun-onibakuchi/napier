import { ethers } from 'ethers';
import { ERC20 } from '../../abi/ERC20';
import { ERC20__factory } from '../../abi/factories';
import { NapierPoolFactory__factory } from '../../abi/factories/NapierPoolFactory__factory';
import { Tranche__factory } from '../../abi/factories/Tranche.sol';
import { getAddressByChainId } from './Addresses';
import {
  YieldSourceEnum, YieldSymbolEnum
} from './YieldPositionNames';

declare let window: any;

async function requestAccount() {
  try {
    await window.ethereum.request({ method: 'eth_requestAccounts' });
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const address = await signer.getAddress();
    const { chainId } = await provider.getNetwork();

  } catch (e: any) {
    window.alert(e.data?.message?.toString() || e.message);
  }
}


export async function getERC20Instance(
  yieldSymbol: YieldSymbolEnum,
): Promise<ERC20> {
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const myAddress = await signer.getAddress();
  const { chainId } = await provider.getNetwork();
  const addresses = getAddressByChainId(chainId);

  let contractAddress = "";
  if (yieldSymbol === YieldSymbolEnum.DAI) {
    contractAddress = addresses.DAI;
  }
  
  const dai = ERC20__factory.connect(contractAddress, provider);
  
  return dai;
}


export async function calculateAmount(underlyingInputAmount: number, yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum) {
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const myAddress = await signer.getAddress();
  const { chainId } = await provider.getNetwork();
  const addresses = getAddressByChainId(chainId);

  // let ptContractAddress = "";
  // if (yieldSymbol === YieldSymbolEnum.DAI) {
  //   if (yieldSource === YieldSourceEnum.Aave) {
  //     ptContractAddress = addresses.DAI;
  //   }
  // }

  const tAmount = underlyingInputAmount;

  // call tranche (npt)
  const ONE = ethers.BigNumber.from(10).pow(18)
  const tranche = await Tranche__factory.connect(addresses.Tranche, signer);
  const [cDAIPT,  yDAIPT, aDAIPT, eDAIPT] = await tranche.getZeros();
  let ptContractAddress = "";
  if (yieldSymbol === YieldSymbolEnum.DAI) {
    if (yieldSource === YieldSourceEnum.Aave) {
      ptContractAddress = aDAIPT;
    }
  }
  const trancheSeries = await tranche.getSeries(ptContractAddress);

  console.log('trancheSeries', trancheSeries.adapter);
  
  // const adapter = new Contract(tranche.getSeries(ptContractAddress).adapter, abi)
  // const feePst = adapter.getIssuanceFee();
  // const fee = tAmount.mul(feePst).div(ONE);
  // let _scale = tranche.lscales(
  // pt, <user address>
  // )
  // if (_scale.isZero()) {
  // _scale = adapter.scaleStored();
  // }
  // // pt amount and yt amount are the same
  // const mintAmount = (tAmount - fee).mul(_scale).div(ONE);
}

export async function approveTargetToken(yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum) {
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const chainId = await signer.getChainId();
  const addresses = getAddressByChainId(chainId);

  let targetAddress = "";
  if (yieldSymbol === YieldSymbolEnum.DAI) {
    targetAddress = addresses.DAI;

  }

  const dai = ERC20__factory.connect(targetAddress, signer);
  const approveMsg = await dai.approve(addresses.Tranche, ethers.constants.MaxUint256);
}

export async function mintPT(amount: number, yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum) {
  console.log(amount)
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const chainId = await signer.getChainId();
  const addresses = getAddressByChainId(chainId);

  const tranche = Tranche__factory.connect(addresses.Tranche, signer);

  const [cDAIPT,  yDAIPT, aDAIPT, eDAIPT] = await tranche.getZeros();
  let ptContractAddress = "";
  if (yieldSymbol === YieldSymbolEnum.DAI) {
    if (yieldSource === YieldSourceEnum.Aave) {
      ptContractAddress = aDAIPT;
    }
  }
  console.log('issueing');

  const issued = await tranche.issueFromUnderlying(ptContractAddress, ethers.BigNumber.from(amount))
  console.log('issued', amount, issued);
  // const approveMsg = await dai.approve(addresses.Tranche, ethers.constants.MaxUint256);
}

export async function mintPTAndLP(amount: number, yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum) {
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const chainId = await signer.getChainId();
  const addresses = getAddressByChainId(chainId);

  const poolFactory = NapierPoolFactory__factory.connect(addresses.Tranche, signer);
  const tranche = Tranche__factory.connect(addresses.Tranche, signer);


  const [cDAIPT,  yDAIPT, aDAIPT, eDAIPT] = await tranche.getZeros();
  const rightPool = await poolFactory.getPools();
  let ptContractAddress = "";
  if (yieldSymbol === YieldSymbolEnum.DAI) {
    if (yieldSource === YieldSourceEnum.Aave) {
      ptContractAddress = aDAIPT;
    }
  }

  const issued = await tranche.issueFromUnderlying(ptContractAddress, ethers.BigNumber.from(amount))


}


// export async function calculateAmountIn(aount: number, yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum)m