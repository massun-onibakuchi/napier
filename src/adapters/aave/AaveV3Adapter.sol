// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

// External references
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/aave-v3/IPool.sol";
import "../../interfaces/aave-v3/IPoolAddressesProvider.sol";

// Internal references
import "../BaseAdapter.sol";

/// @title AaveV3 Adapter
/// NOTE: Aave V3 https://docs.aave.com/developers/tokens/atoken
contract AaveV3Adapter is BaseAdapter, Ownable {
    using SafeERC20 for IERC20;

    /// @notice aave v3 pool address provider
    IPoolAddressesProvider public immutable provider;

    /// @notice referral code for aave v3
    uint16 public referralCode;

    constructor(AdapterParams memory _adapterParams, address _providerAddress) BaseAdapter(_adapterParams) {
        provider = IPoolAddressesProvider(_providerAddress);
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
        IERC20 _underlying = IERC20(adapterParams.underlying);
        address pool = provider.getPool();

        _underlying.safeTransferFrom(msg.sender, address(this), uBal);
        // x underlying => x aTokens
        _underlying.safeApprove(pool, uBal);
        // msg.sender will receive the aTokens
        IPool(pool).supply(address(_underlying), uBal, msg.sender, referralCode);

        return uBal;
    }

    /// @inheritdoc BaseAdapter
    /// @dev no funds should be left in the contract after this call
    function unwrapTarget(uint256 tBal) external override returns (uint256) {
        IERC20(adapterParams.target).safeTransferFrom(msg.sender, address(this), tBal);
        // msg.sender will receive the underlying
        IPool(provider.getPool()).withdraw(adapterParams.underlying, tBal, msg.sender);

        return tBal;
    }

    function setReferralCode(uint16 _code) external onlyOwner {
        referralCode = _code;
    }
}
