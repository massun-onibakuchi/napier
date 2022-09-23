// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYearnVault is IERC20 {
    function governance() external view returns (address);

    /// @notice Returns the total quantity of all assets under control of this Vault,
    ///         whether they're loaned out to a Strategy, or currently held in the Vault.
    function totalAssets() external view returns (uint256);

    /// @notice Returns the amount of underlying per each unit [1e18] of yearn shares
    function pricePerShare() external view returns (uint256);

    /// @notice https://docs.yearn.finance/vaults/smart-contracts/vault#deposit
    ///  Measuring quantity of shares to issues is based on the total outstanding debt that this contract has ("expected value")
    ///  instead of the total balance sheet it has ("estimated value") has important security considerations,
    ///  and is done intentionally.
    /// @param amount The quantity of tokens to deposit, defaults to all.
    /// @param recipient The address to issue the shares in this Vault to. Defaults to the caller's address
    /// @return shares The issued Vault shares
    function deposit(uint256 amount, address recipient) external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    /// @notice https://docs.yearn.finance/vaults/smart-contracts/vault#withdraw
    /// @param maxShares How many shares to try and redeem for tokens, defaults to all.
    /// @param recipient The address to issue the shares in this Vault to. Defaults to the caller's address.
    /// @param maxLoss The maximum acceptable loss to sustain on withdrawal. Defaults to 0.01%.
    /// @return The quantity of tokens redeemed for _shares.
    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);
}
