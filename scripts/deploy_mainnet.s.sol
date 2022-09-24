// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../src/adapters/aave/AaveAdapter.sol";
import "../src/adapters/compound/CompoundAdapter.sol";
import "../src/adapters/yearn/YearnAdapter.sol";
import "../src/adapters/aave/AaveAdapter.sol";
import "../src/tokens/Tranche.sol";
import {NapierPoolFactory, NapierPool} from "../src/pool/NapierPoolFactory.sol";

import "forge-std/Script.sol";

contract Deploy is Script {
    uint256 internal constant DELTA = 150;

    address internal constant DAI_MAINNET = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // compound
    address internal constant CDAI_MAINNET = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address internal constant CDAI_GOERLI = 0x0545a8eaF7ff6bB6F708CbB544EA55DBc2ad7b2a;
    address internal constant CETH_MAINNET = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    // yearn
    address internal constant YDAI_MAINNET = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;

    // aave
    address internal constant ADAI_MAINNET = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address internal constant ADAI_GOERLI = 0x31f30d9A5627eAfeC4433Ae2886Cf6cc3D25E772;

    address internal constant LENDING_POOL_V2_MAINNET = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address internal constant LENDING_POOL_V2_GOERLI = 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210;

    function run() public {
        uint256 feePst = 0;
        uint256 maturity = block.timestamp + 10 weeks;
        address underlying = DAI_MAINNET;

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
            })
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

        Adapter aAdapter = new AaveAdapter(
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

        NapierPoolFactory poolFactory = new NapierPoolFactory(address(this));
        Tranche tranche = new Tranche(adapters, IERC20Metadata(underlying), maturity, msg.sender, poolFactory);
        address pool = poolFactory.createPool(underlying, address(tranche));

        vm.stopBroadcast();
    }
}
