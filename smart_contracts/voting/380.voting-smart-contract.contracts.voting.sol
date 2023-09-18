// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Voting {

    /**
     * This is a voting smart contract and what are the things we are exploring"
     * a. candidacy to vote.
     * b. who will declare the vote opened?
     * c. voting periods - how do we capture the before, during and after voting?
     * d. How do we keep record of the vote per the address and the person voted?
     * f. Can the voters delegate their power to vote to another person?
     * g. determine the metrics of who won the vote
     * 
     */

    // A struct to help us collect the data of the vandidates for the polls.

    struct Candidates {
        uint candidateID;
        string candidateName;
        uint candidateVoteCount;
        
    }
//  A struct to determine the number of votes per voter and the candidate voted for.
    struct validVoter {
        uint vote;
       bool voted;
        bool authorized;
    }

    // the voting controllers controls the voting process from start to finish.

    address public votingController;

    // an array to collect data of the same type.

    Candidates[] public listOfCandidates;

    enum votingState {Created, Voting, Ended}
    votingState public state;
    // bool public Created; 
    // bool public votingStarted;
    // bool public Ended;

    mapping(address => validVoter) public voters;

    string public electionName;

    uint public totalVotes;

    // This is an access modifier

    /// Voting has not Commenced

    // error VotingNotStarted();

    // /// Voting has Ended

    // error VotingHasEnded();

    /// You are not the Voting Controller

    error notManager();

    /// Voting Period not reached
    error VotingSeasonNotReached();

    modifier onlyController() {
        if (msg.sender != votingController) {
            revert notManager();
        }
        _;
    }

    modifier votingSeason() {
        require(state == votingState.Created, "Voting Window has not Reached");
        // if (!votingStarted) {
        //     revert VotingNotStarted();
        // }
        _;
    }

    modifier votingHasCommenced() {
       
       require(state == votingState.Voting, "Voting Period not yet Opened");
        // if (!Ended) {
        //     revert VotingHasEnded();

        // }
        _;
    }

    modifier votingHasEnded() {
        require(state == votingState.Ended, "Voting has Ended");
        // if (!Created) {
        //     revert VotingSeasonNotReached();
        // }
        _;
    }
    modifier verifiedVote() {
        require(!voters[msg.sender].voted, "You can only Vote once");
        _;
    }

    modifier authorizedVote() {
        require(voters[msg.sender].authorized, "You are not an authorized Voter");
        _;
    }




    constructor(string memory _name) {
        votingController = msg.sender;
        electionName = _name;
        state = votingState.Voting;
       
        

        
    }

    function addCandidate(string calldata _names) public onlyController{
        listOfCandidates.push(Candidates(0, _names, 0));
    }

    function getNumOfCandidate() public view returns(uint) {
        return listOfCandidates.length;
    }

    function authorizeVoting(address _votingPersonnel) onlyController public {
        voters[_votingPersonnel].authorized = true;
    }

    function startVoting() public votingHasCommenced onlyController {
        state = votingState.Voting;

    }

    function vote(uint _votingIndex) public  verifiedVote authorizedVote {
        voters[msg.sender].vote = _votingIndex;
        voters[msg.sender].voted = true;
        listOfCandidates[_votingIndex].candidateVoteCount +=1;
        totalVotes++;
        


    }

    function endVoting() onlyController votingHasEnded public view returns(string memory _winnerName) {
        uint winner;
        for (uint i = 0; i < listOfCandidates.length; i++) {
            if (listOfCandidates[i].candidateVoteCount > winner) {
                winner = listOfCandidates[i].candidateVoteCount;
                _winnerName = listOfCandidates[1].candidateName;
            }
            
        }
       

    }





}