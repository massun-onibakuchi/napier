// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/INapierPool.sol";
import {IToken as IClaim} from "../interfaces/IToken.sol";

import "../utils/FixedPoint.sol";
import "../utils/FixedMath.sol";

contract NapierPool is ERC20, ReentrancyGuard, INapierPool {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20Metadata;

    INapierPoolFactory public immutable override factory;

    IERC20Metadata public immutable override underlying;

    uint8 public immutable underlyingDecimals;

    ITranche public immutable override nPT;

    uint8 public immutable nptDecimals;

    // The expiration time
    uint256 public immutable maturity;

    // The fees which have been allocated to pay governance, a percent of LP fees on trades
    // Since we don't have access to transfer they must be stored so governance can collect them later
    uint128 public governanceFeesUnderlying;

    uint128 public governanceFeesNpt;

    // Stored records of governance tokens
    address public immutable governance;

    // The percent of each trade's implied yield to collect as LP fee
    uint256 public percentFee;

    // The percent of LP fees that is payed to governance
    uint256 public percentFeeGov;

    uint256 internal _uReserve;

    uint256 internal _nptReserve;

    constructor() ERC20("Napier Pool", "nLP") {
        factory = INapierPoolFactory(msg.sender);

        (uint256 _maturity, address _underlying, address _npt, address _governance) = factory.getData();

        maturity = _maturity;
        underlying = IERC20Metadata(_underlying);
        nPT = ITranche(_npt);
        underlyingDecimals = IERC20Metadata(_underlying).decimals();
        nptDecimals = ITranche(_npt).decimals();
        governance = _governance;

        underlying.safeApprove(_npt, type(uint256).max);
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked("Napier Pool", underlying.symbol(), "/", nPT.symbol()));
    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked("nLP-", underlying.symbol(), "/", nPT.symbol()));
    }

    function getReserves() public view returns (uint256, uint256) {
        return (_uReserve, _nptReserve);
    }

    function addLiquidityFromUnderlying(
        address pt,
        address recipient,
        uint256 amountIn,
        uint256 minLiquidity,
        uint256 deadline
    ) external notMatured returns (uint256 liquidity) {
        require(deadline >= block.timestamp, "pool: expired");

        IERC20Metadata(underlying).safeTransferFrom(msg.sender, address(this), amountIn);
        liquidity = _mintFromUnderlying(pt, amountIn, recipient);

        require(liquidity >= minLiquidity, "pool: min liquidity");
    }

    function removeLiquidity(
        address pt,
        address recipient,
        uint256 minUnderlyingOut,
        uint256 minPtOut,
        uint256 deadline
    ) external returns (uint256 liquidity) {
        require(deadline >= block.timestamp, "pool: expired");
        // TODO
    }

    /// @param pt The Principal Token of a lending protocol
    /// @param amountIn The amount of underlying to deposit
    /// @param recipient The address to receive the minted liquidity token
    function _mintFromUnderlying(
        address pt,
        uint256 amountIn,
        address recipient
    ) internal nonReentrant returns (uint256 liquidity) {
        (uint256 uReserve, uint256 nptReserve) = getReserves();

        // mint pt and nPT
        (uint256 uAmountUsed, uint256 mintAmount, uint256 nptAmountIn) = nPT.mintNapierPT(
            pt,
            amountIn,
            uReserve,
            nptReserve
        );

        uint256 uAmountIn = amountIn - uAmountUsed;
        // add reserve
        _nptReserve += nptAmountIn;
        _uReserve += uAmountIn;

        // mint Lp token
        (liquidity, , ) = _mintLP(uAmountIn, nptAmountIn, uReserve, nptReserve, recipient);

        IClaim(nPT.getSeries(pt).claim).transfer(recipient, mintAmount);
    }

    /// @dev Mints the maximum possible LP given a set of max inputs
    /// @param uAmountIn The max underlying to deposit
    /// @param nptAmountIn The max npt to deposit
    /// @param uReserve The underlying reserve
    /// @param nptReserve The nPT reserve
    /// @param recipient The person who receives the lp funds
    /// @return liquidity The amount of LP tokens minted
    /// @return underlyingIn amountsIn The actual amounts of token deposited
    /// @return nptIn  amountsIn The actual amounts of token deposited
    function _mintLP(
        uint256 uAmountIn,
        uint256 nptAmountIn,
        uint256 uReserve,
        uint256 nptReserve,
        address recipient
    )
        internal
        returns (
            uint256 liquidity,
            uint256 underlyingIn,
            uint256 nptIn
        )
    {
        uint256 _totalSupply = totalSupply();

        // If the pool has been initialized, but there aren't yet any Zeros in it
        if (_totalSupply == 0) {
            // When uninitialized we mint exactly the underlying input
            // in LP tokens
            // mint virtual PT and liquidity tokens
            _mint(recipient, uAmountIn);
            // return actual input amounts
            return (uAmountIn, uAmountIn, 0);
        }
        // Get the reserve ratio, the say how many underlying per npt in the reserve
        // (input underlying / reserve underlying) is the percent increase caused by deposit
        uint256 underlyingPerNpt = uReserve.divDown(nptReserve);
        // Use the underlying per npt to get the needed number of input underlying
        uint256 neededUnderlying = underlyingPerNpt.mulDown(nptAmountIn);

        // If the user can't provide enough underlying
        if (neededUnderlying > uAmountIn) {
            // The increase in total supply is the input underlying
            // as a ratio to reserve
            liquidity = (uAmountIn.mulDown(_totalSupply)).divDown(uReserve);
            // We mint a new amount of as the the percent increase given
            // by the ratio of the input underlying to the reserve underlying
            _mint(recipient, liquidity);
            // In this case we use the whole input of underlying
            // and consume (uAmountIn / underlyingPerNpt) npts
            underlyingIn = uAmountIn;
            nptIn = uAmountIn.divDown(underlyingPerNpt);
        } else {
            // We calculate the percent increase in the reserves from contributing
            // all of the npt
            liquidity = (neededUnderlying.mulDown(_totalSupply)).divDown(uReserve);
            // We then mint an amount of pool token which corresponds to that increase
            _mint(recipient, liquidity);
            // The indicate we consumed the input npt and (nptAmountIn * underlyingPerNpt)
            underlyingIn = neededUnderlying;
            nptIn = nptAmountIn;
        }
    }

    function getAmountIn(
        address pt,
        address recipient,
        uint256 amountIn
    ) external view returns (uint256, uint256) {
        (uint256 uReserve, uint256 nptReserve) = getReserves();
        uint256 scale = nPT.scaleStored();
        (uint256 amountUsed, uint256 nptAmount) = nPT.computeNptToMint(pt, amountIn, uReserve, nptReserve, scale);
        return (amountIn - amountUsed, nptAmount);
    }

    modifier notMatured() {
        require(block.timestamp < maturity, "Tranche: before maturity");
        _;
    }

    modifier matured() {
        require(block.timestamp >= maturity, "Tranche: after maturity");
        _;
    }
}
