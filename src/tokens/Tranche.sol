// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/ITranche.sol";
// import "../interfaces/IToken.sol";
import "./Token.sol";
import "../interfaces/INapierPoolFactory.sol";
import "../adapters/BaseAdapter.sol";

// For convenience
interface Zero is IToken {} // prettier-ignore

interface Claim is IToken {} // prettier-ignore

/// @notice You can use this contract to issue, combine, and redeem Sense ERC20 Zeros and Claims
contract Tranche is ERC20, ReentrancyGuard, ITranche {
    // timestamp of series end
    uint256 public immutable override maturity;

    // timestamp of series initialization
    uint256 public immutable override issuance;

    IERC20 public immutable override underlying;

    address public immutable sponsor;

    INapierPoolFactory public immutable poolFactory;

    struct Series {
        // address zero; // Zero ERC20 token
        address claim; // Claim ERC20 token
        BaseAdapter adapter; // Adapter
        uint256 reward; // tracks fees due to the series' settler
        uint256 iscale; // scale at issuance
        uint256 mscale; // scale at maturity
        uint256 maxscale; // max scale value from this series' lifetime
        uint128 tilt; // % of underlying principal initially reserved for Claims
    }

    /// @notice pt -> Series
    mapping(address => Series) public series;

    /// @notice pt -> user -> lscale (last scale)
    mapping(address => mapping(uint256 => mapping(address => uint256))) public lscales;

    struct InitParams {
        BaseAdapter adapter; // Adapter
        uint128 tilt; // % of underlying principal initially reserved for Claims
    }

    // TODO: token name and symbol
    // TODO: deploy tranche with CREATE2 from factory, init with callback instead of constructor
    // ref: Element finance and Uniswap V3
    constructor(
        InitParams[] memory _params,
        address _underlying,
        uint256 _maturity,
        address _sponsor,
        INapierPoolFactory _poolFactory
    ) ERC20("Napier Principal Token", "nPT") {
        issuance = block.timestamp;
        maturity = _maturity;
        sponsor = _sponsor;
        underlying = IERC20(_underlying);
        poolFactory = _poolFactory;

        uint256 len = _params.length;
        for (uint256 i = 0; i < len; ) {
            require(_underlying == _params[i].adapter.underlying(), "Tranche: underlying mismatch");

            uint8 uDecimals = IERC20Metadata(_underlying).decimals();

            address zero = address(new Token("Zero", "ZERO", uDecimals, address(this)));
            address claim = address(new Token("Claim", "CLAIM", uDecimals, address(this)));
            uint256 iscale = _params[i].adapter.scale();

            series[zero] = Series({
                claim: claim,
                adapter: _params[i].adapter,
                reward: 0,
                iscale: iscale,
                mscale: 0,
                maxscale: iscale,
                tilt: _params[i].tilt
            });
            unchecked {
                i++;
            }
        }
    }

    /// @dev only registered pools can mint
    /// @param account The address to send the minted tokens
    /// @param amount The amount to be minted
    function mintNapierPT(address account, uint256 amount) external onlyPool {
        _mint(account, amount);
    }

    /// @dev only registered pools can burn
    /// @param account The address from where to burn tokens from
    /// @param amount The amount to be burned
    function burnNapierPT(address account, uint256 amount) external onlyPool {
        _burn(account, amount);
    }

    function scale() public {}

    /// @notice Mint Zeros and Claims of a specific protocol
    /// @param pt principal token address
    /// @param tAmount amount of Target to deposit
    /// @dev The balance of Zeros/Claims minted will be the same value in units of underlying (less fees)
    function issue(address pt, uint256 tAmount) external nonReentrant returns (uint256 uAmount) {}

    /// @notice Reconstitute Target by burning Zeros and Claims
    /// @dev Explicitly burns claims before maturity, and implicitly does it at/after maturity through `_collect()`
    /// @param pt principal token address
    /// @param uAmount Balance of Zeros and Claims to burn
    function combine(address pt, uint256 uAmount) external nonReentrant returns (uint256 tAmount) {}

    /// @notice Burn Zeros of a Series once its been settled
    /// @dev The balance of redeemable Target is a function of the change in Scale
    /// @param pt principal token address
    /// @param uAmount Amount of Zeros to burn, which should be equivelent to the amount of Underlying owed to the caller
    function redeemZero(address pt, uint256 uAmount) external nonReentrant returns (uint256 tBal) {}

    function collect(
        address usr,
        address pt,
        uint256 uAmountTransfer,
        address to
    ) external nonReentrant returns (uint256 collected) {
        uint256 uBal = Claim(msg.sender).balanceOf(usr);
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

    modifier onlyPool() {
        require(poolFactory.isPool(msg.sender), "Tranche: only pool");
        _;
    }
}
