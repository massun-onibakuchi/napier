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
      <div className='left'>
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
        className='w-full md:flex md:items-center md:w-auto space-between '
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
        <div>
          <button
            type='button'
            className='inline-block px-7 py-3 m-0 bg-indigo-400 text-white font-medium text-sm leading-snug uppercase rounded shadow-md'
          >
            Button
          </button>
        </div>
      </div>
    </nav>
  );
}
