// SPDX-License-Identifier: GPL-3.0
import "./ElectionsWinner.sol";
import "./Voters.sol";
pragma solidity ^0.8.17;

contract Candidates {
    struct Candidate {
        string name; // name of the candidate who can receive votes
        uint votes; // total votes it has
    }
    // uint public inde;
    address public owner; //person who deployed the contract
    Candidate[] public candidates; // array of type Candidate to store candidates name and their votes
    uint public winnerIndex;
    bytes data;
    constructor(string[] memory existingCandidates) {
        //initialize the existing candidates to the voting system
        owner = msg.sender;
        for (uint256 index = 0; index < existingCandidates.length; index++) {
            candidates.push(
                Candidate({name: existingCandidates[index], votes: 0})
            );
        }
    }
    function getCandidates() public view returns(Candidate[] memory){
        return candidates;
    }
    function giveRightToVote(address voterContractAddress,address voterAccountAddress) public {
        //need voters to give them access to vote
        require(
            msg.sender == owner,
            "Only chairperson can give right to vote."
        );
        //call giveAccessToVote function from Voters contract
        (bool success,bytes memory data) = voterContractAddress.call(abi.encodeWithSignature("giveAccessToVote(address)", voterAccountAddress));    
        require(success,"right to vote failed");
        // Voters temp = Voters(address(voterContractAddress));
        // temp.giveAccessToVote(voterAccountAddress);
    }
    function addCandidate(string memory newCandidate) public { //add new candidate to elections
        require(msg.sender == owner);
        candidates.push(Candidate({name: newCandidate, votes: 0}));
    }
    function castVote(uint candidateIndex) public {
        require(candidateIndex < candidates.length,"Invalid index");
        candidates[candidateIndex].votes+=1;
    }
    function getWinnerName(address electionWinnerContractAddress) public returns (uint[] memory votesArray){
        // ElectionsWinner electionsWinner = new ElectionsWinner(getCandidatesVotes());
        // inde = electionsWinner.winnerIndex();
        votesArray = getCandidatesVotes();
        // return votesArray;
        ElectionsWinner temp;
        temp = ElectionsWinner(electionWinnerContractAddress);    
        temp.getWinnerIndex(votesArray);
        // (bool success,bytes memory _data ) = electionWinnerContractAddress.call(abi.encodeWithSignature("getWinnerIndex(uint[] memory)",votesArray));
        // require(success,"didn't get winner index");
        // data = _data; 
        // require(success,"Getting winner name failed");       
        // return data;
        // return candidates[electionsWinner.winnerIndex()].name;
    }
    function getCandidatesVotes() public view returns (uint[] memory tempCandidatesVotes) { // return copy of Candidates
        tempCandidatesVotes = new uint[](candidates.length);
        for (uint index = 0; index < candidates.length; index++) {
            tempCandidatesVotes[index] = candidates[index].votes;
        }
        // return tempCandidatesVotes;
    }
}
