import { ethers } from 'ethers';
import React, { useEffect, useState } from 'react';
import NavBar from '../components/NavBar';
import { YieldPosition } from '../components/YieldPosition';
import {
  YieldSourceEnum,
  YieldSymbolEnum,
} from '../utils/web3/YieldPositionNames';

declare let window: any;

function Description() {
  return (
    <div className='flex flex-col justify-center items-center bg-white mx-auto max-w-2xl rounded-lg'>
      <h1 className='text-2xl font-semibold mb-4'>
        Capital efficiency for your yield position
      </h1>
      <h2 className='font-light text-center'>
        Mint Principal and Yield Tokens from your underlying asset, boost your
        APY by providing liquidity and view current APYs across all available
        terms.
      </h2>
    </div>
  );
}

interface YieldPosition {
  underlyingSymbolEnum: YieldSymbolEnum;
  source: YieldSourceEnum;
  TVL: string;
  APY: string;
  maturity: string;
}
interface YieldPositionsProps {
  positions: YieldPosition[];
  myAddress: string;
}

function YieldPositions({ positions, myAddress }: YieldPositionsProps) {
  return (
    <div className='mt-8 flex w-full h-full items-center justify-center break-words'>
      <div className='flex bg-white flex-col w-5/6 flex-nowrap m-0'>
        <div className='flex pl-12 flex-row flex-nowrap my-6'>
          <div className='w-1/4 text-lg'>Symbol</div>
          <div className='w-1/6 text-lg'>TVL</div>
          <div className='w-1/6 text-lg'>APY</div>
          <div className='w-1/6 text-lg'>MATURITY</div>
          <div />
        </div>
        {positions.map(
          ({ underlyingSymbolEnum, source, TVL, APY, maturity }) => (
            <div className='mb-6' key={`${underlyingSymbolEnum}-${source}`}>
              <YieldPosition
                underlyingSymbolEnum={underlyingSymbolEnum}
                source={source}
                myAddress={myAddress}
                TVL={TVL}
                APY={APY}
                maturity={maturity}
              />
            </div>
          ),
        )}
      </div>
    </div>
  );
}

const YIELD_POSITONS: YieldPosition[] = [
  {
    underlyingSymbolEnum: YieldSymbolEnum.DAI,
    source: YieldSourceEnum.Aave,
    TVL: '$ 27.4M',
    APY: '1.33%',
    maturity: 'Apr 1st, 2022',
  },
  {
    underlyingSymbolEnum: YieldSymbolEnum.DAI,
    source: YieldSourceEnum.Yearn,
    TVL: '$ 19.3M',
    APY: '1.62%',
    maturity: 'Apr 1st, 2022',
  },
  {
    underlyingSymbolEnum: YieldSymbolEnum.DAI,
    source: YieldSourceEnum.Compound,
    TVL: '$ 25.1M',
    APY: '1.22%',
    maturity: 'Apr 1st, 2022',
  },
  {
    underlyingSymbolEnum: YieldSymbolEnum.DAI,
    source: YieldSourceEnum.Euler,
    TVL: '$ 9.5M',
    APY: '1.34%',
    maturity: 'Apr 1st, 2022',
  },
];

function Home() {
  const [myAddress, setMyAddress] = useState<string>('');
  const [chainId, setChainId] = useState<number>(1);

  async function requestAccount() {
    try {
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const address = await signer.getAddress();
      setMyAddress(address);

      const { chainId } = await provider.getNetwork();
      setChainId(chainId);
    } catch (e: any) {
      window.alert(e.data?.message?.toString() || e.message);
    }
  }
  useEffect(() => {
    requestAccount();
  });

  return (
    <div className=' min-h-screen'>
      <div className='container mx-auto'>
        <NavBar address={myAddress} onConnect={() => requestAccount()} />

        <body>
          <div>
            <Description />
          </div>
          <YieldPositions positions={YIELD_POSITONS} myAddress={myAddress} />
        </body>
      </div>
    </div>
  );
}

export default Home;
