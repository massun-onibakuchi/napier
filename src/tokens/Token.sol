// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IToken.sol";

/// @title Base Token
// TODO: this contract can be deployed with minimal proxy
contract Token is IToken, ERC20 {
    uint8 private immutable _DECIMALS;

    uint256 private immutable _BASE_UNIT;

    address public immutable tranche;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _tranche
    ) ERC20(_name, _symbol) {
        _DECIMALS = _decimals;
        _BASE_UNIT = 10**_decimals;
        tranche = _tranche;
    }

    function decimals() public view override(ERC20, IERC20Metadata) returns (uint8) {
        return _DECIMALS;
    }

    /// @param account The address to send the minted tokens
    /// @param amount The amount to be minted
    function mint(address account, uint256 amount) public onlyTranche {
        _mint(account, amount);
    }

    /// @param account The address from where to burn tokens from
    /// @param amount The amount to be burned
    function burn(address account, uint256 amount) public onlyTranche {
        _burn(account, amount);
    }

    modifier onlyTranche() {
        require(msg.sender == tranche, "Token:Only tranche can mint/burn");
        _;
    }
}
