// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Base token contract for Principal Token and Yield Token of each protocol
interface IToken is IERC20Metadata {
    /// @param account The address to send the minted tokens
    /// @param amount The amount to be minted
    function mint(address account, uint256 amount) external;

    /// @param account The address from where to burn tokens from
    /// @param amount The amount to be burned
    function burn(address account, uint256 amount) external;
}
