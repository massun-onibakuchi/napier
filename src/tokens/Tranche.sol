// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../utils/FixedMath.sol";
import "../utils/DateTime.sol";

import "../interfaces/ITranche.sol";
import "../interfaces/INapierPoolFactory.sol";

import {BaseAdapter as Adapter} from "../adapters/BaseAdapter.sol";
import "./Token.sol";

import "forge-std/console.sol";

// For convenience
/// @title Principal Token for each lending protocol
/// @dev `Zero` means zero-coupon bond
interface IZero is IToken {} // prettier-ignore

/// @title Yield Token for each lending protocol
/// @dev `Claim` means Yield Token
interface IClaim is IToken {} // prettier-ignore

/// @notice You can use this contract to issue, combine, and redeem Sense ERC20 Zeros and Claims
/// @title Napier Principal Token interface
/// @dev This contract is responsible for issuing/redeeming each principal token.
///      Napier Principal Token is called as nPT.
///      nPT is like a indexed token, which is composed of some Prinicipal Tokens such as PT of aDAI and PT of cDAI.
///      nPT is virtual token which is only minted/burned by a Napier pool when liquidity providers add/remove their liquidity.
///      this would let LPers aggregate liquiditites and make a more profit.
contract Tranche is ERC20, ReentrancyGuard, ITranche {
    using FixedMath for uint256;
    using SafeERC20 for IERC20Metadata;

    string private constant ZERO_SYMBOL_PREFIX = "pT";
    string private constant ZERO_NAME_PREFIX = "PrincipalToken";
    string private constant CLAIM_SYMBOL_PREFIX = "yT";
    string private constant CLAIM_NAME_PREFIX = "YieldToken";

    uint256 private constant ISSUANCE_FEE_CAP = 0.1e18; // 10% issuance fee cap

    // timestamp of series end
    uint256 public immutable override maturity;

    // timestamp of series initialization
    uint256 public immutable override issuance;

    IERC20Metadata public immutable override underlying;

    address public immutable sponsor;

    INapierPoolFactory public immutable poolFactory;

    address[] internal _zeros;

    /// @notice pt -> Series
    mapping(address => Series) internal series;

    /// @notice pt -> user -> lscale (last scale)
    mapping(address => mapping(address => uint256)) public lscales;

    // TODO: deploy tranche with CREATE2 from factory, init with callback instead of constructor
    // TODO: This contract is deployed by the TrancheFactory. ref: Element finance and Uniswap V3
    /// @param _adapters The adapters for each lending protocol
    /// @param _underlying The underlying asset e.g. DAI
    /// @param _maturity The maturity of the series.
    /// @param _sponsor  The sponsor of the series.
    /// @param _poolFactory The factory of the pool. The poolFactory is used to get registered pools.
    constructor(
        Adapter[] memory _adapters,
        IERC20Metadata _underlying,
        uint256 _maturity,
        address _sponsor,
        INapierPoolFactory _poolFactory
    ) ERC20("Napier Principal Token", "nPT") {
        require(block.timestamp < _maturity, "Tranche: maturity in the past");

        issuance = block.timestamp;
        maturity = _maturity;
        sponsor = _sponsor;
        underlying = _underlying;
        poolFactory = _poolFactory;

        (, string memory m, string memory y) = DateTime.toDateString(_maturity);
        string memory datestring = string(abi.encodePacked(" ", m, "-", y));

        uint256 len = _adapters.length;
        for (uint256 i = 0; i < len; ) {
            require(address(_underlying) == _adapters[i].underlying(), "Tranche: underlying mismatch");

            address zero;
            address claim;
            {
                IERC20Metadata target = IERC20Metadata(_adapters[i].getTarget());
                string memory _name = target.name();
                string memory _symbol = target.symbol();
                uint8 tDecimals = target.decimals();

                zero = address(
                    new Token(
                        string(abi.encodePacked(_name, datestring, " ", ZERO_NAME_PREFIX)),
                        string(abi.encodePacked(ZERO_SYMBOL_PREFIX, _symbol, datestring)),
                        tDecimals,
                        address(this)
                    )
                );
                claim = address(
                    new Token(
                        string(abi.encodePacked(_name, datestring, " ", CLAIM_NAME_PREFIX)),
                        string(abi.encodePacked(CLAIM_SYMBOL_PREFIX, _symbol, datestring)),
                        tDecimals,
                        address(this)
                    )
                );
            }
            uint256 iscale = _adapters[i].scale();

            _zeros.push(zero);
            series[zero] = Series({
                claim: claim,
                adapter: _adapters[i],
                reward: 0,
                iscale: iscale,
                mscale: 0,
                maxscale: iscale,
                tilt: _adapters[i].tilt()
            });
            unchecked {
                i++;
            }
        }
    }

    function name() public view override(ERC20, IERC20Metadata) returns (string memory) {
        (, string memory m, string memory y) = DateTime.toDateString(maturity);
        string memory datestring = string(abi.encodePacked(" ", m, "-", y));
        return string(abi.encodePacked("Napier Principal Token ", underlying.name(), datestring));
    }

    function symbol() public view override(ERC20, IERC20Metadata) returns (string memory) {
        (, string memory m, string memory y) = DateTime.toDateString(maturity);
        string memory datestring = string(abi.encodePacked(" ", m, "-", y));
        return string(abi.encodePacked("NapierPT ", underlying.symbol(), datestring));
    }

    /// @dev only registered pools can mint
    /// @param pt The principal token address
    /// @param uAmount deposit amount of underlying
    /// @param uReserve underlying reserve
    /// @param nptReserve NapierPT reserve
    function mintNapierPT(
        address pt,
        uint256 uAmount,
        uint256 uReserve,
        uint256 nptReserve
    )
        external
        onlyPool
        notMatured
        nonReentrant
        returns (
            uint256 uAmountUse,
            uint256 ptAmount,
            uint256 nptAmount
        )
    {
        (uAmountUse, nptAmount) = _computeNptToMint(pt, uAmount, uReserve, nptReserve);
        if (uAmountUse != 0) {
            // mint pt
            underlying.safeTransferFrom(msg.sender, address(this), uAmountUse);
            ptAmount = _issueFromUnderlying(pt, address(this), uAmountUse);
            // mint nPT
            _mint(msg.sender, nptAmount);
        }
    }

    /// @param _pt address
    /// @param _uAmount underlying amount
    /// @param _uReserve underlying reserve
    /// @param _nptReserve NapierPricipalToken reserve
    /// @return uAmountUse underlying amount used
    /// @return nptAmount npt amount to be minted
    function _computeNptToMint(
        address _pt,
        uint256 _uAmount,
        uint256 _uReserve,
        uint256 _nptReserve
    ) internal returns (uint256 uAmountUse, uint256 nptAmount) {
        // We do not add Principal Token liquidity if it haven't been initialized yet
        if (_nptReserve != 0) {
            // _uAmount * _nptReserve / (nptScale * _uReserve * (1 - feePst) + _nptReserve)
            uint256 feePst = series[_pt].adapter.getIssuanceFee();
            uint256 nptScale = _nptScale(); // in WAD
            uAmountUse = _uAmount.fmul(
                _nptReserve.fdiv(nptScale.fmul(_uReserve).fmul(FixedMath.WAD - feePst) + _nptReserve)
            );
            nptAmount = uAmountUse.fmul(nptScale);
        }
    }

    /// @notice calculate the scale of napier PT. the sum of ptBal * ptScale for each pts.
    /// @return scale in WAD
    function _nptScale() internal returns (uint256) {
        // TODO: gas optimization
        uint256 len = _zeros.length;
        uint256 weightedScaleSum;
        uint256 totalPtBal;
        for (uint256 i = 0; i < len; ) {
            IZero zero = IZero(_zeros[i]);
            // zero bal is in terget token term
            // normalized to 18 decimals
            uint256 ptBal = _normalize(zero.balanceOf(address(this)), zero.decimals()); // in WAD

            console.log("ptBal :>>", ptBal);
            weightedScaleSum += ptBal.fmul(series[address(zero)].adapter.scale()); // in WAD
            totalPtBal += ptBal;
            console.log("weightedScaleSum :>>", weightedScaleSum);
            console.log("totalPtBal :>>", totalPtBal);
            unchecked {
                i++;
            }
        }
        console.log("weightedScaleSum.fdiv(totalPtBal) :>>", weightedScaleSum.fdiv(totalPtBal));
        return (totalPtBal != 0) ? weightedScaleSum.fdiv(totalPtBal) : FixedMath.WAD;
    }

    /// @dev only registered pools can burn
    /// @param account The address from where to burn tokens from
    /// @param amount The amount to be burned
    function burnNapierPT(address account, uint256 amount) external onlyPool notMatured {
        _burn(account, amount);
    }

    function transfer(address, uint256) public pure override(IERC20, ERC20) returns (bool) {
        revert("nPT: transfer disabled");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override(IERC20, ERC20) returns (bool) {
        revert("nPT: transferFrom disabled");
    }

    function scale() external returns (uint256) {
        return _nptScale();
    }

    /// @notice Mint Zeros and Claims of a specific protocol
    /// @dev The balance of Zeros/Claims minted will be the same value in units of target (less fees)
    /// @param pt principal token address
    /// @param uAmount amount of underlying to deposit
    /// @return mintAmount amount of PT and YT minted
    function issueFromUnderlying(address pt, uint256 uAmount)
        external
        nonReentrant
        notMatured
        returns (uint256 mintAmount)
    {
        underlying.safeTransferFrom(msg.sender, address(this), uAmount);
        mintAmount = _issueFromUnderlying(pt, msg.sender, uAmount);
    }

    function _issueFromUnderlying(
        address _pt,
        address _recipient,
        uint256 _uAmount
    ) internal returns (uint256 mintAmount) {
        Series memory _series = series[_pt];

        underlying.safeApprove(address(_series.adapter), _uAmount);

        uint256 tAmount = _series.adapter.wrapUnderlying(_uAmount);
        mintAmount = _issue(_pt, _series, _recipient, tAmount);
    }

    /// @notice Mint Zeros and Claims of a specific protocol
    /// @param pt principal token address
    /// @param tAmount amount of Target to deposit
    /// @return mintAmount amount of PT and YT minted
    /// @dev The balance of Zeros/Claims minted will be the same value in units of target (less fees)
    function issue(address pt, uint256 tAmount) external nonReentrant notMatured returns (uint256 mintAmount) {
        Series memory _series = series[pt];
        IERC20Metadata(_series.adapter.getTarget()).safeTransferFrom(msg.sender, address(this), tAmount);
        mintAmount = _issue(pt, _series, msg.sender, tAmount);
    }

    function _issue(
        address _pt,
        Series memory _series,
        address _recipient,
        uint256 _tAmount
    ) internal returns (uint256 mintAmount) {
        require(_series.claim != address(0), "Tranche: invalid pt");

        // Take the issuance fee out of the deposited Target, and put it towards the settlement reward
        uint256 feePst = _series.adapter.getIssuanceFee(); // in WAD term
        require(feePst <= ISSUANCE_FEE_CAP, "Tranche: issuance fee too high");

        uint256 fee = _tAmount.fmul(feePst);

        // update accrued fees
        series[_pt].reward += fee;
        uint256 tAmountSubFee = _tAmount - fee;

        // If the caller has collected on Claims before, use the scale value from that collection to determine how many Zeros/Claims to mint
        // so that the Claims they mint here will have the same amount of yield stored up as their existing holdings
        uint256 _scale = lscales[_pt][_recipient];

        // If the caller has not collected on Claims before, use the current scale value to determine how many Zeros/Claims to mint
        // so that the Claims they mint here are "clean," in that they have no yet-to-be-collected yield
        if (_scale == 0) {
            _scale = _series.adapter.scale(); // NOTE: in WAD term
            lscales[_pt][_recipient] = _scale;
        }

        // Determine the amount of Underlying equal to the Target being sent in (the principal)
        // the amount of Zeros/Claims to mint is the amount of Target deposited (sub fee), multipled by the last scale value
        mintAmount = tAmountSubFee.fmul(_scale); // NOTE: in target token term

        // Mint equal amounts of Zeros and Claims
        IZero(_pt).mint(_recipient, mintAmount);
        IClaim(_series.claim).mint(_recipient, mintAmount);

        emit Issued(_pt, mintAmount, _recipient);
    }

    /// @notice Reconstitute Target by burning Zeros and Claims
    /// @dev Explicitly burns claims before maturity, and implicitly does it at/after maturity through `_collect()`
    /// @param pt principal token address
    /// @param uAmount Balance of Zeros and Claims to burn
    function combine(address pt, uint256 uAmount) external nonReentrant notMatured returns (uint256 tAmount) {}

    /// @notice Burn Zeros of a Series once its been settled
    /// @dev The balance of redeemable Target is a function of the change in Scale
    /// @param pt principal token address
    /// @param uAmount Amount of Zeros to burn, which should be equivelent to the amount of Underlying owed to the caller
    function redeemZero(address pt, uint256 uAmount) external nonReentrant matured returns (uint256 tAmount) {}

    function collect(
        address usr,
        address pt,
        uint256 uAmountTransfer,
        address to
    ) external nonReentrant returns (uint256 collected) {
        uint256 uBal = IClaim(series[pt].claim).balanceOf(usr);
        return _collect(usr, pt, uBal, uAmountTransfer > 0 ? uAmountTransfer : uBal, to);
    }

    /// @notice Collect Claim excess before, at, or after maturity
    /// @dev If `to` is set, we copy the lscale value from usr to this address
    /// @param _usr User who's collecting for their Claims
    /// @param _pt principal token address
    /// @param _uBal claim balance
    /// @param _uAmountTransfer original transfer value
    /// @param _to address to set the lscale value from usr
    function _collect(
        address _usr,
        address _pt,
        uint256 _uBal,
        uint256 _uAmountTransfer,
        address _to
    ) internal returns (uint256 collected) {}

    /// @dev to 18 point decimal
    /// @param amount The amount of the token in native decimal encoding
    /// @param decimals decimals of the token
    function _normalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        // If we need to increase the decimals
        if (decimals > 18) {
            // Then we shift right the amount by the number of decimals
            amount = amount / 10**(decimals - 18);
            // If we need to decrease the number
        } else if (decimals < 18) {
            // then we shift left by the difference
            amount = amount * 10**(18 - decimals);
        }
        // If nothing changed this is a no-op
        return amount;
    }

    function getZeros() external view returns (address[] memory) {
        return _zeros;
    }

    function getSeries(address pt) external view returns (Series memory) {
        return series[pt];
    }

    modifier onlyPool() {
        require(poolFactory.isRegisteredPool(msg.sender), "Tranche: only pool");
        _;
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
