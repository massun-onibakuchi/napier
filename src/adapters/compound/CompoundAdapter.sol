// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

// External references
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/compound/CTokenInterface.sol";
import "../../interfaces/compound/CETHTokenInterface.sol";
import "../../interfaces/IWETH.sol";

// Internal references
import "../BaseAdapter.sol";

/// @notice Adapter contract for cTokens
contract CompoundAdapter is BaseAdapter {
    using FixedMath for uint256;
    using SafeERC20 for IERC20Metadata;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    receive() external payable {}

    constructor(AdapterParams memory _adapterParams) BaseAdapter(_adapterParams) {
        IERC20Metadata(_adapterParams.underlying).safeApprove(_adapterParams.target, type(uint256).max);
    }

    /// @inheritdoc BaseAdapter
    /// @notice NOTE: scale is in WAD term. (see `_to18Decimals()` method)
    /// @return Exchange rate from Target to Underlying using Compound's `exchangeRateCurrent()`, normed to 18 decimals
    function scale() external override returns (uint256) {
        uint256 exRate = CTokenInterface(adapterParams.target).exchangeRateCurrent();
        return _to18Decimals(exRate);
    }

    function scaleStored() external view returns (uint256) {
        uint256 exRate = CTokenInterface(adapterParams.target).exchangeRateStored();
        return _to18Decimals(exRate);
    }

    function _scale() internal override returns (uint256) {}

    function underlying() public view override returns (address) {
        address target = adapterParams.target;
        return _isCETH(target) ? WETH : CTokenInterface(target).underlying();
    }

    function wrapUnderlying(uint256 uBal) external override returns (uint256) {
        IERC20Metadata u = IERC20Metadata(underlying());
        IERC20Metadata target = IERC20Metadata(adapterParams.target);

        u.safeTransferFrom(msg.sender, address(this), uBal); // pull underlying

        bool isCETH = _isCETH(address(target));
        // unwrap WETH into ETH
        if (isCETH) {
            IWETH(WETH).withdraw(uBal);
        }
        // mint target
        uint256 tBalBefore = target.balanceOf(address(this));
        if (isCETH) {
            CETHTokenInterface(adapterParams.target).mint{value: uBal}();
        } else {
            require(CTokenInterface(adapterParams.target).mint(uBal) == 0, "Mint failed");
        }
        uint256 tBal = target.balanceOf(address(this)) - tBalBefore;
        // transfer target to sender
        target.safeTransfer(msg.sender, tBal);
        return tBal;
    }

    function unwrapTarget(uint256 tBal) external override returns (uint256) {
        IERC20Metadata u = IERC20Metadata(underlying());
        IERC20Metadata target = IERC20Metadata(adapterParams.target);
        bool isCETH = _isCETH(address(target));

        target.safeTransferFrom(msg.sender, address(this), tBal); // pull target

        // redeem target for underlying
        uint256 uBalBefore = isCETH ? address(this).balance : u.balanceOf(address(this));
        require(CTokenInterface(adapterParams.target).redeem(tBal) == 0, "Redeem failed");
        uint256 uBalAfter = isCETH ? address(this).balance : u.balanceOf(address(this));
        uint256 uBal = uBalAfter - uBalBefore;

        if (isCETH) {
            // deposit ETH into WETH contract
            (bool success, ) = WETH.call{value: uBal}("");
            require(success, "Adapter: ETH Transfer failed.");
        }
        // transfer underlying to sender
        u.safeTransfer(msg.sender, uBal);
        return uBal;
    }

    function _isCETH(address target) internal view returns (bool) {
        return keccak256(abi.encodePacked(IERC20Metadata(target).symbol())) == keccak256(abi.encodePacked("cETH"));
    }

    function _to18Decimals(uint256 exRate) internal view returns (uint256) {
        // From the Compound docs:
        // "exchangeRateCurrent() returns the exchange rate, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals)"
        //
        // The equation to norm an asset to 18 decimals is:
        // `num * 10**(18 - decimals)`
        //
        // So, when we try to norm exRate to 18 decimals, we get the following:
        // `exRate * 10**(18 - exRateDecimals)`
        // -> `exRate * 10**(18 - (18 - 8 + uDecimals))`
        // -> `exRate * 10**(8 - uDecimals)`
        // -> `exRate / 10**(uDecimals - 8)`
        return uDecimals >= 8 ? exRate / 10**(uDecimals - 8) : exRate * 10**(8 - uDecimals);
    }
}
