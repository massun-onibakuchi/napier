// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../src/adapters/aave/AaveV2Adapter.sol";
import "../src/adapters/compound/CompoundAdapter.sol";
import "../src/adapters/yearn/YearnAdapter.sol";
import "../src/adapters/aave/AaveV2Adapter.sol";
import "../src/tokens/Tranche.sol";
import {NapierPoolFactory, NapierPool} from "../src/pool/NapierPoolFactory.sol";

import "forge-std/Script.sol";

contract Deploy is Script {
    uint256 internal constant DELTA = 150;

    address internal constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address internal constant DAI_GOERLI = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844;

    // compound
    address internal constant CDAI_GOERLI = 0x0545a8eaF7ff6bB6F708CbB544EA55DBc2ad7b2a;
    address internal constant CETH_GOERLI = 0x64078a6189Bf45f80091c6Ff2fCEe1B15Ac8dbde;

    // aave v2
    address internal constant ADAI_GOERLI = 0x31f30d9A5627eAfeC4433Ae2886Cf6cc3D25E772;
    address internal constant LENDING_POOL_V2_GOERLI = 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210;

    function run() public {
        uint256 feePst = 0;
        uint256 maturity = block.timestamp + 10 weeks;
        address underlying = DAI_GOERLI;

        // Foundry supports various wallet options.
        // https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw
        vm.startBroadcast();

        Adapter[] memory adapters = new Adapter[](2);

        Adapter cAdapter = new CompoundAdapter(
            Adapter.AdapterParams({
                underlying: DAI_GOERLI,
                target: CDAI_MAINNET,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            })
        );

        Adapter aAdapter = new AaveV2Adapter(
            Adapter.AdapterParams({
                underlying: DAI_GOERLI,
                target: ADAI_MAINNET,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            }),
            LENDING_POOL_V2_MAINNET
        );

        adapters[0] = cAdapter;
        adapters[1] = aAdapter;

        NapierPoolFactory poolFactory = new NapierPoolFactory(address(this));
        Tranche tranche = new Tranche(adapters, IERC20Metadata(underlying), maturity, msg.sender, poolFactory);
        address pool = poolFactory.createPool(underlying, address(tranche));

        vm.stopBroadcast();
    }
}
