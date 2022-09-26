import { ethers } from 'ethers';
import { ERC20 } from '../../abi/ERC20';
import { ERC20__factory } from '../../abi/factories';
import { BaseAdapter__factory } from '../../abi/factories/BaseAdapter__factory';
import { NapierPoolFactory__factory } from '../../abi/factories/NapierPoolFactory__factory';
import { NapierPool__factory } from '../../abi/factories/NapierPool__factory';
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


export async function calculateAmount(underlyingInputAmount: number, yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum, setAmountIn: (pAmount: string, yAmount: string) => void) {
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

  const tAmount = ethers.BigNumber.from(underlyingInputAmount);

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

  console.log('trancheSeries', );

  const adapter = BaseAdapter__factory.connect(trancheSeries.adapter, signer);
  const feePst = await adapter.getIssuanceFee();
    const fee = ethers.BigNumber.from(tAmount).mul(feePst).div(ONE);
  console.log('feePst', feePst)
  const scale = await tranche.lscales(ptContractAddress, myAddress);
  console.log('scale,', scale);
  const mintAmount = (tAmount.add(-fee)).mul(scale).div(ONE);
  console.log(mintAmount.toString());
  
  setAmountIn(mintAmount.toString(), mintAmount.toString());;
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
  const issued = await tranche.issueFromUnderlying(ptContractAddress, ethers.utils.parseEther(String(amount)))
}

export async function mintPTAndLP(amount: number, yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum) {
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const chainId = await signer.getChainId();
  const myAddress = await signer.getAddress();

  const addresses = getAddressByChainId(chainId);
  const tranche = Tranche__factory.connect(addresses.Tranche, signer);

  const [cDAIPT,  yDAIPT, aDAIPT, eDAIPT] = await tranche.getZeros();
  let ptContractAddress = "";
  if (yieldSymbol === YieldSymbolEnum.DAI) {
    if (yieldSource === YieldSourceEnum.Aave) {
      ptContractAddress = aDAIPT;
    }
  }

  const poolFactory = NapierPoolFactory__factory.connect(addresses.NapierPoolFactory, signer);
  const [ poolAddress ] = await poolFactory.getPools();

  const pool = await NapierPool__factory.connect(poolAddress, signer);
  const deadline = Math.floor(Date.now() / 1000) + 10 * 60; // now + 10 mins

  console.log(
    ptContractAddress,
    myAddress,
    ethers.utils.parseEther(String(amount)),
    ethers.utils.parseEther(String(0)),
    ethers.utils.parseEther(String(deadline))
  )
  // const [res1, res2] = await pool.getReserves();
  // console.log(res1.toString(), res2.toString())
  const issued = await pool.addLiquidityFromUnderlying(
    ptContractAddress,
    myAddress,
    ethers.utils.parseEther(String(amount)),
    ethers.utils.parseEther(String(0)),
    ethers.utils.parseEther(String(deadline)),
  )
}

export async function approveTargetTokenToPool(yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum) {
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const chainId = await signer.getChainId();
  const addresses = getAddressByChainId(chainId);

  let targetAddress = "";
  if (yieldSymbol === YieldSymbolEnum.DAI) {
    targetAddress = addresses.DAI;

  }

  const poolFactory = NapierPoolFactory__factory.connect(addresses.NapierPoolFactory, signer);
  const [ poolAddress ] = await poolFactory.getPools();

  const dai = ERC20__factory.connect(targetAddress, signer);
  const approveMsg = await dai.approve(poolAddress, ethers.constants.MaxUint256);
}

export async function calculateAmountIn(amount: number, yieldSymbol: YieldSymbolEnum, yieldSource: YieldSourceEnum, setAmountIn: (uAmount: string, nptAmount: string) => void) {
  console.log('calculateAmountIn', amount, yieldSource, yieldSymbol)
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const chainId = await signer.getChainId();
  const myAddress = await signer.getAddress();
  const addresses = getAddressByChainId(chainId);
  const tranche = Tranche__factory.connect(addresses.Tranche, signer);

  const [cDAIPT,  yDAIPT, aDAIPT, eDAIPT] = await tranche.getZeros();
  let ptContractAddress = "";
  if (yieldSymbol === YieldSymbolEnum.DAI) {
    if (yieldSource === YieldSourceEnum.Aave) {
      ptContractAddress = aDAIPT;
    }
  }

  const poolFactory = NapierPoolFactory__factory.connect(addresses.NapierPoolFactory, signer);
  const [ poolAddress ] = await poolFactory.getPools();
  const pool = await NapierPool__factory.connect(poolAddress, signer);
  const [uAmountIn, nptAmount] = await pool.getAmountIn(ptContractAddress, myAddress, ethers.utils.parseEther(String(amount)));
  setAmountIn(ethers.utils.formatEther(uAmountIn), ethers.utils.formatEther(nptAmount.toString()));
}