// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ballot {
    address public chairperson;
    bool public votingEnabled;
   // bool public novoters;

    modifier onlyChairperson  {
        require (msg.sender == chairperson);
        _;
    }

    modifier votingIsEnabled{
        require (votingEnabled == true, "Voting Disabled");
        _;
    }

  //  modifier novoters{
   //     require (novoters == true, "No Count of Votes");
   //     _;
   // }

    struct Candidate {
        string name;
        uint voteCount;
    }

     struct Voter{
        bool voted;
        uint vote;
    }


   // Candidate public Pacman = Candidate ();
    Candidate[] public candidates;
    mapping (address => Voter) public voters;

    //Candidate public Leni = Candidate ("Leni", 0);
    //Candidate public Bongbong = Candidate ("BBM", 0);

    function setVotingState(bool _votingEnabled) public onlyChairperson{
        //if (msg.sender != chairperson) {
        // revert("Woopsie");
       // }
       // require (msg.sender == chairperson, "Must be a Chairperson");
        votingEnabled = _votingEnabled;
    }

    constructor (string [] memory candidateNames) {
        chairperson = msg.sender;
        for (uint index = 0; index < candidateNames.length; index++)
        candidates.push(Candidate(candidateNames[index], 0));

        //candidates.push(Candidate("Pacman", 0));
        //candidates.push(Candidate("Leni", 0));
        //candidates.push(Candidate("Bong2", 0));
    }

     function vote(uint _candidate) public votingIsEnabled {
         require (voters[msg.sender].voted == false, "Already Voted.");
        voters[msg.sender].vote = _candidate;
        voters[msg.sender].voted = true;

        candidates[_candidate].voteCount++;
    }

    function getCandidatesLength() public view returns(uint) {
        return candidates.length;
    }

    function getWinningCandidate() public view returns(uint) {
        uint winningVoteCount;
        uint winningCandidate;
        for (uint index = 0; index < candidates.length; index++) {
        if (candidates[index].voteCount > winningVoteCount) {
            winningVoteCount = candidates[index].voteCount;
            winningCandidate = index;
            }
        }
        return winningCandidate;

        //require (msg.sender == false, "Wala pa pre");
    }

    function getWinner() public view returns (string memory) {
        uint winner = getWinningCandidate();
        if (candidates[winner].voteCount > 0) {
            return candidates[winner].name;
        }
        return "";
    }

}