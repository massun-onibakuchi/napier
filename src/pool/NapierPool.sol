// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/INapierPool.sol";

import "../utils/FixedPoint.sol";
import "../utils/FixedMath.sol";

contract NapierPool is ERC20, ReentrancyGuard, INapierPool {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;

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

    uint256 internal _uReserve;

    uint256 internal _nptReserve;

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
    ) ERC20("Napier Pool LP Token", "Napier LPT") {
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

    function mint(address pt, address recipient) external nonReentrant notMatured returns (uint256 liquidity) {
        //     (uint256 uReserve_, uint256 nptReserve_) = getReserves();
        //     uint256 uBal = underlying.balanceOf(address(this));
        //     uint256 nptBal = nPT.balanceOf(address(this));
        //     uint256 amountUnderlying = uBal - uReserve_;
        //     uint256 nptAmount = nptBal - nptReserve_;
        //     // nPT.issue(pt, uAmountUsed);
        //     // nPT.mintNapierPT(address(this), nptAmountIn);
        //     // (liquidity, , ) = _mintLP(uAmount - uAmountUsed, nptAmountIn, uReserve, nptReserve, recipient);
    }

    function getReserves() public view returns (uint256, uint256) {
        return (_uReserve, _nptReserve);
    }

    function mintFromUnderlying(
        address pt,
        uint256 uAmount,
        address recipient
    ) external nonReentrant notMatured returns (uint256 liquidity) {
        // (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        // uint256 balance0 = underlying.balanceOf(address(this));
        // uint256 balance1 = IERC20(token1).balanceOf(address(this));
        // uint256 amount0 = balance0.sub(_reserve0);
        // uint256 amount1 = balance1.sub(_reserve1);

        // uReserve := Z
        // nptReserve := Y
        uint256 uReserve = underlying.balanceOf(address(this));
        uint256 nptReserve = nPT.balanceOf(address(this));

        underlying.safeTransferFrom(msg.sender, address(this), uAmount);

        // uAmoount := z = z' + z''
        // uAmoountIn := z'
        // uAmountUsed := z''

        // mint pt and nPT
        underlying.safeApprove(address(nPT), uAmount);
        (uint256 uAmountUsed, , uint256 nptAmountIn) = nPT.mint(address(this), uAmount, uReserve, nptReserve);

        uint256 uAmountIn = uAmount - uAmountUsed;
        _nptReserve += nptAmountIn;
        _uReserve += uAmountIn;

        (liquidity, , ) = _mintLP(uAmountIn, nptAmountIn, uReserve, nptReserve, recipient);
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

    function burn(address pt, address recipient)
        external
        nonReentrant
        returns (uint256 amountUnderunderlying, uint256 amountNPt)
    {}

    // function swap(
    //     uint256 amountUnderlying,
    //     uint256 amountNPt,
    //     address to,
    //     bytes calldata data
    // ) external nonReentrant {}

    modifier notMatured() {
        require(block.timestamp < maturity, "Tranche: before maturity");
        _;
    }

    modifier matured() {
        require(block.timestamp >= maturity, "Tranche: after maturity");
        _;
    }
}
