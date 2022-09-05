// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface ITranche {
    function scale() external;

    /// @notice Mint Zeros and Claims of a specific protocol
    /// @param pt principal token address
    /// @param tAmount amount of Target to deposit
    /// @dev The balance of Zeros/Claims minted will be the same value in units of underlying (less fees)
    function issue(address pt, uint256 tAmount) external returns (uint256 uAmount);

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

    function collect(
        address usr,
        address pt,
        uint256 uAmountTransfer,
        address to
    ) external returns (uint256 collected);
}
