//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingContract {
    bool votingStartEver = false;
    address electionCommission;//election commission address
    bool voteStarted = false;//vote started or not
    string[] symbolList;  //symbol list
    struct candidate {//custom data structure
        string name;
        uint voteCount;
    }

    mapping(string => candidate) Candidates;
    mapping(string => bool) alreadyVotedList;
    //setting authority
    constructor(){
        electionCommission = msg.sender;
    }

    //authorized access
    modifier onlyElectionComission(){
        require(msg.sender == electionCommission, "Unauthorized Access.");
        _;
    }
    //voting started
    modifier votingStarted(){
        require(voteStarted == true, "Voting not started yet.");
        _;
    }

    //register for voter
    function registrationForCandidate(string memory name, string memory symbol) public onlyElectionComission
    {
        require(bytes(name).length != 0, "Name Can't be empty");
        require(bytes(symbol).length != 0, "Symbol can't be empty");
        require(bytes(Candidates[symbol].name).length == 0, "This Symbol was already taken.");
        require(votingStartEver == false, "Candidate registration was not possible.");
        symbolList.push(symbol);
        Candidates[symbol].name = name;
        Candidates[symbol].voteCount = 0;
    }

    //start voting
    function startVote() public onlyElectionComission {
        require(symbolList.length > 0, "Atleast 2 candidate must be registered.");
        require(voteStarted == false, "Already Started.");
        voteStarted = true;
        votingStartEver = true;
    }

    //stop voting
    function stopVoting() public onlyElectionComission {
        require(voteStarted == true, "Voting not started yet.");
        voteStarted = false;
    }


    //voter gives votes
    function giveVotes(string memory symbol, string memory voterAddress) public votingStarted {
        // require(bytes(Candidates[symbol].name).length!=0,"Symbol not found.");
        require(alreadyVotedList[voterAddress] != true, "You can vote once..");
        Candidates[symbol].voteCount += 1;
        alreadyVotedList[voterAddress] = true;
    }

    //get candidate details.
    function voteCountStatus(string memory symbol) public view returns (candidate memory){
        require(bytes(symbol).length > 0, "Invalid Input");
        require(bytes(Candidates[symbol].name).length > 0, "No Record Found");
        require(votingStartEver == true, "For record voting must be started once.");
        return Candidates[symbol];
    }

    //delete candidate
    function deleteCandidate(string memory symbol) public onlyElectionComission {
        require(symbolList.length > 0, "Atleast 1 candidate must be registered.");
        require(bytes(symbol).length != 0, "Can't be empty");
        require(bytes(Candidates[symbol].name).length != 0, "Symbol not registered.");
        require(votingStartEver == false, "You can't remove candidate.");
        delete Candidates[symbol];
    }

    //get symbol list
    function getSymbolList() public view returns (string[] memory){
        return symbolList;
    }
}