import React, { useState } from 'react';
import NavBar from '../components/NavBar';

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
                p-8
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

  return (
    <div className='flex pl-12 bg-[#020927] text-white items-center py-8 mb-6'>
      <div className='w-1/4 text-lg'>aDAI</div>
      <div className='w-1/6 text-lg'>000</div>
      <div className='w-1/6 text-lg'>000</div>
      <div className='w-1/6 text-lg'>000</div>
      <div className='w-1/6 text-lg'>
        <button
          id='dropdownDefault'
          data-dropdown-toggle='dropdown'
          className='text-white bg-blue-700 border-white border-2 rounded-lg text-sm px-4 py-2.5 text-center inline-flex items-center'
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
                <a href='./' className='block py-2 px-4 hover:bg-gray-100'>
                  Add Liquidity
                </a>
              </li>
              <li>
                <a href='./' className='block py-2 px-4 hover:bg-gray-100'>
                  Remove Liquidity
                </a>
              </li>
            </ul>
          </div>
        )}
      </div>
    </div>
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
        <Position />
        <Position />
      </div>
    </div>
  );
}

function Home() {
  return (
    <div className=' min-h-screen'>
      <div className='container mx-auto'>
        <NavBar />

        <body
          className='
        antialiased
        '
        >
          <div className='px-4'>
            <Description />
          </div>
          <YieldPositions />
        </body>
      </div>
    </div>
  );
}

export default Home;
