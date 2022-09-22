// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../tokens/Tranche.sol";
import "../../../adapters/aave/AaveAdapter.sol";

import "../../../utils/FixedMath.sol";

import "../TestAdapter.t.sol";

contract TestAaveAdapterADAI is TestAdapter {
    using FixedMath for uint256;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant aDAI = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;

    function _setup() internal override {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        underlying = DAI;
        target = aDAI;

        adapter = new AaveAdapter(
            Adapter.AdapterParams({underlying: DAI, target: aDAI, delta: DELTA, minm: 0, maxm: 0, issuanceFee: feePst})
        );

        Adapter[] memory adapters = new Adapter[](1);
        adapters[0] = adapter;
        tranche = new Tranche(
            adapters,
            IERC20Metadata(underlying),
            maturity,
            address(this),
            INapierPoolFactory(address(this))
        );
    }
}
