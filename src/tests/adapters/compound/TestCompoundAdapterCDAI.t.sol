// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../tokens/Tranche.sol";
import "../../../adapters/compound/CompoundAdapter.sol";

import "../../../utils/FixedMath.sol";

import "../TestAdapter.t.sol";

contract TestCompoundAdapterCDAI is TestAdapter {
    using FixedMath for uint256;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    function _setup() internal override {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        underlying = DAI;
        target = cDAI;

        adapter = new CompoundAdapter(
            Adapter.AdapterParams({underlying: DAI, target: cDAI, delta: DELTA, minm: 0, maxm: 0, issuanceFee: feePst}),
            WETH,
            CETH
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
