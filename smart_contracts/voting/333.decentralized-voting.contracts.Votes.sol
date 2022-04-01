// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Votes {
    // model vote
    struct Vote {
        uint256 id;
        string option;
        uint256 voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // store vote
    // fetch vote
    mapping(uint256 => Vote) public votes;

    // voted event
    event votedEvent(uint256 indexed _voteId);

    // read votes
    uint256 public votersCount;

    function addVoter(string memory _option) private {
        votersCount++;
        votes[votersCount] = Vote(votersCount, _option, 0);
    }

    // constr
    constructor() public {
        addVoter("Yes");
        addVoter("No");
    }

    function vote(uint256 _voterId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_voterId > 0 && _voterId <= votersCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        votes[_voterId].voteCount++;

        // trigger voted event
        emit votedEvent(_voterId);
    }
}
