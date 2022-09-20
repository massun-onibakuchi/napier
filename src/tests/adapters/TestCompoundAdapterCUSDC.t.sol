// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../tokens/Tranche.sol";
import "../../adapters/compound/CompoundAdapter.sol";

import "../../utils/FixedMath.sol";

import "./TestAdapter.t.sol";

contract TestCompoundAdapterCUSDC is TestAdapter {
    using FixedMath for uint256;

    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    function _setup() internal override {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        underlying = USDC;
        target = cUSDC;

        adapter = new CompoundAdapter(
            Adapter.AdapterParams({underlying: USDC, target: cUSDC, delta: DELTA, minm: 0, maxm: 0, issuanceFee: feePst})
        );

        Adapter[] memory adapters = new Adapter[](1);
        adapters[0] = adapter;
        tranche = new Tranche(adapters, underlying, maturity, address(this), INapierPoolFactory(address(this)));
    }
}
