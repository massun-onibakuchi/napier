// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../tokens/Tranche.sol";
import {BaseAdapter as Adapter} from "../../adapters/BaseAdapter.sol";

import "../../utils/FixedMath.sol";

import "forge-std/Test.sol";

abstract contract TestAdapter is Test {
    using FixedMath for uint256;

    uint256 internal constant FORK_BLOCK = 15540000;

    uint256 internal constant DELTA = 150;
    uint256 internal constant MIN_MATURITY = 2 weeks;
    uint256 internal constant MAX_MATURITY = 14 weeks;

    uint8 internal U_DECIMALS;
    uint8 internal T_DECIMALS;
    uint256 internal U_BASE;
    uint256 internal T_BASE;

    address internal underlying;
    address internal target;

    Tranche internal tranche;
    Adapter internal adapter;
    address[] internal zeros;

    uint256 internal maturity;
    uint256 internal feePst;

    function setUp() public {
        // set up rpc_endpoints in foundry.toml. ref: https://book.getfoundry.sh/cheatcodes/rpc
        // [rpc_endpoints]
        // mainnet = "${RPC_URL}"
        vm.createSelectFork(vm.rpcUrl("mainnet"), FORK_BLOCK);

        _setup();

        assertTrue(underlying != address(0), "setup: underlying is zero address");
        assertTrue(target != address(0), "setup: target is zero address");
        assertTrue(address(adapter) != address(0), "setup: adapter is zero address");
        assertTrue(address(tranche) != address(0), "setup: tranche is zero address");

        zeros = tranche.getZeros();
        U_DECIMALS = IERC20Metadata(underlying).decimals();
        T_DECIMALS = IERC20Metadata(target).decimals();
        U_BASE = 10**U_DECIMALS;
        T_BASE = 10**T_DECIMALS;

        // label
        vm.label(address(underlying), "underlying");
        vm.label(address(target), "target");
        vm.label(address(adapter), "adapter");
        vm.label(address(tranche), "tranche");
        vm.label(address(this), "this");
        vm.label(zeros[0], "zero");
        vm.label(tranche.getSeries(zeros[0]).claim, "claim");

        // funds
        _fund();

        // approve
        IERC20(underlying).approve(address(adapter), type(uint256).max);
        IERC20(target).approve(address(adapter), type(uint256).max);

        IERC20(underlying).approve(address(tranche), type(uint256).max);
        IERC20(target).approve(address(tranche), type(uint256).max);
    }

    /// @dev override this function to set up your own test environment
    /// @dev Deploy tranche and adapter
    function _setup() internal virtual {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        // 1. setup underlying and target
        // 2. deploy tranche and adapter
    }

    function _fund() internal virtual {
        deal(underlying, address(this), 1000 * U_BASE, true);
        deal(target, address(this), 1000 * T_BASE, true);
    }

    function testConstructorParams() public virtual {
        address zero = zeros[0];
        assertEq(address(tranche.underlying()), underlying);
        assertEq(tranche.getZeros().length, 1);
        assertEq(tranche.getSeries(zero).adapter.getTarget(), target);
        assertEq(tranche.maturity(), maturity);
        assertEq(tranche.issuance(), block.timestamp);
        assertEq(address(tranche.poolFactory()), address(this));
    }

    function testWrapUnderlying() public virtual {
        uint256 scale = adapter.scale(); // in WAD
        uint256 uAmount = IERC20(underlying).balanceOf(address(this));
        uint256 tBalBefore = IERC20(target).balanceOf(address(this));

        uint256 tBal = adapter.wrapUnderlying(uAmount);

        assertEq(IERC20(target).balanceOf(address(this)) - tBalBefore, tBal, "target bal");
        assertEq(IERC20(underlying).balanceOf(address(this)), 0, "underlying bal");
        assertEq(IERC20(underlying).balanceOf(address(adapter)), 0, "underlying bal of adapter");
        assertApproxEqRel(
            tBal,
            _normalize((uAmount * 1e18) / scale, U_DECIMALS, T_DECIMALS), // normalize to target decimals
            0.000_000_1e18,
            "inconsistent value"
        );
    }

    function testUnwrapUnderlying() public virtual {}

    function testIssue() public virtual {
        address pt = zeros[0];
        address claim = tranche.getSeries(pt).claim;
        uint256 tAmount = IERC20(target).balanceOf(address(this));

        // tAmount = tAmountSubFee * scale / WAD;
        uint256 scale = adapter.scale();
        uint256 fee = feePst.fmul(tAmount);
        uint256 mintAmount = (tAmount - fee).fmul(scale);

        // issue cToken-PT
        tranche.issue(pt, tAmount);
        assertEq(IERC20(pt).balanceOf(address(this)), mintAmount);
        assertEq(IERC20(claim).balanceOf(address(this)), mintAmount);
        assertEq(tranche.lscales(pt, address(this)), scale);
    }

    function testIssueFromUnderlying() public virtual {
        address pt = zeros[0];
        address claim = tranche.getSeries(pt).claim;
        uint256 uAmount = IERC20(underlying).balanceOf(address(this));

        // tAmount = tAmountSubFee * scale / WAD;
        uint256 scale = adapter.scale();
        uint256 tAmount = _normalize(uAmount, U_DECIMALS, T_DECIMALS).fdiv(scale);
        uint256 fee = feePst.fmul(tAmount);
        uint256 mintAmount = (tAmount - fee).fmul(scale);

        // issue cToken-PT
        tranche.issueFromUnderlying(pt, uAmount);
        // NOTE: mintAmount is in units of target token (same decimals as target token)
        assertApproxEqRel(
            _normalize(uAmount, U_DECIMALS, T_DECIMALS),
            mintAmount,
            0.000_000_1e18, // An 18 decimal fixed point number, where 1e18 == 100%
            "uAmount !~= mintAmount"
        );
        assertApproxEqRel(
            IERC20(pt).balanceOf(address(this)),
            mintAmount,
            0.000_000_1e18, // An 18 decimal fixed point number, where 1e18 == 100%
            "zero amount"
        );
        assertApproxEqRel(
            IERC20(claim).balanceOf(address(this)),
            mintAmount,
            0.000_000_1e18, // An 18 decimal fixed point number, where 1e18 == 100%
            "claim amount"
        );
        assertEq(tranche.lscales(pt, address(this)), scale);
    }

    function testCantTransferNapierPT() external {
        vm.expectRevert("nPT: transfer disabled");
        tranche.transfer(address(1), 1);

        vm.expectRevert("nPT: transferFrom disabled");
        tranche.transferFrom(address(1), address(2), 1);
    }

    /// @dev Takes an 'amount' encoded with 'decimalsBefore' decimals and
    ///      re encodes it with 'decimalsAfter' decimals
    /// @param amount The amount to normalize
    /// @param decimalsBefore The decimal encoding before
    /// @param decimalsAfter The decimal encoding after
    function _normalize(
        uint256 amount,
        uint8 decimalsBefore,
        uint8 decimalsAfter
    ) internal pure returns (uint256) {
        // If we need to increase the decimals
        if (decimalsBefore > decimalsAfter) {
            // Then we shift right the amount by the number of decimals
            amount = amount / 10**(decimalsBefore - decimalsAfter);
            // If we need to decrease the number
        } else if (decimalsBefore < decimalsAfter) {
            // then we shift left by the difference
            amount = amount * 10**(decimalsAfter - decimalsBefore);
        }
        // If nothing changed this is a no-op
        return amount;
    }
}
