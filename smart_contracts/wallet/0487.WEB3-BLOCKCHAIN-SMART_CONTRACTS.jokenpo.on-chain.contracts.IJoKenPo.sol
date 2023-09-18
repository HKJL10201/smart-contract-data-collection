/**
 *Submitted for verification at Etherscan.io on 2022-11-04
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19 .0;

import {JKPLibrary} from "./JKPLibrary.sol";

interface IJoKenPo {
    function getResult() external view returns (string memory);

    function getBid() external view returns (uint256);

    function getCommission() external view returns (uint8);

    function setBid(uint256 newBid) external;

    function setCommission(uint8 newCommission) external;

    function getBalance() external view returns (uint);

    function play(
        JKPLibrary.Options newChoice
    ) external payable returns (string memory);

    function getLeaderBoard()
        external
        view
        returns (JKPLibrary.Winner[] memory);
}
