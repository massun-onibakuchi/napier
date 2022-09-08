// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/INapierPool.sol";

contract NapierPool is ERC20, INapierPool {
    INapierPoolFactory public immutable override factory;

    IERC20 public immutable override underlying;

    ITranche public immutable override nPT;

    // TODO: token name and symbol
    // TODO: deploy tranche with CREATE2 from factory, init with callback instead of constructor
    // ref: Element finance and Uniswap V3
    constructor(IERC20 _underlying, ITranche _nPT) ERC20("Napier Pool Token", "nPT") {
        underlying = _underlying;
        nPT = _nPT;
        factory = INapierPoolFactory(msg.sender);
    }

    function mint(address pt, address recipient) external returns (uint256 liquidity) {}

    function burn(address pt, address recipient) external returns (uint256 amountUnderunderlying, uint256 amountNPt) {}
}
