// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../src/adapters/aave/AaveV2Adapter.sol";
import "../src/adapters/compound/CompoundAdapter.sol";
import "../src/adapters/yearn/YearnAdapter.sol";

import "./BaseScripts.sol";

contract Deploy is BaseScripts {
    function run() public {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        underlying = DAI_MAINNET;

        // Foundry supports various wallet options.
        // https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw
        vm.startBroadcast();

        Adapter[] memory adapters = new Adapter[](3);

        Adapter cAdapter = new CompoundAdapter(
            Adapter.AdapterParams({
                underlying: DAI_MAINNET,
                target: CDAI_MAINNET,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            }),
            WETH_MAINNET,
            CETH_MAINNET
        );

        Adapter yAdapter = new YearnAdapter(
            Adapter.AdapterParams({
                underlying: DAI_MAINNET,
                target: YDAI_MAINNET,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            })
        );

        Adapter aAdapter = new AaveV2Adapter(
            Adapter.AdapterParams({
                underlying: DAI_MAINNET,
                target: ADAI_MAINNET,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            }),
            LENDING_POOL_V2_MAINNET
        );

        adapters[0] = cAdapter;
        adapters[1] = yAdapter;
        adapters[2] = aAdapter;

        _deployTrancheAndCreatePool(adapters);

        vm.stopBroadcast();
    }
}
