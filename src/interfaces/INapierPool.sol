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

    /// @param pt The Principal Token of a lending protocol
    /// @param recipient The address to receive the minted liquidity token
    function mint(address pt, address recipient) external returns (uint256 liquidity);

    /// @param pt The Principal Token of a lending protocol
    /// @param recipient The address to receive assets
    function burn(address pt, address recipient) external returns (uint256 amountUnderunderlying, uint256 amountNPt);

    // TODO
    // function swap(
    //     uint256 amountUnderunderlying,
    //     uint256 amountNPt,
    //     address to,
    //     bytes calldata data
    // );
}
