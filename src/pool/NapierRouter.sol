// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../interfaces/INapierRouter.sol";

import "../interfaces/INapierPool.sol";

contract NapierRouter is INapierRouter {
    // function addLiquidityFromUnderlying(
    //     address underlying,
    //     address pt,
    //     address npt,
    //     address recipient,
    //     uint256 amountIn,
    //     uint256 minLpTokenOut,
    //     uint256 deadline
    // ) external returns (uint256) {
    //     // require(deadline >= block.timestamp, "NapierRouter: expired");
    //     // IERC20(underlying).safeTransferFrom(msg.sender, address(), amountIn);
    //     // uint256 liquidity = mintFromUnderlying(pt, recipient);
    // }
}
