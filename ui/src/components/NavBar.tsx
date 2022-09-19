import React from 'react';

export default function NavBar() {
  return (
    <nav
      className='
                flex flex-wrap
                items-center
                w-full
                py-8
                text-lg text-gray-700
                bg-white
                '
    >
      <div className='left w-1/5'>
        <a className='text-2xl flex items-center px-12' href='./'>
          <div className='mr-2'>
            <img
              src='./napier_logo.png'
              alt='nothing'
              width='44px'
              height='44px'
            />
          </div>
          <span className=''>NapierFi</span>
        </a>
      </div>

      <div
        className='w-1/3 md:flex md:items-center md:w-auto space-between '
        id='menu'
      >
        <ul
          className='
                    pt-4
                    text-gray-700
                    flex
                    space-between 
                    md:p-0
                    m-0
                    
                    '
        >
          <li>
            <a className='md:p-4 py-2 block hover:text-purple-400' href='./#'>
              Fixed Rates
            </a>
          </li>
          <li>
            <a
              className='md:p-4 py-2 block underline underline-offset-8 hover:text-purple-400'
              href='./#'
            >
              Mint & LP
            </a>
          </li>
          <li>
            <a className='md:p-4 py-2 block hover:text-purple-400' href='./#'>
              Pools
            </a>
          </li>
        </ul>
      </div>
      <div className='w-1/4 justify-end lg:flex items-center ml-auto pr-12'>
        <div
          style={{
            width: '2rem',
            height: '2rem',
            borderRadius: '50%',
            background:
              'transparent conic-gradient(from 90deg at 50% 50%, #FF0707 0.00%, #E815C0 26.60%, #2244FF 41.87%, #54BC7C 63.55%, #B1C03A 76.35%, #FF8B03 100.00%) 0% 0% no-repeat padding-box',
          }}
        />
        <span className='ml-1'>0xNapier...Napier</span>
      </div>
    </nav>
  );
}
