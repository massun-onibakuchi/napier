// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/yearn/IYearnVault.sol";

import "../BaseAdapter.sol";

/// @notice Adapter contract for yearn vaults
contract YearnAdapter is BaseAdapter {
    using SafeERC20 for IERC20;
    using SafeERC20 for IYearnVault;

    // The addresse of the yearn vault
    IYearnVault public immutable vault;

    constructor(AdapterParams memory _adapterParams) BaseAdapter(_adapterParams) {
        vault = IYearnVault(_adapterParams.target); // target is yearn vault

        IERC20(_adapterParams.underlying).safeApprove(_adapterParams.target, type(uint256).max);
    }

    /// @notice Get the price per share in the vault
    /// @notice scale in WAD term.
    function scale() external view override returns (uint256) {
        return _scale();
    }

    function scaleStored() external view override returns (uint256) {
        return _scale();
    }

    /// @return scale in WAD term.
    function _scale() internal view override returns (uint256) {
        // The price per share in units of underlying
        // normalize to 18 decimals
        return _normalize(vault.pricePerShare(), uDecimals);
    }

    function underlying() public view override returns (address) {
        return adapterParams.underlying;
    }

    function wrapUnderlying(uint256 uBal) external override returns (uint256 tBal) {
        IERC20(adapterParams.underlying).safeTransferFrom(msg.sender, address(this), uBal);
        // Deposit and get the shares that were minted to msg.sender
        tBal = vault.deposit(uBal, msg.sender);
    }

    function unwrapTarget(uint256 tBal) external override returns (uint256 uBal) {
        vault.safeTransferFrom(msg.sender, address(this), tBal);
        // Withdraws shares from the vault and sends the underlying to msg.sender
        uBal = vault.withdraw(tBal, msg.sender);
    }

    /// @dev to 18 point decimal
    /// @param amount The amount of the token in native decimal encoding
    /// @param decimals decimals of the token
    function _normalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        // If we need to increase the decimals
        if (decimals > 18) {
            // Then we shift right the amount by the number of decimals
            amount = amount / 10**(decimals - 18);
            // If we need to decrease the number
        } else if (decimals < 18) {
            // then we shift left by the difference
            amount = amount * 10**(18 - decimals);
        }
        // If nothing changed this is a no-op
        return amount;
    }
}
