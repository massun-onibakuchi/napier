import { BigNumberish, utils } from 'ethers';
import React, { useState } from 'react';
import {
  calculateAmount,
  getERC20Instance,
} from '../utils/web3/interactWithContracts';
import {
  YieldSourceEnum,
  YieldSymbolEnum,
} from '../utils/web3/YieldPositionNames';

interface PositionProps {
  underlyingSymbolEnum: YieldSymbolEnum;
  source: YieldSourceEnum;
  myAddress: string;
}

export function YieldPosition({
  underlyingSymbolEnum,
  source,
  myAddress,
}: PositionProps) {
  const [isDropdownOpened, setIsDropdownOpened] = useState<boolean>(false);
  const [isAddingLiquidity, setIsAddingLiquidity] = useState<boolean>(false);
  const [underlyingBalance, setUnderlyingBalance] = useState<BigNumberish>(0);
  const [underlyingSymbol, setUnderlyingSymbol] = useState<string>('');
  const [underlyingInputAmount, setUnderlyingInputAmount] = useState<number>(0);

  // TODO
  const toFixed = 0;

  function onDropDownOpen() {
    setIsDropdownOpened(!isDropdownOpened);
  }

  async function onIsAddingLiquidity() {
    setIsAddingLiquidity(!isAddingLiquidity);
    setIsDropdownOpened(false);

    const dai = await getERC20Instance(underlyingSymbolEnum);
    const balance = await dai.balanceOf(myAddress); // alice
    const symbol = await dai.symbol();
    setUnderlyingBalance(balance);
    setUnderlyingSymbol(symbol);
  }

  function onUnderlyingInput(e: React.FormEvent<HTMLInputElement>) {
    const input = Number(e.currentTarget.value);
    if (Number.isNaN(input)) {
      return;
    }
    setUnderlyingInputAmount(input);
    calculateAmount(underlyingInputAmount, underlyingSymbolEnum, source);
  }

  function onUnderlyingMaxClick() {
    setUnderlyingInputAmount(Number(utils.formatEther(underlyingBalance)));
  }

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
            onClick={onDropDownOpen}
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
                    onClick={onIsAddingLiquidity}
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
                {`Mint principal and yield tokens with your ${underlyingSymbol}`}
              </span>
              <div className='flex flex-row gap-2  bg-[#1a1f34] p-3 rounded-md'>
                <input
                  onInput={onUnderlyingInput}
                  className=' w-full bg-[#1a1f34] text-right'
                  type='number'
                  value={underlyingInputAmount}
                />
                <div className=''>
                  <button
                    onClick={onUnderlyingMaxClick}
                    type='button'
                    className='text-white border-white border-2 rounded-lg text-sm px-2 py-1 text-center inline-flex items-right'
                  >
                    MAX
                  </button>
                </div>
              </div>
              <span className='text-right m-1'>{`Available: ${Number(
                utils.formatEther(underlyingBalance),
              )} ${underlyingSymbol}`}</span>
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
                Approve
              </button>
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
