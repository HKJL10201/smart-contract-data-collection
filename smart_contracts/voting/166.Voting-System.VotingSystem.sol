// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

error NotOwner();

contract Elections {
    address public immutable OWNER;
    mapping(address => bool) internal ElectionCommittee;
    mapping(address => Voter) public Voters;
    // mapping(address => bool) public Voters;
    // mapping(bytes32 => bool) public Candidates
    // mapping(bytes32 => uint256) CandidatesVoteCount;

    struct candidate {
        string name;
        uint256 VoteCount;
    }
    candidate[] public ListOfCandidates;

    struct Voter {
        bool RightToVote;
        bool Voted;
        uint256 CandidateChosenIndex;
    }

    constructor(string[] memory Candidates) {
        OWNER = msg.sender;
        ElectionCommittee[OWNER] = true;
        for (uint i = 0; i < Candidates.length; i++) {
            ListOfCandidates.push(candidate({
                name: Candidates[i],
                VoteCount: 0
            }));
        }
    }

    function AppointMemberOfElectionCommittee(address Member) public onlyOwner {
        ElectionCommittee[Member] = true;
    }

    function Vote(uint256 ChosenIndex) public {
        Voter storage _voter = Voters[msg.sender];
        require(_voter.RightToVote == true , "You don't have right to vote, request from any member of Election Committee");
        require(_voter.Voted == false , "You have voted already!");
        _voter.Voted = true;
        _voter.CandidateChosenIndex = ChosenIndex;
        ListOfCandidates[ChosenIndex].VoteCount+=1;
    }

    function giveVotingRights(address _voter) public {
        require(ElectionCommittee[msg.sender] == true , "Only Member of Election Committee can give voting rights!");
        require(Voters[_voter].Voted == false, "This person has already voted!");
        Voters[_voter].RightToVote = true;
    }

    modifier onlyOwner {
        if( msg.sender != OWNER) { revert NotOwner();}
        _;
    }

    function findWinner() internal view returns(uint){
        uint WinningIndex;
        uint256 max; 
        for(uint i=0; i< ListOfCandidates.length; i++){
            if(ListOfCandidates[i].VoteCount > max){
                WinningIndex = i;
                max = ListOfCandidates[i].VoteCount;
            }
        }
        return WinningIndex;
    }

    function WinnerName() external view returns (string memory winner) {
        winner = ListOfCandidates[findWinner()].name;
    }
}
