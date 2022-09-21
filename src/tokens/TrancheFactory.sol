// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {BaseAdapter as Adapter} from "../adapters/BaseAdapter.sol";
import "./Tranche.sol";

contract TrancheFactory {
    mapping(address => bool) private _isTrancheRegistered;

    function createTranche(
        address _underlying,
        Adapter[] memory _adapters,
        uint256 _maturity
    ) external returns (ITranche tranche) {
        // TODO
    }
}
