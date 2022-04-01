pragma solidity ^0.5.0;
contract Voting {
    struct Voter {
        uint value;
        bool voted;
    }
    struct Proposal {
        string title;
        uint vCountAbs;
        uint vCountNeg;
        uint vCountPos;
        mapping (address => Voter) voters;
        address[] votersAddress;
    }
    Proposal[] public proposals;
    event CreatedVoEvent();
    event CreatedPrEvent();
    function getTheNumberOfProposals() public view returns (uint) {
        return proposals.length;
    }
    function getProposal(uint proposalInt) public view returns (uint, string memory, uint, uint, uint, address[] memory) {
        if (proposals.length > 0) {
            Proposal storage p = proposals[proposalInt];
            return (proposalInt, p.title, p.vCountPos, p.vCountNeg, p.vCountAbs, p.votersAddress);
        }
    }
    function addProposal(string memory title) public returns (bool) {
        Proposal memory proposal;
        emit CreatedPrEvent();
        proposal.title = title;
        proposals.push(proposal);
        return true;
    }
    function vote(uint proposalInt, uint voteValue) public returns (bool) {
        if (proposals[proposalInt].voters[msg.sender].voted == false) { 
            require(voteValue == 1 || voteValue == 2 || voteValue == 3); 
            Proposal storage p = proposals[proposalInt]; 
            if (voteValue == 1) {
                p.vCountPos += 1;
            } else if (voteValue == 2) {
                p.vCountNeg += 1;
            } else {
                p.vCountAbs += 1;
            }
            p.voters[msg.sender].value = voteValue;
            p.voters[msg.sender].voted = true;
            p.votersAddress.push(msg.sender);
            emit CreatedVoEvent();
            return true;
        } else {
            return false;
        }
    }
}

