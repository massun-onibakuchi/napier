// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../tokens/Tranche.sol";
import "../interfaces/ITranche.sol";

import "../adapters/compound/CompoundAdapter.sol";
import {NapierPoolFactory, NapierPool} from "../pool/NapierPoolFactory.sol";

import "../utils/FixedMath.sol";
import "./BaseTest.t.sol";

import "forge-std/Test.sol";

contract TestNapierPool is BaseTest {
    using FixedMath for uint256;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    NapierPool internal pool;
    NapierPoolFactory internal poolFactory;

    /// @dev override this function to set up your own test environment
    /// @dev Deploy tranche and adapter
    function _setup() internal override {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        // 1. setup underlying
        // 2. deploy tranche and adapter

        underlying = DAI;

        Adapter adapter = new CompoundAdapter(
            Adapter.AdapterParams({underlying: DAI, target: cDAI, delta: DELTA, minm: 0, maxm: 0, issuanceFee: feePst})
        );
        adapters.push(adapter);

        poolFactory = new NapierPoolFactory(address(this));
        tranche = new Tranche(adapters, IERC20Metadata(underlying), maturity, address(this), poolFactory);
        pool = NapierPool(poolFactory.createPool(underlying, address(tranche)));

        // approve
        IERC20(underlying).approve(address(pool), type(uint256).max);

        vm.label(address(poolFactory), "factory");
        vm.label(address(pool), "pool");
    }

    function _fund() internal override {
        super._fund();

        vm.label(address(1), "user");
        deal(underlying, address(1), amount, true);
        vm.prank(address(1));
        IERC20(underlying).approve(address(pool), type(uint256).max);
    }

    function testConstructorParams() public override {
        super.testConstructorParams();
        assertEq(address(pool.nPT()), address(tranche), "tranche");
        assertEq(address(pool.underlying()), underlying, "underlying");
        assertEq(pool.maturity(), maturity, "maturity");
    }

    function testAddLiquidity() public {
        address pt = zeros[0];
        // We do not add Principal Token liquidity if a pool haven't been initialized yet
        pool.addLiquidityFromUnderlying(pt, address(this), amount, 0, block.timestamp);
        assertEq(pool.balanceOf(address(this)), _normalize(amount, U_DECIMALS, 18), "liquidity");
        assertEq(tranche.balanceOf(address(pool)), 0, "zero bal should be 0");

        uint256 nptReserve = _normalize(amount, U_DECIMALS, tranche.decimals());
        deal(address(tranche), address(pool), nptReserve, true);
        deal(pt, address(tranche), _normalize(amount, U_DECIMALS, IERC20Metadata(pt).decimals()), true); // add some pt to tranche to compensate for npt reserve

        vm.prank(address(1));
        pool.addLiquidityFromUnderlying(pt, address(1), amount, 0, block.timestamp);
        assertEq(pool.balanceOf(address(this)), pool.totalSupply() / 2, "liquidity");
        assertEq(pool.balanceOf(address(1)), pool.totalSupply() / 2, "liquidity");
    }

    function testMinLiquidity() public {
        address pt = zeros[0];

        vm.expectRevert("pool: min liquidity");
        pool.addLiquidityFromUnderlying(pt, address(this), amount, amount + 1, block.timestamp);
    }

    function testDeadline() public {
        uint256 deadline = block.timestamp;
        address pt = zeros[0];

        vm.warp(deadline + 1);

        vm.expectRevert("pool: expired");
        pool.addLiquidityFromUnderlying(pt, address(this), amount, 0, deadline);

        vm.expectRevert("pool: expired");
        pool.removeLiquidity(pt, address(this), amount, 0, deadline);
    }
}
