// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../tokens/Tranche.sol";
import "../../../interfaces/IWETH.sol";
import "../../../adapters/aave/AaveV3Adapter.sol";
import "../../../interfaces/aave-v3/IPoolAddressesProvider.sol";
import "../../../interfaces/aave-v3/IPool.sol";

import "../../../utils/FixedMath.sol";

import "../TestAdapter.t.sol";

contract TestAaveV3AdapterAWMatic is TestAdapter {
    address internal constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address internal constant aWMATIC = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;
    address internal constant PROVIDER_POLYGON_MAINNET = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

    IPoolAddressesProvider internal _provider;
    IPool internal _pool;

    function _createFork() internal override {
        // set up rpc_endpoints in foundry.toml. ref: https://book.getfoundry.sh/cheatcodes/rpc
        uint256 BLOCK = 33000000;
        vm.createSelectFork(vm.rpcUrl("polygon"), BLOCK);
    }

    function _setup() internal override {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        underlying = WMATIC;
        target = aWMATIC;

        _provider = IPoolAddressesProvider(PROVIDER_POLYGON_MAINNET);
        _pool = IPool(_provider.getPool());

        vm.label(PROVIDER_POLYGON_MAINNET, "provider");
        vm.label(_provider.getPool(), "pool");

        adapter = new AaveV3Adapter(
            Adapter.AdapterParams({
                underlying: WMATIC,
                target: aWMATIC,
                delta: DELTA,
                minm: 0,
                maxm: 0,
                issuanceFee: feePst
            }),
            PROVIDER_POLYGON_MAINNET
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

        _fund();
    }

    function _fund() internal virtual override {
        U_DECIMALS = IERC20Metadata(underlying).decimals();
        T_DECIMALS = IERC20Metadata(target).decimals();
        U_BASE = 10**U_DECIMALS;
        T_BASE = 10**T_DECIMALS;

        vm.deal(address(this), 2000 * U_BASE);
        IWETH(underlying).deposit{value: 2000 * U_BASE}();
        IERC20(underlying).approve(address(_pool), type(uint256).max);
        _pool.supply(underlying, 1000 * U_BASE, address(this), 0);
    }
}
