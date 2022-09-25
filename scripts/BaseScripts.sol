// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {BaseAdapter as Adapter} from "../src/adapters/BaseAdapter.sol";
import "../src/tokens/Tranche.sol";
import {NapierPoolFactory, NapierPool} from "../src/pool/NapierPoolFactory.sol";

import "forge-std/Script.sol";

abstract contract BaseScripts is Script {
    uint256 internal constant DELTA = 150;

    /********* Mainnet *********/
    address internal constant DAI_MAINNET = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // compound
    address internal constant CDAI_MAINNET = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address internal constant CETH_MAINNET = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    // yearn
    address internal constant YDAI_MAINNET = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;

    // aave v2
    address internal constant ADAI_MAINNET = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address internal constant LENDING_POOL_V2_MAINNET = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    /********* Goerli *********/

    // address internal constant DAI_GOERLI = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844;
    address internal constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    // compound
    address internal constant CDAI_UNDERLYING_GOERLI = 0x2899a03ffDab5C90BADc5920b4f53B0884EB13cC;
    address internal constant CDAI_GOERLI = 0x0545a8eaF7ff6bB6F708CbB544EA55DBc2ad7b2a;
    address internal constant CETH_GOERLI = 0x64078a6189Bf45f80091c6Ff2fCEe1B15Ac8dbde;
    // aave v2
    address internal constant ADAI_UNDERLYING_GOERLI = 0x75Ab5AB1Eef154C0352Fc31D2428Cef80C7F8B33;
    address internal constant ADAI_GOERLI = 0x31f30d9A5627eAfeC4433Ae2886Cf6cc3D25E772;
    address internal constant LENDING_POOL_V2_GOERLI = 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210;

    /********* Mumbai *********/
    // address internal constant WMATIC_MUMBAI = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

    // aave v2
    address internal constant AWMATIC_V2_UNDERLYING_MUMBAI = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address internal constant AWMATIC_V2_MUMBAI = 0xF45444171435d0aCB08a8af493837eF18e86EE27;
    address internal constant LENDING_POOL_V2_MUMBAI = 0x9198F13B08E299d85E096929fA9781A1E3d5d827;

    // aave v3
    address internal constant AWMATIC_V3_UNDERLYING_MUMBAI = 0xb685400156cF3CBE8725958DeAA61436727A30c3;
    address internal constant AWMATIC_V3_MUMBAI = 0x89a6AE840b3F8f489418933A220315eeA36d11fF;
    address internal constant PROVIDER_V3_MUMBAI = 0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6;

    uint256 feePst;
    uint256 maturity;
    address underlying;

    // Foundry supports various wallet options.
    // https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw

    function _deployTrancheAndCreatePool(Adapter[] memory adapters) internal virtual {
        NapierPoolFactory poolFactory = new NapierPoolFactory(address(this));
        Tranche tranche = new Tranche(adapters, IERC20Metadata(underlying), maturity, msg.sender, poolFactory);
        address pool = poolFactory.createPool(underlying, address(tranche));
    }
}
