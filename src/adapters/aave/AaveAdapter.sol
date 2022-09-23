// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

// External references
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAToken} from "../../interfaces/aave/IAToken.sol";
import {ILendingPool} from "../../interfaces/aave/ILendingPool.sol";

// Internal references
import "../BaseAdapter.sol";

/// @title AaveV2 Adapter
/// NOTE: Aave V2 https://docs.aave.com/developers/tokens/atoken
contract AaveAdapter is BaseAdapter {
    using FixedMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // TODO: Select LendingPool by ChainId
    address public constant LENDING_POOL_V2_MAINNET = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    ILendingPool internal _pool;

    constructor(AdapterParams memory _adapterParams) BaseAdapter(_adapterParams) {
        require(adapterParams.underlying == IAToken(_adapterParams.target).UNDERLYING_ASSET_ADDRESS(), "AaveAdapter: unmatching underlying");

        _pool = ILendingPool(LENDING_POOL_V2_MAINNET);

        // TODO: check how to approve deposit for Aave LendingPool
        IERC20Metadata(_adapterParams.underlying).safeApprove(LENDING_POOL_V2_MAINNET, type(uint256).max);
    }

    /// @inheritdoc BaseAdapter
    /// @notice 1:1 exchange rate
    function scale() external override returns (uint256) {
        return _normalize(1, uDecimals);
    }

    function _scale() internal override returns (uint256) {}

    /// @inheritdoc BaseAdapter
    function underlying() public view override returns (address) {
        return adapterParams.underlying;
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function wrapUnderlying(uint256 uBal) external override returns (uint256) {
        require(uBal > 0, "AaveAdapter: uBal lower than 0");
        require(IERC20Metadata(underlying()).balanceOf(address(msg.sender)) >= uBal, "AaveAdapter: Insufficient uBal");

        IERC20Metadata target = IERC20Metadata(adapterParams.target);
        uint256 tBalBefore = target.balanceOf(msg.sender);

        IERC20Metadata(underlying()).safeTransferFrom(msg.sender, address(this), uBal);
        _pool.deposit(underlying(), uBal, msg.sender, 0);

        uint256 tBalAfter = target.balanceOf(msg.sender);
        uint256 tBal = tBalAfter - tBalBefore;
        require(tBal == uBal, "AaveAdapter: Balance Inequality");
        return tBal;
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function unwrapTarget(uint256 tBal) external override returns (uint256) {
        require(tBal > 0, "AaveAdapter: tBal lower than 0");
        require(IERC20Metadata(adapterParams.target).balanceOf(address(msg.sender)) >= tBal, "AaveAdapter: Insufficient tBal");

        uint256 uBalBefore = IERC20Metadata(underlying()).balanceOf(msg.sender);

        IERC20Metadata(adapterParams.target).safeTransferFrom(msg.sender, address(this), tBal);
        uint256 withdrawnAmount = _pool.withdraw(adapterParams.target, tBal, msg.sender);

        uint256 uBalAfter = IERC20Metadata(underlying()).balanceOf(msg.sender);
        uint256 uBal = uBalAfter - uBalBefore;
        require(uBal == tBal, "AaveAdapter: Balance Inequality");
        require(uBal == withdrawnAmount, "AaveAdapter: Balance Inequality");
        return uBal;
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
        } else if (decimals == 18) {
            amount = amount * 10**18;
        }
        // If nothing changed this is a no-op
        return amount;
    }
}
