#!/bin/sh

# https://book.getfoundry.sh/tutorials/forking-mainnet-with-cast-anvil

export ALICE=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
export DAI=0x6b175474e89094c44da98b954eedeac495271d0f
export LUCKY_USER=0xad0135af20fa82e106607257143d0060a7eb5cbf

cast rpc anvil_impersonateAccount $LUCKY_USER

cast send $DAI \
--from $LUCKY_USER \
  "transfer(address,uint256)(bool)" \
  $ALICE \
  1686045944718512103110072

cast call $DAI \
  "balanceOf(address)(uint256)" \
  $ALICE