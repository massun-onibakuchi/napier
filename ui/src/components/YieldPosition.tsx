import { BigNumberish, utils } from 'ethers';
import React, { useState } from 'react';
import {
  approveTargetToken,
  approveTargetTokenToPool,
  calculateAmount,
  calculateAmountIn,
  getERC20Instance,
  mintPT,
  mintPTAndLP,
} from '../utils/web3/interactWithContracts';
import {
  YieldSourceEnum,
  YieldSymbolEnum,
} from '../utils/web3/YieldPositionNames';

interface PositionProps {
  underlyingSymbolEnum: YieldSymbolEnum;
  source: YieldSourceEnum;
  myAddress: string;
  TVL: string;
  APY: string;
  maturity: string;
}

export function YieldPosition({
  underlyingSymbolEnum,
  source,
  myAddress,
  TVL,
  APY,
  maturity,
}: PositionProps) {
  const [isDropdownOpened, setIsDropdownOpened] = useState<boolean>(false);
  const [isAddingLiquidity, setIsAddingLiquidity] = useState<boolean>(false);
  const [isLPPage, setIsLPPage] = useState<boolean>(false);

  const [underlyingBalance, setUnderlyingBalance] = useState<BigNumberish>(0);
  const [underlyingSymbol, setUnderlyingSymbol] = useState<string>('');
  const [underlyingInputAmount, setUnderlyingInputAmount] = useState<number>(0);
  const [underlyingAmountRequiredForLP, setUnderlyingAmountRequiredForLP] =
    useState<string>('');
  const [expectedNptAmount, setExpectedNptAmount] = useState<string>('');
  const [expectedPrincipalToken, setExpectedPrincipalToken] =
    useState<string>('');
  const [expectedYieldToken, setExpectedYieldToken] = useState<string>('');

  // TODO
  const toFixed = 0;

  function onDropDownOpen() {
    setIsDropdownOpened(!isDropdownOpened);
  }

  async function onIsAddingLiquidity() {
    setIsAddingLiquidity(!isAddingLiquidity);
    setIsDropdownOpened(false);

    await updateUnderlyingBalance();
  }

  async function updateUnderlyingBalance() {
    const dai = await getERC20Instance(underlyingSymbolEnum);
    const balance = await dai.balanceOf(myAddress); // alice
    const symbol = await dai.symbol();
    setUnderlyingBalance(balance);
    setUnderlyingSymbol(symbol);
    console.log('balance', underlyingBalance);
  }

  function onUnderlyingInput(e: React.FormEvent<HTMLInputElement>) {
    const input = Number(e.currentTarget.value);
    if (Number.isNaN(input)) {
      return;
    }
    setUnderlyingInputAmount(input);
    if (isLPPage) {
      const setAmountIn = (uAmount: string, nptAmount: string) => {
        setUnderlyingAmountRequiredForLP(uAmount);
        setExpectedNptAmount(nptAmount);
      };
      calculateAmountIn(input, underlyingSymbolEnum, source, setAmountIn);
    } else {
      const setAmountIn = (pAmount: string, yAmount: string) => {
        setExpectedPrincipalToken(pAmount);
        setExpectedYieldToken(yAmount);
      };
      calculateAmount(input, underlyingSymbolEnum, source, setAmountIn);
    }
  }

  function onUnderlyingMaxClick() {
    setUnderlyingInputAmount(Number(utils.formatEther(underlyingBalance)));
  }

  function onApprovePT() {
    approveTargetToken(underlyingSymbolEnum, source);
  }

  function onApproveUnderlyingToPool() {
    approveTargetTokenToPool(underlyingSymbolEnum, source);
  }

  async function onMintPT() {
    console.log(underlyingInputAmount, underlyingSymbolEnum, source);
    await mintPT(underlyingInputAmount, underlyingSymbolEnum, source);
    await updateUnderlyingBalance();
  }

  async function onMintPTAndLP() {
    console.log();
    await mintPTAndLP(underlyingInputAmount, underlyingSymbolEnum, source);
    await updateUnderlyingBalance();
  }

  function onLPOptionChange(e: any) {
    if (e.target.value === 'a') {
      setIsLPPage(false);
    } else {
      setIsLPPage(true);
    }
  }

  return (
    <>
      <div className='flex pl-12 bg-[#020927] text-white items-center py-8 '>
        {source === YieldSourceEnum.Aave && (
          <div className='w-1/4 text-lg flex'>
            <img className='pr-2' src='./adai.png' alt='aDAI' width='58' />
            aDAI
          </div>
        )}
        {source === YieldSourceEnum.Compound && (
          <div className='w-1/4 text-lg flex'>
            <img className='pr-2' src='./cdai.png' alt='cDAI' width='58' />
            cDAI
          </div>
        )}
        {source === YieldSourceEnum.Yearn && (
          <div className='w-1/4 text-lg flex'>
            <img className='pr-2' src='./ydai.png' alt='cDAI' width='58' />
            yDAI
          </div>
        )}
        {source === YieldSourceEnum.Euler && (
          <div className='w-1/4 text-lg flex'>
            <img className='pr-2' src='./edai.png' alt='eDAI' width='58' />
            eDAI
          </div>
        )}
        <div className='w-1/6 text-lg'>{TVL}</div>
        <div className='w-1/6 text-lg'>{APY}</div>
        <div className='w-1/6 text-lg flex flex-col mr-2'>
          <span>{maturity}</span>
        </div>
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
            <label>
              <input
                type='radio'
                value='a'
                onChange={onLPOptionChange}
                checked={!isLPPage}
              />
              {'   '} Mint principal and yield tokens
            </label>
            <label>
              <input
                type='radio'
                value='b'
                onChange={onLPOptionChange}
                checked={isLPPage}
              />
              {'   '} Mint principal and yield tokens, and earn LP fees
            </label>
          </div>
          <div className='w-1/2 border m-2 p-2 border-white flex flex-col'>
            <div className='flex m-2 w-full flex-col'>
              <span className='text-center mb-2'>
                {isLPPage
                  ? `LP for additional yield with your ${source}`
                  : `Mint principal and yield tokens with your ${underlyingSymbolEnum}`}
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

            <div className='flex m-2 w-full mb-4'>
              <div className='flex flex-col w-1/2'>
                <span className='text-center m-1'>
                  {isLPPage ? 'Underlying' : 'Principal token'}
                </span>
                <div className='flex flex-row gap-2  bg-[#1a1f34] mr-2 rounded-md text-right justify-center'>
                  <div className='bg-[#1a1f34] m-4 justify-center'>
                    <span className=''>
                      {isLPPage
                        ? underlyingAmountRequiredForLP
                        : expectedPrincipalToken}
                    </span>
                  </div>
                </div>
              </div>
              <div className='flex flex-col w-1/2'>
                <span className='text-center m-1'>
                  {isLPPage ? 'Calculated nPT Amount' : 'Yield token'}
                </span>
                <div className='flex flex-row gap-2  bg-[#1a1f34] mr-2 rounded-md text-right justify-center'>
                  <div className='bg-[#1a1f34] m-4 justify-center'>
                    <span className=''>
                      {isLPPage ? expectedNptAmount : expectedYieldToken}
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div className='flex justify-center mt-2'>
              <button
                className='w-full border-white border-2 text-xl p-8 text-center inline-flex items-center justify-center m-2'
                type='button'
                onClick={isLPPage ? onApproveUnderlyingToPool : onApprovePT}
              >
                1) Approve
              </button>
              <button
                className='w-full border-white border-2 text-xl p-8 text-center inline-flex items-center justify-center m-2'
                type='button'
                onClick={isLPPage ? onMintPTAndLP : onMintPT}
              >
                2) {isLPPage ? 'Mint & Provide Liquidity' : 'Mint'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
