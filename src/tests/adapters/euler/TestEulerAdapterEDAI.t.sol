// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../tokens/Tranche.sol";
import "../../../adapters/euler/EulerAdapter.sol";

import "../TestAdapter.t.sol";

contract TestEulerAdapterEDAI is TestAdapter {
    address eulerMain = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant eDAI = 0xe025E3ca2bE02316033184551D4d3Aa22024D9DC;

    function _setup() internal override {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        underlying = DAI;
        target = eDAI;

        adapter = new EulerAdapter(
            Adapter.AdapterParams({
                underlying: underlying,
                target: target,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            }),
            eulerMain
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

    function _fund() internal override {
        U_DECIMALS = IERC20Metadata(underlying).decimals();
        T_DECIMALS = IERC20Metadata(target).decimals();
        U_BASE = 10**U_DECIMALS;
        T_BASE = 10**T_DECIMALS;

        vm.deal(address(this), 1000 * U_BASE);

        vm.startPrank(address(0xcafe));

        IERC20(underlying).approve(eulerMain, type(uint256).max);
        uint256 amount = IEToken(target).convertBalanceToUnderlying(1000 * T_BASE + T_BASE);
        deal(underlying, address(0xcafe), amount, true);
        IEToken(target).deposit(0, amount);
        IEToken(target).transfer(address(this), 1000 * T_BASE); // fund

        vm.stopPrank();
    }
}
