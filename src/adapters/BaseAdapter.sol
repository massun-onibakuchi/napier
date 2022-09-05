// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib as SafeERC20} from "solmate/utils/SafeTransferLib.sol";
import {FixedMath} from "../utils/FixedMath.sol";
import {Errors} from "../utils/Errors.sol";

abstract contract BaseAdapter {
    using FixedMath for uint256;
    using SafeERC20 for ERC20;

    AdapterParams public adapterParams;

    struct AdapterParams {
        address underlying; //
        address target;
        // Target token
        uint256 delta; // max growth per second allowed
        uint256 minm; // min maturity (seconds after block.timstamp)
        uint256 maxm; // max maturity (seconds after block.timstamp)
    }

    string public name;
    string public symbol;
    LScale public _lscale;

    struct LScale {
        uint256 timestamp; // timestamp of the last scale value
        uint256 value; // last scale value
    }

    constructor(AdapterParams memory _adapterParams) {
        adapterParams = _adapterParams;

        name = string(abi.encodePacked(ERC20(_adapterParams.target).name(), " Adapter"));
        symbol = string(abi.encodePacked(ERC20(_adapterParams.target).symbol(), "-adapter"));
    }

    /// @notice Calculate and return this adapter's Scale value for the current timestamp
    /// @dev For some Targets, such as cTokens, this is simply the exchange rate, or `supply cToken / supply underlying`
    /// @dev For other Targets, such as AMM LP shares, specialized logic will be required
    /// @return _value WAD Scale value
    function scale() external virtual returns (uint256) {
        uint256 _value = _scale();
        uint256 lvalue = _lscale.value;
        uint256 elapsed = block.timestamp - _lscale.timestamp;

        if (elapsed > 0 && lvalue != 0) {
            // check actual growth vs delta (max growth per sec)
            uint256 growthPerSec = (_value > lvalue ? _value - lvalue : lvalue - _value).fdiv(
                lvalue * elapsed,
                10**ERC20(adapterParams.target).decimals()
            );

            if (growthPerSec > adapterParams.delta) {
                revert(Errors.InvalidScaleValue);
            }
        }

        if (_value != lvalue) {
            // update value only if different than the previous
            _lscale.value = _value;
            _lscale.timestamp = block.timestamp;
        }

        return _value;
    }

    /// @notice Scale getter that must be overriden by child contracts
    function _scale() internal virtual returns (uint256);

    /// @notice Underlying token address getter that must be overriden by child contracts
    function underlying() external view virtual returns (address);

    /// @notice Tilt value getter that may be overriden by child contracts
    /// @dev Returns `0` by default, which means no principal is set aside for Claims
    function tilt() external virtual returns (uint128) {
        return 0;
    }

    /// @notice Deposits underlying `amount`in return for target. Must be overriden by child contracts
    /// @param amount Underlying amount
    /// @return amount of target returned
    function wrapUnderlying(uint256 amount) external virtual returns (uint256);

    /// @notice Deposits target `amount`in return for underlying. Must be overriden by child contracts
    /// @param amount Target amount
    /// @return amount of underlying returned
    function unwrapTarget(uint256 amount) external virtual returns (uint256);

    /* ========== ACCESSORS ========== */

    function getTarget() external view returns (address) {}
}
