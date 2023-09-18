// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Election is Ownable {
    //candidate_name => no of votes
    struct Candidate {
        string name;
        uint256 votes;
    }
    Candidate[] public CandidatesToVotes;
    //voter list (address => votes)
    mapping(address => uint256) public VotersToVotes;
    string public winner;
    enum ELECTION_STATE {
        CLOSED,
        OPEN,
        WINNER_ANNOUNCED
    }
    ELECTION_STATE public election_status;

    constructor() public {
        election_status = ELECTION_STATE.CLOSED;
    }

    function check_the_voter(address _voter_address)
        private
        view
        returns (bool)
    {
        if (VotersToVotes[_voter_address] == 0) {
            return true;
        } else {
            return false;
        }
    }

    function check_the_candidate(string memory _name)
        private
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < CandidatesToVotes.length; i++) {
            if (
                keccak256(abi.encodePacked(_name)) ==
                keccak256(abi.encodePacked(CandidatesToVotes[i].name))
            ) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function add_candidate(string memory _name) public onlyOwner {
        require(
            election_status == ELECTION_STATE.CLOSED,
            "Cant add candidate now"
        );
        //make a require() not to add same candidate twice
        (bool candidate_present, uint256 idx) = check_the_candidate(_name);
        require(!(candidate_present), "Candidate already exits ..!");
        CandidatesToVotes.push(Candidate(_name, 0));
    }

    function start_election() public onlyOwner {
        require(
            election_status == ELECTION_STATE.CLOSED,
            "Cant start election"
        );
        election_status = ELECTION_STATE.OPEN;
    }

    function calculate_winner() private {
        uint256 MaxVotes = 0;
        uint256 winner_idx;
        for (uint256 i = 0; i < CandidatesToVotes.length; i++) {
            if (CandidatesToVotes[i].votes > MaxVotes) {
                MaxVotes = CandidatesToVotes[i].votes;
                winner_idx = i;
            }
        }
        winner = CandidatesToVotes[winner_idx].name;
        election_status = ELECTION_STATE.WINNER_ANNOUNCED;
    }

    function end_election() public onlyOwner {
        require(election_status == ELECTION_STATE.OPEN, "Cant end election");
        election_status = ELECTION_STATE.CLOSED;
        calculate_winner();
    }

    function vote(string memory _name) public {
        //check the election status
        require(election_status == ELECTION_STATE.OPEN, "Cant vote now ..!");
        //check voter didnt voted earlier
        require(check_the_voter(msg.sender), "you have already voted ..!");
        //check _name is present in Candidate list
        (bool candidate_present, uint256 idx) = check_the_candidate(_name);
        require(candidate_present, "Vote for validate Candidate");
        CandidatesToVotes[idx].votes++;
        VotersToVotes[msg.sender] = 1;
    }
}
