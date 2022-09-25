import { ethers } from 'ethers';
import React, { useEffect, useState } from 'react';
import NavBar from '../components/NavBar';

declare let window: any;

function Description() {
  return (
    <div
      className='
                flex
                flex-col
                justify-center
                items-center
                bg-white
                mx-auto
                max-w-2xl
                rounded-lg
                
                '
    >
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

function Position() {
  const [isDropdownOpened, setIsDropdownOpened] = useState<boolean>(false);
  const [isAddingLiquidity, setIsAddingLiquidity] = useState<boolean>(false);

  return (
    <>
      <div className='flex pl-12 bg-[#020927] text-white items-center py-8 '>
        <div className='w-1/4 text-lg flex'>
          <img src='./adai.png' alt='aDAI' width='50' />
          aDAI
        </div>
        <div className='w-1/6 text-lg'>000</div>
        <div className='w-1/6 text-lg'>000</div>
        <div className='w-1/6 text-lg'>000</div>
        <div className='w-1/6 text-lg'>
          <button
            id='dropdownDefault'
            data-dropdown-toggle='dropdown'
            className='text-white border-white border-2 rounded-lg text-sm px-4 py-2.5 text-center inline-flex items-center'
            type='button'
            onClick={() => setIsDropdownOpened(!isDropdownOpened)}
          >
            Manage{' '}
            <svg
              className='ml-2 w-4 h-4'
              aria-hidden='true'
              fill='none'
              stroke='currentColor'
              viewBox='0 0 24 24'
              xmlns='http://www.w3.org/2000/svg'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth='2'
                d='M19 9l-7 7-7-7'
              />
            </svg>
          </button>
          {isDropdownOpened && (
            <div
              id='dropdown'
              className='absolute z-10 w-44 bg-white rounded divide-y divide-gray-100 shadow'
            >
              <ul
                className='py-1 text-sm text-gray-700 '
                aria-labelledby='dropdownDefault'
              >
                <li>
                  <button
                    type='button'
                    className='block py-2 px-4 hover:bg-gray-100'
                    onClick={() => setIsAddingLiquidity(!isAddingLiquidity)}
                  >
                    Add Liquidity
                  </button>
                </li>
                <li>
                  <button
                    type='button'
                    className='block py-2 px-4 hover:bg-gray-100'
                  >
                    Remove Liquidity
                  </button>
                </li>
              </ul>
            </div>
          )}
        </div>
      </div>
      {isAddingLiquidity && (
        <div className='border-t border-white bg-[#020927] text-white flex '>
          <div className='w-1/2 flex flex-col items-center justify-center'>
            <span>1. Mint principal and yield tokens</span>
            <span> 2. LP for additonal yield</span>
          </div>
          <div className='w-1/2 border m-2 p-2 border-white flex flex-col'>
            <div className='flex m-2 w-full flex-col'>
              <span className='text-center mb-2'>
                Mint principal and yield tokens with your DAI
              </span>
              <div className='flex flex-row gap-2  bg-[#1a1f34] p-3 rounded-md'>
                <input className=' w-full bg-[#1a1f34] text-right' />
                <div className=''>
                  <button
                    type='button'
                    className='text-white border-white border-2 rounded-lg text-sm px-2 py-1 text-center inline-flex items-right'
                  >
                    MAX
                  </button>
                </div>
              </div>
              <span className='text-right m-1'>Available balance : 00 </span>
            </div>

            <div className='flex m-2 w-full'>
              <div className='flex flex-col w-1/2'>
                <span className='text-center m-1'>Principal token</span>
                <div className='flex flex-row gap-2  bg-[#1a1f34] mr-2 p-3 rounded-md'>
                  <input className='bg-[#1a1f34] text-right' />
                  <div className=''>
                    <button
                      type='button'
                      className='text-white border-white border-2 rounded-lg text-sm px-2 py-1 text-center inline-flex items-center'
                    >
                      MAX
                    </button>
                  </div>
                </div>
                <span className='text-right m-1'>Available balance : 00 </span>
              </div>
              <div className='flex flex-col w-1/2'>
                <span className='text-center m-1'>Principal token</span>
                <div className='flex flex-row gap-2  bg-[#1a1f34] mr-2 p-3 rounded-md'>
                  <input className='bg-[#1a1f34] text-right' />
                  <div className=''>
                    <button
                      type='button'
                      className='text-white border-white border-2 rounded-lg text-sm px-2 py-1 text-center inline-flex items-center'
                    >
                      MAX
                    </button>
                  </div>
                </div>
                <span className='text-right m-1'>Available balance : 00 </span>
              </div>
            </div>
            <span className='text-right m-2'>
              {' '}
              Calculated nPT Amount : 00000 (nPT)
            </span>
            <div className='flex justify-center mt-2'>
              <button
                className='w-full border-white border-2 text-xl p-8 text-center inline-flex items-center justify-center m-2'
                type='button'
              >
                Enter Amount
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

function YieldPositions() {
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
        <div className='mb-6'>
          <Position />
        </div>

        <Position />
      </div>
    </div>
  );
}

function Home() {
  const [myAddress, setMyAddress] = useState<string>('');

  async function requestAccount() {
    try {
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const address = await signer.getAddress();
      setMyAddress(address);
      const balanceBN = await signer.getBalance();
      //   setBalance(Number(ethers.utils.formatEther(balanceBN)));
    } catch (e: any) {
      //   setErrorMsg(e.data?.message?.toString() || e.message);
    }
    // setIsLoading(false);
  }

  useEffect(() => {
    // if (!isInitialRender) return;

    try {
      requestAccount();
      //   getPrice().then((value) => {
      //     setConversionRate(value);
      //   });
    } catch (e: any) {
      //   setErrorMsg(e.data.message.toString() || e.message);
    }

    // if (isInitialRender) {
    //   setIsInitialRender(false);
    // }
  }, []);

  return (
    <div className=' min-h-screen'>
      <div className='container mx-auto'>
        <NavBar address={myAddress} />

        <body>
          <div>
            <Description />
          </div>
          <YieldPositions />
        </body>
      </div>
    </div>
  );
}

export default Home;
