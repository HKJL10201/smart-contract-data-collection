// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "./CommunityToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleVoting is Ownable{

    event NewProposal();

    mapping(uint256 => Proposal) proposals;

    uint256 countProposals = 0;

    enum VoteStatus{
        Missing,
        Approved,
        Declined    
    }

    struct Proposal{
        uint256 id;
        bool exists;

        bool wasApproved;
        bool isCompleted;
        string name;
        string description;
        address creator;
        uint8 approvals;
        uint8 declines;
        address[] voters;

        bool requiresRegistration;
        address[] registeredAddresses;
    }

    constructor() {
        
    }

    modifier requiresProposal(uint256 proposalId){
        require(proposals[proposalId].exists, "Proposal doesn't exist");
        _;
    }

    function propose(string memory name) public returns(uint256 proposalId){
        Proposal memory proposal = _createBaseProposal(name);
        proposalId = proposal.id;


        emit NewProposal();
    }
    
    function finishProposal(uint256 proposalId) public view onlyOwner requiresProposal(proposalId) returns(bool wasApproved){
        Proposal memory proposal = proposals[proposalId];

        proposal.wasApproved = wasApproved = proposal.approvals > proposal.declines;
        proposal.isCompleted = true;
    }

    function getProposal(uint256 proposalId) public view requiresProposal(proposalId) returns(Proposal memory proposal){
        proposal = proposals[proposalId];
    }

    function approve(uint256 proposalId) public virtual requiresProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(!_addressExists(msg.sender, proposal.voters), "Already voted!");


        proposal.voters.push(msg.sender);
        proposal.approvals++;
    }

    function decline(uint256 proposalId) public virtual requiresProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(!_addressExists(msg.sender, proposal.voters), "Already voted!");

        proposal.voters.push(msg.sender);
        proposal.declines++;
    }

    function _createBaseProposal(string memory name) internal returns(Proposal storage){
        require(bytes(name).length != 0, "Enter a valid name!");
        Proposal storage newProposal = proposals[countProposals];
        newProposal.id = countProposals;

        newProposal.wasApproved = false;
        newProposal.isCompleted = false;
        newProposal.name = name;
        newProposal.description = name;
        newProposal.creator = msg.sender;
        newProposal.exists = true;

        countProposals++;

        return newProposal;
    }


    function _addressExists(address addrs, address[] memory addresses) internal pure returns(bool) {
        for(uint256 i = 0; i < addresses.length; i++)        
        {
            if(addresses[i] == addrs){
                return true;
            }
        }

        return false;
    }
}