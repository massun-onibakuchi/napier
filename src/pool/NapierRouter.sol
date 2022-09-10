// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../interfaces/INapierRouter.sol";

contract NapierRouter is INapierRouter {
    function addLiquidityFromUnderlying(
        address nPT,
        address recipient,
        uint256 amountIn,
        uint256 minLpTokenOut,
        uint256 deadline
    ) external returns (uint256) {
        // TODO
    }
}
