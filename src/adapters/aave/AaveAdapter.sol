// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

// External references
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/aave/ILendingPool.sol";

// Internal references
import "../BaseAdapter.sol";

/// @title AaveV3 Adapter
/// NOTE: Aave V3 https://docs.aave.com/developers/tokens/atoken
contract AaveAdapter is BaseAdapter {
    using FixedMath for uint256;
    using SafeERC20 for IERC20;

    constructor(AdapterParams memory _adapterParams) BaseAdapter(_adapterParams) {}

    function scaleStored() external view override returns (uint256) {}

    /// @inheritdoc BaseAdapter
    /// @notice 1:1 exchange rate
    function _scale() internal override returns (uint256) {}

    /// @inheritdoc BaseAdapter
    function underlying() public view override returns (address) {}

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function wrapUnderlying(uint256 uBal) external override returns (uint256) {}

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function unwrapTarget(uint256 tBal) external override returns (uint256) {}
}
