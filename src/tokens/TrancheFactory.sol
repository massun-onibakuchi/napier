// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {BaseAdapter as Adapter} from "../adapters/BaseAdapter.sol";
import "./Tranche.sol";

contract TrancheFactory {
    //  using EnumerableSet for EnumerableSet.AddressSet;
    //  EnumerableSet.AddressSet private tranches;

    mapping(address => bool) private _isTrancheRegistered;

    function createTranche(
        address _underlying,
        Adapter[] memory adapters,
        uint256 _maturity
    ) external returns (ITranche tranche) {
        // TODO
    }
}
