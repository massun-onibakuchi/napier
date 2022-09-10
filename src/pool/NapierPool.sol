// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/INapierPool.sol";

contract NapierPool is ERC20, ReentrancyGuard, INapierPool {
    // using FixedPoint for uint256;

    INapierPoolFactory public immutable override factory;

    IERC20 public immutable override underlying;

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
    uint256 public immutable percentFee;

    // The percent of LP fees that is payed to governance
    uint256 public immutable percentFeeGov;

    /// @dev Scale value for the yield-bearing asset's first `join` (i.e. initialization)
    uint256 internal _initScale;

    // TODO: token name and symbol
    // TODO: deploy tranche with CREATE2 from factory, init with callback instead of constructor
    // ref: Element finance and Uniswap V3
    constructor(
        address _underlying,
        ITranche _nPT,
        uint256 _maturity,
        uint256 _percentFee,
        uint256 _percentFeeGov,
        address _governance,
        string memory name,
        string memory symbol
    ) ERC20("Napier Pool Token", "nPT") {
        underlying = IERC20(_underlying);
        nPT = _nPT;
        underlyingDecimals = IERC20Metadata(_underlying).decimals();
        nptDecimals = _nPT.decimals();

        require(_maturity > block.timestamp, "NapierPool: Maturity in the past");
        maturity = _maturity;
        percentFee = _percentFee;
        percentFeeGov = _percentFeeGov;
        governance = _governance;

        factory = INapierPoolFactory(msg.sender);
    }

    function mint(address pt, address recipient) external nonReentrant returns (uint256 liquidity) {
        // _upscaleArray(reserves);
        // _upscaleArray(reqAmountsIn);
        // // @todo
        if (totalSupply() == 0) {
            // ITranche.Series memory _series = nPT.getSeries(pt);
            //     (uint8 _zeroi, uint8 _targeti) = getIndices();
            // uint256 initScale = _series.adapter.scale();
            // Convert target balance into Underlying
            // note: We assume scale values will always be 18 decimals
            // uint256 underlyingIn = (amount * initScale) / 1e18;
            //     // Just like weighted pool 2 token from the balancer v2 monorepo,
            //     // we lock MINIMUM_BPT in by minting it for the zero address – this reduces potential
            //     // issues with rounding and ensures that this code path will only be executed once
            //     _mintPoolTokens(address(0), MINIMUM_BPT);
            //     // Mint the recipient BPT comensurate with the value of their join in Underlying
            //     _mintPoolTokens(recipient, underlyingIn - MINIMUM_BPT);
            //     // Amounts entering the Pool, so we round up
            //     _downscaleUpArray(reqAmountsIn);
            //     // Set the scale value all future deposits will be backdated to
            //     _initScale = initScale;
            //     // For the first join, we don't pull any Zeros, regardless of what the caller requested –
            //     // this starts this pool off as synthetic Underlying only, as the yieldspace invariant expects
            //     delete reqAmountsIn[_zeroi];
            //     // Cache new invariant and reserves, post join
            //     _cacheReserves(reserves);
            //     return (reqAmountsIn, new uint256[](2));
        } else {
            //     (uint256 bptToMint, uint256[] memory amountsIn) = _tokensInForBptOut(reqAmountsIn, reserves);
            //     // Amounts entering the Pool, so we round up
            //     _downscaleUpArray(amountsIn);
            //     // Calculate fees due before updating reserves to determine invariant growth from just swap fees
            //     if (protocolSwapFeePercentage != 0) {
            //         _mintPoolTokens(_protocolFeesCollector, _bptFeeDue(reserves, protocolSwapFeePercentage));
            //     }
            //     // `recipient` receives liquidity tokens
            //     _mintPoolTokens(recipient, bptToMint);
            //     // Update reserves for caching
            //     reserves[0] += amountsIn[0];
            //     reserves[1] += amountsIn[1];
            //     // Cache new invariant and reserves, post join
            //     _cacheReserves(reserves);
            //     // Inspired by PR #990 in balancer-v2-monorepo, we always return zero dueProtocolFeeAmounts
            //     // to the Vault, and pay protocol fees by minting BPT directly to the protocolFeeCollector instead
            //     return (amountsIn, new uint256[](2));
        }
    }

    function burn(address pt, address recipient)
        external
        nonReentrant
        returns (uint256 amountUnderunderlying, uint256 amountNPt)
    {}

    /// @notice Calculate the max amount of BPT that can be minted from the requested amounts in,
    // given the ratio of the reserves, and assuming we don't make any swaps
    function _tokensInForBptOut(uint256[] memory reqAmountsIn, uint256[] memory reserves)
        internal
        returns (uint256, uint256[] memory)
    {
        // Disambiguate reserves wrt token type
        // (uint8 _zeroi, uint8 _targeti) = getIndices();
        // (uint256 zeroReserves, uint256 targetReserves) = (reserves[_zeroi], reserves[_targeti]);

        // uint256[] memory amountsIn = new uint256[](2);

        // // If the pool has been initialized, but there aren't yet any Zeros in it
        // if (zeroReserves == 0) {
        //     uint256 reqTargetIn = reqAmountsIn[_targeti];
        //     // Mint LP shares according to the relative amount of Target being offered
        //     uint256 bptToMint = (totalSupply() * reqTargetIn) / targetReserves;

        //     // Pull the entire offered Target
        //     amountsIn[_targeti] = reqTargetIn;

        //     return (bptToMint, amountsIn);
        // } else {
        //     // Disambiguate requested amounts wrt token type
        //     (uint256 reqZerosIn, uint256 reqTargetIn) = (reqAmountsIn[_zeroi], reqAmountsIn[_targeti]);
        //     // Caclulate the percentage of the pool we'd get if we pulled all of the requested Target in
        //     uint256 pctTarget = reqTargetIn.divDown(targetReserves);

        //     // Caclulate the percentage of the pool we'd get if we pulled all of the requested Zeros in
        //     uint256 pctZeros = reqZerosIn.divDown(zeroReserves);

        //     // Determine which amountIn is our limiting factor
        //     if (pctTarget < pctZeros) {
        //         // If it's Target, pull the entire requested Target amountIn,
        //         // and pull Zeros in at the percetage of the requested Target / Target reserves
        //         uint256 bptToMint = totalSupply().mulDown(pctTarget);

        //         amountsIn[_zeroi] = zeroReserves.mulDown(pctTarget);
        //         amountsIn[_targeti] = reqTargetIn;

        //         return (bptToMint, amountsIn);
        //     } else {
        //         // If it's Zeros, pull the entire requested Zero amountIn,
        //         // and pull Target in at the percetage of the requested Zeros / Zero reserves
        //         uint256 bptToMint = totalSupply().mulDown(pctZeros);

        //         amountsIn[_zeroi] = reqZerosIn;
        //         amountsIn[_targeti] = targetReserves.mulDown(pctZeros);

        //         return (bptToMint, amountsIn);
        //     }
        // }
    }

    // function swap(
    //     uint256 amountUnderlying,
    //     uint256 amountNPt,
    //     address to,
    //     bytes calldata data
    // ) external nonReentrant {}
}
