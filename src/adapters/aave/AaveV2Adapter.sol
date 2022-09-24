// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

// External references
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAToken} from "../../interfaces/aave-v2/IAToken.sol";
import {ILendingPool} from "../../interfaces/aave-v2/ILendingPool.sol";

// Internal references
import "../BaseAdapter.sol";

/// @title AaveV2 Adapter
/// NOTE: Aave V2 https://docs.aave.com/developers/tokens/atoken
contract AaveV2Adapter is BaseAdapter {
    using SafeERC20 for IERC20Metadata;

    ILendingPool public immutable pool;

    constructor(AdapterParams memory _adapterParams, address _poolAddress) BaseAdapter(_adapterParams) {
        require(
            adapterParams.underlying == IAToken(_adapterParams.target).UNDERLYING_ASSET_ADDRESS(),
            "AaveV2Adapter: unmatching underlying"
        );

        pool = ILendingPool(_poolAddress);

        IERC20Metadata(_adapterParams.underlying).safeApprove(_poolAddress, type(uint256).max);
    }

    /// @inheritdoc BaseAdapter
    /// @notice 1:1 exchange rate
    function scale() external pure override returns (uint256) {
        return FixedMath.WAD;
    }

    function scaleStored() external pure override returns (uint256) {
        return FixedMath.WAD;
    }

    function _scale() internal override returns (uint256) {}

    /// @inheritdoc BaseAdapter
    function underlying() public view override returns (address) {
        return adapterParams.underlying;
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function wrapUnderlying(uint256 uBal) external override returns (uint256) {
        require(uBal > 0, "AaveV2Adapter: uBal lower than 0");

        IERC20Metadata _underlying = IERC20Metadata(adapterParams.underlying);
        IERC20Metadata _target = IERC20Metadata(adapterParams.target);

        uint256 tBalBefore = _target.balanceOf(msg.sender);

        _underlying.safeTransferFrom(msg.sender, address(this), uBal);
        pool.deposit(address(_underlying), uBal, msg.sender, 0);

        uint256 tBalAfter = _target.balanceOf(msg.sender);
        uint256 tBal = tBalAfter - tBalBefore;
        require(tBal == uBal, "AaveV2Adapter: Balance Inequality");
        return tBal;
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function unwrapTarget(uint256 tBal) external override returns (uint256) {
        require(tBal > 0, "AaveV2Adapter: tBal lower than 0");

        IERC20Metadata _underlying = IERC20Metadata(adapterParams.underlying);
        IERC20Metadata _target = IERC20Metadata(adapterParams.target);

        uint256 uBalBefore = _underlying.balanceOf(msg.sender);

        _target.safeTransferFrom(msg.sender, address(this), tBal);
        pool.withdraw(address(_target), tBal, msg.sender);

        uint256 uBalAfter = _underlying.balanceOf(msg.sender);
        uint256 uBal = uBalAfter - uBalBefore;
        require(uBal == tBal, "AaveV2Adapter: Balance Inequality");
        return uBal;
    }
}
