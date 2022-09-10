// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/INapierPT.sol";

// Maybe unused
abstract contract NapierPT is ERC20("Napier PT", "nPT"), INapierPT {

}
