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
        require(adapterParams.underlying == underlying(), "AaveAdapter: unmatching underlying");

        _pool = ILendingPool(LENDING_POOL_V2_MAINNET);

        // TODO: check how to approve deposit for Aave LendingPool
        IERC20Metadata(_adapterParams.underlying).safeApprove(LENDING_POOL_V2_MAINNET, type(uint256).max);
    }

    /// @inheritdoc BaseAdapter
    /// @notice 1:1 exchange rate
    function scale() external override returns (uint256) {
        return 1 * 10**(18 - uDecimals);
    }

    function _scale() internal override returns (uint256) {}

    /// @inheritdoc BaseAdapter
    function underlying() public view override returns (address) {
        address target = adapterParams.target;
        return IAToken(target).UNDERLYING_ASSET_ADDRESS();
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function wrapUnderlying(uint256 uBal) external override returns (uint256) {
        require(IERC20Metadata(underlying()).balanceOf(address(msg.sender)) >= uBal, "AaveAdapter: Insufficient uBal");

        IERC20Metadata target = IERC20Metadata(adapterParams.target);
        uint256 tBalBefore = target.balanceOf(msg.sender);

        _pool.deposit(underlying(), uBal, msg.sender, 0);

        uint256 tBalAfter = target.balanceOf(msg.sender);
        uint256 tBal = tBalAfter - tBalBefore;
        require(tBal == uBal, "AaveAdapter: Balance Inequality");
        return tBal;
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function unwrapTarget(uint256 tBal) external override returns (uint256) {
        require(IERC20Metadata(adapterParams.target).balanceOf(address(msg.sender)) >= tBal, "AaveAdapter: Insufficient tBal");

        uint256 uBalBefore = IERC20Metadata(underlying()).balanceOf(msg.sender);

        uint256 withdrawnAmount = _pool.withdraw(adapterParams.target, tBal, msg.sender);

        uint256 uBalAfter = IERC20Metadata(underlying()).balanceOf(msg.sender);
        uint256 uBal = uBalAfter - uBalBefore;
        require(uBal == tBal, "AaveAdapter: Balance Inequality");
        require(uBal == withdrawnAmount, "AaveAdapter: Balance Inequality");
        return uBal;
    }
}
