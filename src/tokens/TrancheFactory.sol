// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol.sol";

import "./Tranche.sol";

contract TrancheFactory {
    //  using EnumerableSet for EnumerableSet.AddressSet;
    //  EnumerableSet.AddressSet private tranches;

    mapping(address => bool) private _isTrancheRegistered;

    function createTranche(
        address _underlying,
        Tranche.InitParams[] memory _params,
        uint256 _maturity
    ) external returns (ITranche tranche) {
        // TODO
    }
}
