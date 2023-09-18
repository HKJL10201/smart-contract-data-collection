// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "./SimpleVoting.sol";

contract RegistrationVoting is SimpleVoting{
    event NewRegistration(uint256, address);

    constructor() SimpleVoting() {

    }

    modifier requiresRegistration(uint256 proposalId) {
        Proposal storage proposal = proposals[proposalId];
        bool alreadyRegistered = _addressExists(msg.sender, proposal.registeredAddresses);
        require(!proposal.requiresRegistration || alreadyRegistered, "Needs to be registered!");

        _;
    }

    function propose(string memory name, bool needsRegistration) public returns(uint256 proposalId){
        Proposal storage proposal = _createBaseProposal(name);
        proposal.requiresRegistration = needsRegistration;

        proposalId = proposal.id;

        emit NewProposal();
    } 

    function register(uint256 proposalId) public requiresProposal(proposalId){
        Proposal storage proposal = proposals[proposalId];
        require(proposal.requiresRegistration, "This proposal doesn't require registration");

        bool alreadyRegistered = _addressExists(msg.sender, proposal.registeredAddresses);
        require(!alreadyRegistered);

        proposal.registeredAddresses.push(msg.sender);

        emit NewRegistration(proposalId, msg.sender);
    }

    function approve(uint256 proposalId) override public 
        requiresProposal(proposalId) 
        requiresRegistration(proposalId)  {

        super.approve(proposalId);
    }

    function decline(uint256 proposalId) override public 
        requiresProposal(proposalId) 
        requiresRegistration(proposalId)  {

        super.decline(proposalId);
    }
}