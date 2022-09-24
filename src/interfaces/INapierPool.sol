// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./INapierPoolFactory.sol";
import "./ITranche.sol";

/// @title NapierPool interface
/// @notice NapierPool is two-tokens AMM with an underlying asset and nPT (for more details see the Tranche.sol)
interface INapierPool {
    function factory() external returns (INapierPoolFactory);

    function underlying() external returns (IERC20Metadata);

    function nPT() external returns (ITranche);

    function addLiquidityFromUnderlying(
        address pt,
        address recipient,
        uint256 amountIn,
        uint256 minLiquidity,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function removeLiquidity(
        address pt,
        address recipient,
        uint256 minUnderlyingOut,
        uint256 minPtOut,
        uint256 deadline
    ) external returns (uint256 liquidity);

    // TODO
    // function swap(
    //     uint256 amountUnderunderlying,
    //     uint256 amountNPt,
    //     address recipient,
    //     uint256 deadline
    // );

    function getAmountIn(
        address pt,
        address recipient,
        uint256 amountIn
    ) external view returns (uint256 uAmountIn, uint256 nptAmountIn);
}
