// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    mapping(address => uint256) private votes;
    mapping(uint256 => uint256) private voteCount;

    event VoteCast(address indexed voter, uint256 indexed option);
    event VoteCounted(uint256 indexed option, uint256 count);

    function vote(uint256 _option) external {
        require(_option > 0, "Invalid option");

        votes[msg.sender] = _option;
        voteCount[_option]++;

        emit VoteCast(msg.sender, _option);
    }

    function getVote(address _voter) external view returns (uint256) {
        return votes[_voter];
    }

    function getCount(uint256 _option) external view returns (uint256) {
        return voteCount[_option];
    }

    function countVotes(uint256 _option) external {
        require(_option > 0, "Invalid option");

        uint256 count = 0;
        address[] memory voters = new address[](address(this).balance);

        for (uint256 i = 0; i < voters.length; i++) {
            if (votes[voters[i]] == _option) {
                count++;
            }
        }

        emit VoteCounted(_option, count);
    }
}
