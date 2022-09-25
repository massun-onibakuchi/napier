// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../src/adapters/aave/AaveV2Adapter.sol";
import "../src/adapters/compound/CompoundAdapter.sol";

import "./BaseScripts.sol";

contract Deploy is BaseScripts {
    function run() public {
        require(block.chainid == 5, "goerli");

        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        underlying = ADAI_UNDERLYING_GOERLI;

        // Foundry supports various wallet options.
        // https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw
        vm.startBroadcast();

        Adapter[] memory adapters = new Adapter[](1);

        // Adapter adapter = new AaveV2Adapter(
        //     Adapter.AdapterParams({
        //         underlying: underlying,
        //         target: ADAI_GOERLI,
        //         delta: DELTA,
        //         minm: 0,
        //         maxm: 0,
        //         issuanceFee: feePst
        //     }),
        //     LENDING_POOL_V2_GOERLI
        // );

        adapters[0] = adapter;

        _deployTrancheAndCreatePool(adapters);

        vm.stopBroadcast();
    }
}
