// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

// External references
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Internal references
import "../BaseAdapter.sol";



interface ATokenInterface {

    
    function decimals() external returns (uint256);

    function underlying() external view returns (address);

    /// The mint function transfers an asset into the protocol, which begins accumulating interest based
    /// on the current Supply Rate for the asset. The user receives a quantity of aTokens equal to the
    /// underlying tokens supplied.
    /// @param mintAmount The amount of the asset to be supplied, in units of the underlying asset.
    /// @return 0 on success, otherwise an Error code
    function mint(uint256 mintAmount) external returns (uint256);

    /// The redeem function converts a specified quantity of aTokens into the underlying asset, and returns
    /// them to the user. The amount of underlying tokens received is equal to the quantity of aTokens redeemed,
    /// @param redeemTokens The number of aTokens to be redeemed.
    /// @return 0 on success, otherwise an Error code
    function redeem(uint256 redeemTokens) external returns (uint256);
}

interface AETHTokenInterface {
    ///@notice Send Ether to CEther to mint
    function mint() external payable;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract AaveAdapter is BaseAdapter {


    using FixedMath for uint256;
    using SafeERC20 for IERC20;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant AETH = 0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04;


    constructor(AdapterParams memory _adapterParams) BaseAdapter(_adapterParams) {}


    // 1 : 1 
    function _scale() internal override returns (uint256) {
        return ATokenInterface(underlying()).decimals();
    }

    
    function underlying() public view override returns (address) {
        address target = adapterParams.target;
        return _isAETH(target) ? WETH : ATokenInterface(target).underlying();
    }

    function wrapUnderlying (uint256 uBal) external override returns (uint256) {
        IERC20 u = IERC20(underlying());
        IERC20 target = IERC20(adapterParams.target);
        bool isAETH = _isAETH(address(adapterParams.target));
        u.safeTransferFrom(msg.sender, address(this), uBal);
        if (isAETH) IWETH(WETH).withdraw(uBal); //unwrap WETH

        //mint target
        uint256 tBalBefore = target.balanceOf(address(this));
        if (isAETH) {
            AETHTokenInterface(adapterParams.target).mint{value: uBal}();
        } else {
            require(ATokenInterface(adapterParams.target).mint(uBal) == 0, "Mint failed");
        }
        uint256 tBalAfter = target.balanceOf(address(this));
        uint256 tBal = tBalAfter - tBalBefore;
        // transfer target to sender
        IERC20(target).safeTransfer(msg.sender, tBal);
        return tBal; 

    }

    function unwrapTarget(uint256 tBal) external override returns (uint256) {
        IERC20 u = IERC20(underlying());
        bool isAETH = _isAETH(address(adapterParams.target));
        IERC20 target = IERC20(adapterParams.target);
        target.safeTransferFrom(msg.sender, address(this), tBal); // pull target
        // redeem target for underlying
        uint256 uBalBefore = isAETH ? address(this).balance : u.balanceOf(address(this));
        require(ATokenInterface(adapterParams.target).redeem(tBal) == 0, "Redeem failed");
        uint256 uBalAfter = isAETH ? address(this).balance : u.balanceOf(address(this));
        uint256 uBal = uBalAfter - uBalBefore;
        if (isAETH) {
            // deposit ETH into WETH contract
            (bool success, ) = WETH.call{value: uBal}("");
            require(success, "Transfer failed.");
        }
        // transfer underlying to sender
        u.safeTransfer(msg.sender, uBal);
        return uBal;
    }


    receive() external payable {}


     function _isAETH(address target) internal view returns (bool) {
        return keccak256(abi.encodePacked(IERC20Metadata(target).symbol())) == keccak256(abi.encodePacked("aETH"));
    }

}


