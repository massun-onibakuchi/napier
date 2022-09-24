// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../src/adapters/aave/AaveV2Adapter.sol";
import "../src/adapters/aave/AaveV3Adapter.sol";
import "../src/tokens/Tranche.sol";
import {NapierPoolFactory, NapierPool} from "../src/pool/NapierPoolFactory.sol";

import "forge-std/Script.sol";

contract Deploy is Script {
    uint256 internal constant DELTA = 150;

    address internal constant WMATIC_MUMBAI = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

    // aave v2
    address internal constant AWMATIC_V2_MUMBAI = 0xF45444171435d0aCB08a8af493837eF18e86EE27;

    address internal constant LENDING_POOL_V2_MUMBAI = 0x9198F13B08E299d85E096929fA9781A1E3d5d827;

    // aave v3
    address internal constant AWMATIC_V3_MUMBAI = 0x89a6AE840b3F8f489418933A220315eeA36d11fF;

    address internal constant PROVIDER_V3_MUMBAI = 0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6;

    function run() public {
        require(block.chainid == 80001, "polygon mumbai only");

        uint256 feePst = 0;
        uint256 maturity = block.timestamp + 10 weeks;
        address underlying = WMATIC_MUMBAI;

        // Foundry supports various wallet options.
        // https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw
        vm.startBroadcast();

        Adapter[] memory adapters = new Adapter[](2);

        Adapter aAdapterV2 = new AaveV2Adapter(
            Adapter.AdapterParams({
                underlying: WMATIC_MUMBAI,
                target: AWMATIC_V2_MUMBAI,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            }),
            LENDING_POOL_V2_MUMBAI
        );

        Adapter aAdapterV3 = new AaveV3Adapter(
            Adapter.AdapterParams({
                underlying: WMATIC_MUMBAI,
                target: AWMATIC_V3_MUMBAI,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            }),
            PROVIDER_V3_MUMBAI
        );

        adapters[0] = aAdapterV2;
        adapters[1] = aAdapterV3;

        NapierPoolFactory poolFactory = new NapierPoolFactory(address(this));
        Tranche tranche = new Tranche(adapters, IERC20Metadata(underlying), maturity, msg.sender, poolFactory);
        address pool = poolFactory.createPool(underlying, address(tranche));

        vm.stopBroadcast();
    }
}
