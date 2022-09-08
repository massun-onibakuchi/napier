// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../interfaces/INapierPoolFactory.sol";

contract NapierPoolFactory is INapierPoolFactory {
    mapping(address => bool) private _isPoolRegistered;

    function createPool(address underlying, address nPT) external returns (address) {
        // TODO
    }
}
