// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

// External references
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/euler/IEToken.sol";

// Internal references
import "../BaseAdapter.sol";

contract EulerAdapter is BaseAdapter {
    using SafeERC20 for IERC20;

    uint256 internal SUB_ACCOUNT_ID = 0;

    constructor(AdapterParams memory _adapterParams, address _eulerMain) BaseAdapter(_adapterParams) {
        // approve Euler protocol uint256 max for deposits
        IERC20(adapterParams.underlying).safeApprove(_eulerMain, type(uint256).max);
    }

    /// @inheritdoc BaseAdapter
    function scale() external view override returns (uint256) {
        return _scale();
    }

    function scaleStored() external view override returns (uint256) {
        return _scale();
    }

    function _scale() internal view override returns (uint256) {
        return _normalize(IEToken(adapterParams.target).convertBalanceToUnderlying(FixedMath.WAD), uDecimals);
    }

    /// @inheritdoc BaseAdapter
    function underlying() public view override returns (address) {
        return adapterParams.underlying;
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function wrapUnderlying(uint256 uBal) external override returns (uint256 tBal) {
        IEToken _eToken = IEToken(adapterParams.target);

        IERC20(adapterParams.underlying).safeTransferFrom(msg.sender, address(this), uBal);
        /// deposit underlying in Euler
        uint256 eTokenBalanceBefore = _eToken.balanceOf(address(this));
        _eToken.deposit(SUB_ACCOUNT_ID, uBal);
        tBal = _eToken.balanceOf(address(this)) - eTokenBalanceBefore;
        /// transfer eTokens to msg.sender
        _eToken.transfer(msg.sender, tBal);
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function unwrapTarget(uint256 tBal) external override returns (uint256 uBal) {
        IERC20 _underlying = IERC20(adapterParams.underlying);

        IERC20(adapterParams.target).safeTransferFrom(msg.sender, address(this), tBal);

        uint256 underlyingTokenBalanceBefore = _underlying.balanceOf(address(this));
        IEToken(adapterParams.target).withdraw(SUB_ACCOUNT_ID, tBal);
        uBal = _underlying.balanceOf(address(this)) - underlyingTokenBalanceBefore;

        // transfer uBal underlying tokens to msg.sender
        _underlying.safeTransfer(msg.sender, uBal);
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
