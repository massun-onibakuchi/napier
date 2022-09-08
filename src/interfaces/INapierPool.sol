// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./INapierPoolFactory.sol";
import "./ITranche.sol";

interface INapierPool {
    function factory() external returns (INapierPoolFactory);

    function underlying() external returns (IERC20);

    function nPT() external returns (ITranche);

    function mint(address pt, address recipient) external returns (uint256 liquidity);

    function burn(address pt, address recipient) external returns (uint256 amountUnderunderlying, uint256 amountNPt);

    // TODO
    // function swap(
    //     uint256 amountUnderunderlying,
    //     uint256 amountNPt,
    //     address to,
    //     bytes calldata data
    // );
}
