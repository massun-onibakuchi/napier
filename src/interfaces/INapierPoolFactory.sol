// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface INapierPoolFactory {
    function isRegisteredPool(address pool) external view returns (bool);

    function getData()
        external
        view
        returns (
            uint256,
            address,
            address,
            address
        );

    function createPool(address underlying, address nPT) external returns (address);
}
