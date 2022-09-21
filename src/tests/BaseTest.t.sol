// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../tokens/Tranche.sol";
import "../interfaces/ITranche.sol";
import {BaseAdapter as Adapter} from "../adapters/BaseAdapter.sol";

import "../utils/FixedMath.sol";

import "forge-std/Test.sol";

abstract contract BaseTest is Test {
    using FixedMath for uint256;

    uint256 internal constant FORK_BLOCK = 15540000;

    uint256 internal constant DELTA = 150;
    uint256 internal constant MIN_MATURITY = 2 weeks;
    uint256 internal constant MAX_MATURITY = 14 weeks;
    uint256 internal constant WAD = 1e18;

    uint8 internal U_DECIMALS;
    uint256 internal U_BASE;

    address internal underlying;

    Tranche internal tranche;
    address[] internal zeros;
    ITranche.Series[] internal series;
    Adapter[] internal adapters;

    uint256 internal maturity;
    uint256 internal feePst;

    uint256 internal amount;

    function setUp() public {
        // set up rpc_endpoints in foundry.toml. ref: https://book.getfoundry.sh/cheatcodes/rpc
        // [rpc_endpoints]
        // mainnet = "${RPC_URL}"
        vm.createSelectFork(vm.rpcUrl("mainnet"), FORK_BLOCK);

        _setup();

        assertTrue(underlying != address(0), "setup: underlying is zero address");
        assertTrue(address(tranche) != address(0), "setup: tranche is zero address");

        zeros = tranche.getZeros();
        U_DECIMALS = IERC20Metadata(underlying).decimals();
        U_BASE = 10**U_DECIMALS;

        for (uint256 i = 0; i < zeros.length; i++) {
            ITranche.Series memory _series = tranche.getSeries(zeros[i]);
            series.push(_series);
            IERC20Metadata target = IERC20Metadata(_series.adapter.getTarget());
            // label
            vm.label(zeros[i], string(abi.encodePacked("zero", target.symbol())));
            vm.label(address(target), target.symbol());
            // approve
            target.approve(address(tranche), type(uint256).max);
            // fund
            deal(address(target), address(this), 1000 * target.decimals(), true);
        }
        assertTrue(series.length == zeros.length, "setup: zeros and series length mismatch");

        // label
        vm.label(address(underlying), "underlying");
        vm.label(address(tranche), "tranche");
        vm.label(address(this), "this");
        // funds
        amount = 1000 * U_BASE;
        _fund();
        // approve
        IERC20(underlying).approve(address(tranche), type(uint256).max);

        _setupAfter();
    }

    /// @dev override this function to set up your own test environment
    /// @dev Deploy tranche and adapter
    function _setup() internal virtual {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        // 1. setup underlying and target
        // 2. deploy tranche and adapter
    }

    function _setupAfter() internal virtual {}

    function _fund() internal virtual {
        deal(underlying, address(this), amount, true);
    }

    function testConstructorParams() public virtual {
        assertEq(address(tranche.underlying()), underlying);
        assertEq(tranche.maturity(), maturity);
        assertEq(tranche.issuance(), block.timestamp);
    }

    /// @dev Takes an 'amount' encoded with 'decimalsBefore' decimals and
    ///      re encodes it with 'decimalsAfter' decimals
    /// @param _amount The amount to normalize
    /// @param _decimalsBefore The decimal encoding before
    /// @param _decimalsAfter The decimal encoding after
    function _normalize(
        uint256 _amount,
        uint8 _decimalsBefore,
        uint8 _decimalsAfter
    ) internal pure returns (uint256) {
        // If we need to increase the decimals
        if (_decimalsBefore > _decimalsAfter) {
            // Then we shift right the amount by the number of decimals
            _amount = _amount / 10**(_decimalsBefore - _decimalsAfter);
            // If we need to decrease the number
        } else if (_decimalsBefore < _decimalsAfter) {
            // then we shift left by the difference
            _amount = _amount * 10**(_decimalsAfter - _decimalsBefore);
        }
        // If nothing changed this is a no-op
        return _amount;
    }
}
