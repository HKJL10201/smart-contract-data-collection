// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct candidate {
        string name;
        uint256 vote_count;
    }

    candidate[] public all_candidates;
    address owner;
    mapping(address => bool) public voters;

    uint256 public voting_starts;
    uint256 public voting_ends;

    constructor(string[] memory _candidate_names, uint256 _timeDuration_minutes) {
        for (uint256 i = 0; i < _candidate_names.length; i++) {
            candidate memory c = candidate(_candidate_names[i], 0);

            all_candidates.push(c);
        }
        owner = msg.sender;
        voting_starts = block.timestamp;
        voting_ends = block.timestamp + (_timeDuration_minutes * 1 minutes);
    }

    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }

    function add_candidate(string memory _name) public only_owner {
        candidate memory new_candidate = candidate(_name, 0);
        all_candidates.push(new_candidate);
    }

    function vote(uint256 _candidate_index) public {
        require(!voters[msg.sender], "you have already voted !!");
        require(_candidate_index < all_candidates.length, "invalid index of candidate");

        all_candidates[_candidate_index].vote_count++;
        voters[msg.sender] = true;
    }

    function get_all_candidates() public view returns (candidate[] memory) {
        return all_candidates;
    }

    function get_voting_status() public view returns (bool) {
        return (block.timestamp >= voting_starts && block.timestamp < voting_ends);
    }

    function get_remaining_time() public view returns (uint256) {
        require(block.timestamp >= voting_starts, "voting hasn.t started yet !!");
        if (block.timestamp >= voting_ends) {
            return 0;
        }
        return voting_ends - block.timestamp;
    }
}
