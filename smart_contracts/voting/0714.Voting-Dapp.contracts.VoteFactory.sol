// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Vote.sol";

contract VoteFactory {
    Vote[] public votes;

    function getVotes() external view returns (Vote[] memory) {
        return votes;
    }

    function addVote(
        string memory _name,
        uint256 _regEnd,
        uint256 _voteStart,
        uint256 _voteEnd
    ) external {
        Vote _newVote = new Vote(_name, _regEnd, _voteStart, _voteEnd);
        votes.push(_newVote);
    }
}
