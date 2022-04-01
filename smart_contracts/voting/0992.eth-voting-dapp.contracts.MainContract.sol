// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Election.sol";

contract MainContract {
    uint256 public electionId = 0;
    mapping(uint256 => address) public Elections;

    function createElection(string[] memory _info, string[] memory _candidates)
        public
    {
        Election election = new Election(_info, _candidates);
        Elections[electionId] = address(election);
        electionId++;
    }
}
