// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

// External references
import {SafeERC20, ERC20} from "solmate/erc20/SafeERC20.sol";
import {FixedMath} from "../../utils/FixedMath.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface CTokenInterface {
    /// @notice cToken is convertible into an ever increasing quantity of the underlying asset, as interest accrues in
    /// the market. This function returns the exchange rate between a cToken and the underlying asset.
    /// @dev returns the current exchange rate as an uint, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals).
    function exchangeRateCurrent() external returns (uint256);

    function decimals() external returns (uint256);

    function underlying() external view returns (address);

    /// The mint function transfers an asset into the protocol, which begins accumulating interest based
    /// on the current Supply Rate for the asset. The user receives a quantity of cTokens equal to the
    /// underlying tokens supplied, divided by the current Exchange Rate.
    /// @param mintAmount The amount of the asset to be supplied, in units of the underlying asset.
    /// @return 0 on success, otherwise an Error code
    function mint(uint256 mintAmount) external returns (uint256);

    /// The redeem function converts a specified quantity of cTokens into the underlying asset, and returns
    /// them to the user. The amount of underlying tokens received is equal to the quantity of cTokens redeemed,
    /// multiplied by the current Exchange Rate. The amount redeemed must be less than the user's Account Liquidity
    /// and the market's available liquidity.
    /// @param redeemTokens The number of cTokens to be redeemed.
    /// @return 0 on success, otherwise an Error code
    function redeem(uint256 redeemTokens) external returns (uint256);
}

interface CETHTokenInterface {
    ///@notice Send Ether to CEther to mint
    function mint() external payable;
}

/// @notice Adapter contract for cTokens
contract CompoundAdapter is BaseAdapter {
    using FixedMath for uint256;
    using SafeERC20 for ERC20;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function _scale() internal override returns (uint256) {
        uint256 decimals = CTokenInterface(underlying()).decimals();
        return CTokenInterface(adapterParams.target).exchangeRateCurrent().fdiv(10**(10 + decimals), 10**decimals);
    }

    function underlying() public view override returns (address) {
        // address target = adapterParams.target;
        // return _isCETH(target) ? WETH : CTokenInterface(target).underlying();
    }

    function wrapUnderlying(uint256 uBal) external override returns (uint256) {
        // ERC20 u = ERC20(underlying());
        // ERC20 target = ERC20(adapterParams.target);
        // bool isCETH = _isCETH(address(adapterParams.target));
        // u.safeTransferFrom(msg.sender, address(this), uBal); // pull underlying
        // if (isCETH) IWETH(WETH).withdraw(uBal); // unwrap WETH into ETH
        // // mint target
        // uint256 tBalBefore = target.balanceOf(address(this));
        // if (isCETH) {
        //     CETHTokenInterface(adapterParams.target).mint{value: uBal}();
        // } else {
        //     require(CTokenInterface(adapterParams.target).mint(uBal) == 0, "Mint failed");
        // }
        // uint256 tBalAfter = target.balanceOf(address(this));
        // uint256 tBal = tBalAfter - tBalBefore;
        // // transfer target to sender
        // ERC20(target).safeTransfer(msg.sender, tBal);
        // return tBal;
    }

    function unwrapTarget(uint256 tBal) external override returns (uint256) {
        // ERC20 u = ERC20(underlying());
        // bool isCETH = _isCETH(address(adapterParams.target));
        // ERC20 target = ERC20(adapterParams.target);
        // target.safeTransferFrom(msg.sender, address(this), tBal); // pull target
        // // redeem target for underlying
        // uint256 uBalBefore = isCETH ? address(this).balance : u.balanceOf(address(this));
        // require(CTokenInterface(adapterParams.target).redeem(tBal) == 0, "Redeem failed");
        // uint256 uBalAfter = isCETH ? address(this).balance : u.balanceOf(address(this));
        // uint256 uBal = uBalAfter - uBalBefore;
        // if (isCETH) {
        //     // deposit ETH into WETH contract
        //     (bool success, ) = WETH.call{value: uBal}("");
        //     require(success, "Transfer failed.");
        // }
        // // transfer underlying to sender
        // u.safeTransfer(msg.sender, uBal);
        // return uBal;
    }

    function _isCETH(address target) internal view returns (bool) {
        return keccak256(abi.encodePacked(ERC20(target).symbol())) == keccak256(abi.encodePacked("cETH"));
    }

    fallback() external payable {}
}
