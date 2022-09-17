// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface CETHTokenInterface {
    ///@notice Send Ether to CEther to mint
    function mint() external payable;
}
