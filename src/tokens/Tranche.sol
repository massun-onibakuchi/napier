// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../utils/FixedMath.sol";

// import "../interfaces/IToken.sol";
import "../interfaces/ITranche.sol";
import "../interfaces/INapierPoolFactory.sol";

import {BaseAdapter as Adapter} from "../adapters/BaseAdapter.sol";
import "./Token.sol";

// For convenience
interface Zero is IToken {} // prettier-ignore

interface Claim is IToken {} // prettier-ignore

/// @notice You can use this contract to issue, combine, and redeem Sense ERC20 Zeros and Claims
contract Tranche is ERC20, ReentrancyGuard, ITranche {
    using FixedMath for uint256;
    using SafeERC20 for IERC20Metadata;

    uint256 public constant ISSUANCE_FEE_CAP = 0.1e18; // 10% issuance fee cap

    // timestamp of series end
    uint256 public immutable override maturity;

    // timestamp of series initialization
    uint256 public immutable override issuance;

    IERC20 public immutable override underlying;

    address public immutable sponsor;

    INapierPoolFactory public immutable poolFactory;

    /// @notice pt -> Series
    mapping(address => Series) internal series;

    /// @notice pt -> user -> lscale (last scale)
    mapping(address => mapping(address => uint256)) public lscales;

    // TODO: token name and symbol
    // TODO: deploy tranche with CREATE2 from factory, init with callback instead of constructor
    // ref: Element finance and Uniswap V3
    constructor(
        Adapter[] memory adapters,
        address _underlying,
        uint256 _maturity,
        address _sponsor,
        INapierPoolFactory _poolFactory
    ) ERC20("Napier Principal Token", "nPT") {
        require(block.timestamp < _maturity, "Tranche: maturity in the past");

        issuance = block.timestamp;
        maturity = _maturity;
        sponsor = _sponsor;
        underlying = IERC20(_underlying);
        poolFactory = _poolFactory;

        uint256 len = adapters.length;
        for (uint256 i = 0; i < len; ) {
            require(_underlying == adapters[i].underlying(), "Tranche: underlying mismatch");

            uint8 tDecimals = IERC20Metadata(adapters[i].getTarget()).decimals();

            // TODO: Zero and Claim token name and symbol
            address zero = address(new Token("Zero", "ZERO", tDecimals, address(this)));
            address claim = address(new Token("Claim", "CLAIM", tDecimals, address(this)));
            uint256 iscale = adapters[i].scale();

            series[zero] = Series({
                claim: claim,
                adapter: adapters[i],
                reward: 0,
                iscale: iscale,
                mscale: 0,
                maxscale: iscale,
                tilt: adapters[i].tilt()
            });
            unchecked {
                i++;
            }
        }
    }

    /// @dev only registered pools can mint
    /// @param account The address to send the minted tokens
    /// @param amount The amount to be minted
    function mintNapierPT(address account, uint256 amount) external onlyPool notMatured {
        _mint(account, amount);
    }

    /// @dev only registered pools can burn
    /// @param account The address from where to burn tokens from
    /// @param amount The amount to be burned
    function burnNapierPT(address account, uint256 amount) external onlyPool notMatured {
        _burn(account, amount);
    }

    function scale() public {}

    /// @notice Mint Zeros and Claims of a specific protocol
    /// @param pt principal token address
    /// @param tAmount amount of Target to deposit
    /// @dev The balance of Zeros/Claims minted will be the same value in units of underlying (less fees)
    function issue(address pt, uint256 tAmount) external nonReentrant notMatured returns (uint256 uAmount) {
        Series memory _series = series[pt];

        require(_series.claim != address(0), "Tranche: invalid pt");

        IERC20Metadata target = IERC20Metadata(_series.adapter.getTarget());
        uint256 tDecimals = target.decimals();
        uint256 tBase = 10**tDecimals;
        uint256 fee;

        // Take the issuance fee out of the deposited Target, and put it towards the settlement reward
        uint256 issuanceFee = _series.adapter.getIssuanceFee();
        require(issuanceFee <= ISSUANCE_FEE_CAP, "Tranche: issuance fee too high");

        if (tDecimals != 18) {
            uint256 base = (tDecimals < 18 ? issuanceFee / (10**(18 - tDecimals)) : issuanceFee * 10**(tDecimals - 18));
            fee = base.fmul(tAmount, tBase);
        } else {
            fee = issuanceFee.fmul(tAmount, tBase);
        }

        // update accrued fees
        series[pt].reward += fee;
        uint256 tAmountSubFee = tAmount - fee;

        target.safeTransferFrom(msg.sender, address(this), tAmount);
        // target.safeTransferFrom(msg.sender, address(_series.adapter), tAmountSubFee);
        // target.safeTransferFrom(msg.sender, address(_series.adapter), fee);

        // If the caller has collected on Claims before, use the scale value from that collection to determine how many Zeros/Claims to mint
        // so that the Claims they mint here will have the same amount of yield stored up as their existing holdings
        uint256 _scale = lscales[pt][msg.sender];

        // If the caller has not collected on Claims before, use the current scale value to determine how many Zeros/Claims to mint
        // so that the Claims they mint here are "clean," in that they have no yet-to-be-collected yield
        if (_scale == 0) {
            _scale = _series.adapter.scale();
            lscales[pt][msg.sender] = _scale;
        }

        // Determine the amount of Underlying equal to the Target being sent in (the principal)
        // the amount of Zeros/Claims to mint is the amount of Target deposited (sub fee), multipled by the last scale value
        uAmount = tAmountSubFee.fmul(_scale, tBase);

        // Mint equal amounts of Zeros and Claims
        Zero(pt).mint(msg.sender, uAmount);
        Claim(_series.claim).mint(msg.sender, uAmount);

        emit Issued(pt, uAmount, msg.sender);
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
        uint256 uBal = Claim(series[pt].claim).balanceOf(usr);
        return _collect(usr, pt, uBal, uAmountTransfer > 0 ? uAmountTransfer : uBal, to);
    }

    /// @notice Collect Claim excess before, at, or after maturity
    /// @dev If `to` is set, we copy the lscale value from usr to this address
    /// @param usr User who's collecting for their Claims
    /// @param pt principal token address
    /// @param uBal claim balance
    /// @param uAmountTransfer original transfer value
    /// @param to address to set the lscale value from usr
    function _collect(
        address usr,
        address pt,
        uint256 uBal,
        uint256 uAmountTransfer,
        address to
    ) internal returns (uint256 collected) {}

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
