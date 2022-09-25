// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../src/adapters/aave/AaveV2Adapter.sol";
import "../src/adapters/aave/AaveV3Adapter.sol";

import "./BaseScripts.sol";

contract Deploy is BaseScripts {
    function run() public {
        require(block.chainid == 80001, "polygon mumbai only");

        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        underlying = AWMATIC_V3_UNDERLYING_MUMBAI;

        // Foundry supports various wallet options.
        // https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw
        vm.startBroadcast();

        Adapter[] memory adapters = new Adapter[](1);

        Adapter aAdapterV2 = new AaveV3Adapter(
            Adapter.AdapterParams({
                underlying: underlying,
                target: AWMATIC_V3_MUMBAI,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            }),
            PROVIDER_V3_MUMBAI
        );

        adapters[0] = aAdapterV2;

        _deployTrancheAndCreatePool(adapters);

        vm.stopBroadcast();
    }
}
