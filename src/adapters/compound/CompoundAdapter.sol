// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

// External references
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/compound/CTokenInterface.sol";
import "../../interfaces/compound/CETHTokenInterface.sol";
import "../../interfaces/IWETH.sol";

// Internal references
import "../BaseAdapter.sol";

/// @notice Adapter contract for cTokens
contract CompoundAdapter is BaseAdapter {
    using FixedMath for uint256;
    using SafeERC20 for IERC20;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    constructor(AdapterParams memory _adapterParams) BaseAdapter(_adapterParams) {
        IERC20(_adapterParams.underlying).safeApprove(_adapterParams.target, type(uint256).max);
    }

    function _scale() internal override returns (uint256) {
        uint256 decimals = CTokenInterface(underlying()).decimals();
        return CTokenInterface(adapterParams.target).exchangeRateCurrent().fdiv(10**(10 + decimals), 10**decimals);
    }

    function underlying() public view override returns (address) {
        address target = adapterParams.target;
        return _isCETH(target) ? WETH : CTokenInterface(target).underlying();
    }

    function wrapUnderlying(uint256 uBal) external override returns (uint256) {
        IERC20 u = IERC20(underlying());
        IERC20 target = IERC20(adapterParams.target);
        bool isCETH = _isCETH(address(adapterParams.target));
        u.safeTransferFrom(msg.sender, address(this), uBal); // pull underlying
        if (isCETH) IWETH(WETH).withdraw(uBal); // unwrap WETH into ETH
        // mint target
        uint256 tBalBefore = target.balanceOf(address(this));
        if (isCETH) {
            CETHTokenInterface(adapterParams.target).mint{value: uBal}();
        } else {
            require(CTokenInterface(adapterParams.target).mint(uBal) == 0, "Mint failed");
        }
        uint256 tBalAfter = target.balanceOf(address(this));
        uint256 tBal = tBalAfter - tBalBefore;
        // transfer target to sender
        IERC20(target).safeTransfer(msg.sender, tBal);
        return tBal;
    }

    function unwrapTarget(uint256 tBal) external override returns (uint256) {
        IERC20 u = IERC20(underlying());
        IERC20 target = IERC20(adapterParams.target);
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

    receive() external payable {}
}
