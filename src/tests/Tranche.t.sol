// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../tokens/Tranche.sol";
import "../interfaces/ITranche.sol";

import "../adapters/compound/CompoundAdapter.sol";

import "../utils/FixedMath.sol";
import "./BaseTest.t.sol";

import "forge-std/Test.sol";

contract NapierPoolFactoryMock is INapierPoolFactory {
    function isRegisteredPool(address) external pure returns (bool) {
        return true;
    }

    function getData()
        external
        view
        returns (
            uint256,
            address,
            address,
            address
        )
    {}

    function createPool(address underlying, address nPT) external returns (address) {}

    function getPools() external view returns (address[] memory) {}
}

contract TestTranche is BaseTest {
    using FixedMath for uint256;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant CDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    /// @dev override this function to set up your own test environment
    /// @dev Deploy tranche and adapter
    function _setup() internal override {
        feePst = 0;
        maturity = block.timestamp + 10 weeks;
        // 1. setup underlying
        // 2. deploy tranche and adapter

        underlying = DAI;

        Adapter adapter = new CompoundAdapter(
            Adapter.AdapterParams({underlying: DAI, target: CDAI, delta: DELTA, minm: 0, maxm: 0, issuanceFee: feePst}),
            WETH,
            CETH
        );
        adapters.push(adapter);

        INapierPoolFactory poolFactoryMock = new NapierPoolFactoryMock();
        tranche = new Tranche(adapters, IERC20Metadata(underlying), maturity, address(this), poolFactoryMock);
    }

    function testMintNapierPTWhenNotInitialized() public {
        // We do not add Principal Token liquidity if a pool haven't been initialized yet
        (uint256 uAmountUse, uint256 ptAmount, uint256 nptAmount) = tranche.mintNapierPT(zeros[0], amount, 0, 0);

        assertEq(uAmountUse, 0, "uAmountUse should be 0");
        assertEq(ptAmount, 0, "ptAmount should be 0");
        assertEq(nptAmount, 0, "nptAmount should be 0");
        assertEq(IZero(zeros[0]).balanceOf(address(tranche)), 0, "zero bal should be 0");
        assertEq(IERC20(underlying).balanceOf(address(this)), amount, "uBal should stay same");
    }

    function testMintNapierPTWhenInitialized() public {
        // We add nPT liquidity if a pool has initialized yet
        uint256 uReserve = 10 * amount;
        uint256 nptReserve = _normalize(amount * 100, U_DECIMALS, tranche.decimals());
        deal(
            zeros[0],
            address(tranche),
            _normalize(amount * 100, U_DECIMALS, IERC20Metadata(zeros[0]).decimals()),
            true
        ); // add some pt to tranche to compensate for npt reserve

        uint256 nptScale = tranche.scale();
        // TODO: scale test

        // _uAmount * _nptReserve / (nptScale * _uReserve * (1 - feePst) + _nptReserve)
        uint256 expectedNptBal = (amount * nptReserve) /
            ((((nptScale * uReserve) / WAD) * (WAD - feePst)) / WAD + nptReserve);
        // mint nPT
        uint256 ptBalBefore = IZero(zeros[0]).balanceOf(address(tranche));
        (uint256 uAmountUse, uint256 ptAmount, uint256 nptAmount) = tranche.mintNapierPT(
            zeros[0],
            amount,
            uReserve,
            nptReserve
        );

        uint256 ptBalDiff = IZero(zeros[0]).balanceOf(address(tranche)) - ptBalBefore;
        assertEq(ptBalDiff, ptAmount, "ptBalDiff should be eq to ptAmount");
        assertEq(IERC20(underlying).balanceOf(address(this)), amount - uAmountUse, "underlying bal");
        assertApproxEqRel(tranche.balanceOf(address(this)), expectedNptBal, 0.000_1e18, "expectedNptBal");
        assertApproxEqRel(nptAmount, expectedNptBal, 0.000_1e18, "expectedNptBal");
        assertApproxEqRel(
            uAmountUse,
            _normalize(ptBalDiff, adapters[0].tDecimals(), U_DECIMALS),
            0.000_1e18,
            "inconsistent value"
        );
    }

    function testBurnNapierPT() public {}

    function testCantTransferNapierPT() public {
        vm.expectRevert("nPT: transfer disabled");
        tranche.transfer(address(1), 1);

        vm.expectRevert("nPT: transferFrom disabled");
        tranche.transferFrom(address(1), address(2), 1);
    }

    function testRevertIfMatured() public {
        vm.warp(maturity + 1);
        vm.expectRevert("Tranche: before maturity");
        tranche.issue(zeros[0], 1);
        // TODO: test other functions
    }

    function testRevertIfNotMatured() public {
        vm.warp(maturity - 1);
        vm.expectRevert("Tranche: after maturity");
        tranche.redeemZero(zeros[0], 1);
        // TODO: test other functions
    }
}
