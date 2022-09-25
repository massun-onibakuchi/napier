// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BaseAdapter as Adapter} from "../adapters/BaseAdapter.sol";

/// @title Napier Principal Token interface
/// @dev This contract is responsible for issuing/redeeming each principal token.
///      Napier Principal Token is called as nPT.
///      nPT is like a indexed token, which is composed of some Prinicipal Tokens such as PT of aDAI and PT of cDAI.
interface ITranche is IERC20Metadata {
    struct Series {
        address claim; // Claim ERC20 token
        Adapter adapter; // Adapter
        uint256 reward; // tracks fees due to the series' settler
        uint256 iscale; // scale at issuance
        uint256 mscale; // scale at maturity
        uint256 maxscale; // max scale value from this series' lifetime
        uint128 tilt; // % of underlying principal initially reserved for Claims
    }

    struct SeriesFull {
        address target; // Target ERC20 token
        address zero; // Zero ERC20 token
        address claim; // Claim ERC20 token
        Adapter adapter; // Adapter
        uint256 reward; // tracks fees due to the series' settler
        uint256 iscale; // scale at issuance
        uint256 mscale; // scale at maturity
        uint256 maxscale; // max scale value from this series' lifetime
        uint128 tilt; // % of underlying principal initially reserved for Claims
    }

    event SeriesInitialized(address indexed nPT, uint256 indexed maturity, address indexed sponsor);

    event Issued(address pt, uint256 balance, address indexed sender);

    event Combined(address pt, uint256 balance, address indexed sender);

    event Collected(address pt, uint256 collected);

    function maturity() external returns (uint256);

    function issuance() external returns (uint256);

    function underlying() external returns (IERC20Metadata);

    function getZeros() external view returns (address[] memory);

    function getSeries(address) external view returns (Series memory);

    function getAllSeriesFull() external view returns (SeriesFull[] memory);

    /// @notice mint NapierPT
    /// @dev only registered pools can mint
    /// @param pt The principal token address
    /// @param uAmount deposit amount of underlying
    /// @param uReserve underlying reserve
    /// @param nptReserve NapierPT reserve
    function mintNapierPT(
        address pt,
        uint256 uAmount,
        uint256 uReserve,
        uint256 nptReserve
    )
        external
        returns (
            uint256 uAmountUse,
            uint256 ptAmount,
            uint256 nptAmount
        );

    /// @param pt address
    /// @param uAmount underlying amount
    /// @param uReserve underlying reserve
    /// @param nptReserve NapierPricipalToken reserve
    /// @param scale npt scale
    /// @return uAmountUse underlying amount used
    /// @return nptAmount npt amount to be minted
    function computeNptToMint(
        address pt,
        uint256 uAmount,
        uint256 uReserve,
        uint256 nptReserve,
        uint256 scale
    ) external view returns (uint256 uAmountUse, uint256 nptAmount);

    /// @notice burn NapierPT
    /// @dev only registered pools can burn
    /// @param account The address from where to burn tokens from
    /// @param amount The amount to be burned
    function burnNapierPT(address account, uint256 amount) external;

    /// @notice nPT scale which is calculated based on several PT scales
    function scale() external returns (uint256);

    function scaleStored() external view returns (uint256);

    /// @notice Mint Zeros and Claims of a specific protocol
    /// @dev The balance of Zeros/Claims minted will be the same value in units of underlying (less fees)
    /// @param pt principal token address
    /// @param uAmount amount of underlying to deposit
    /// @return mintAmount amount of PT and YT minted
    function issueFromUnderlying(address pt, uint256 uAmount) external returns (uint256 mintAmount);

    /// @notice Mint Zeros and Claims of a specific protocol
    /// @dev The balance of Zeros/Claims minted will be the same value in units of underlying (less fees)
    /// @param pt principal token address
    /// @param tAmount amount of Target to deposit
    function issue(address pt, uint256 tAmount) external returns (uint256 mintAmount);

    /// @notice Reconstitute Target by burning Zeros and Claims
    /// @dev Explicitly burns claims before maturity, and implicitly does it at/after maturity through `_collect()`
    /// @param pt principal token address
    /// @param uAmount Balance of Zeros and Claims to burn
    function combine(address pt, uint256 uAmount) external returns (uint256 tAmount);

    /// @notice Burn Zeros of a Series once its been settled
    /// @dev The balance of redeemable Target is a function of the change in Scale
    /// @param pt principal token address
    /// @param uAmount Amount of Zeros to burn, which should be equivelent to the amount of Underlying owed to the caller
    function redeemZero(address pt, uint256 uAmount) external returns (uint256 tBal);

    /// @notice collect accrued past yield based on the user's YT balance
    function collect(
        address usr,
        address pt,
        uint256 uAmountTransfer,
        address to
    ) external returns (uint256 collected);
}
