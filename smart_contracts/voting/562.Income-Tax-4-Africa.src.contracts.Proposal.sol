// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IProposal.sol";
import "../interfaces/ICitizen.sol";
import "../libraries/CompanyLib.sol";
import "./TaxPayerCompany.sol";
import "./Citizen.sol";

contract Proposal is IProposal {

    using CompanyLib for TaxPayerCompany;
    TaxPayerCompany public _company;
    Citizen public _citizen;

    address public owner;

    uint256 public numberOfProposals;

    event ProposalCreated(Proposal _proposal);

    mapping(uint256 => Proposal) public proposals;

    constructor() {
        owner = msg.sender;
    }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------         CREATE FUNCTIONS        --------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function createProposal(Proposal memory _proposal, address _supervisor)
        public
    {
        _proposal.numberOfPublicVotes = 0;
        _proposal.proposalID = numberOfProposals;
        _proposal.storageHash = "";
        _proposal._proposalState = ProposalState.PROPOSED;

        _proposal.supervisor = _supervisor;

        proposals[numberOfProposals] = _proposal;

        numberOfProposals++;

        // _company.getCompany(_proposal.companyID).currentProposals[
        //     numberOfProposals - 1
        // ] = _proposal;

        //mapping(uint256 => IProposal.Proposal) currentProposals;

        //_company.getCompany(_proposal.companyID).numberOfProposals++;

        emit ProposalCreated(proposals[numberOfProposals - 1]);
    }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------         GENERAL FUNCTIONALITY        ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function voteForProposal(uint256 _proposalID)
        public
        onlyCitizen(msg.sender)
    {
        
        uint256 _citizenID = _citizen.getUserID(msg.sender);

        require(
            proposals[_proposalID]._proposalState == ProposalState.PROPOSED,
            "PROPOSAL CLOSED"
        );

        require(
            _citizen.getCitizen(_citizenID).taxPercentage >= 0,
            "NOT A TAX PAYER"
        );

        uint256 citizenVotePower = _citizen.getCitizen(_citizenID).taxPercentage;

        proposals[_proposalID].numberOfPublicVotes += citizenVotePower;
    }

    //Total public votes is scale of 10_000
    //Incase of ties, cheaper price quoted will be selected
    function calculateWinningProposals(uint256 _tenderID) public {
        uint256 winningNumberOfVotes = 0;
        uint256 winningBudget = 0;
        Proposal memory winningProposal;

        for (uint256 x = 0; x <= numberOfProposals; x++) {
            if (proposals[x].tenderID == _tenderID) {
                if (proposals[x].numberOfPublicVotes == winningNumberOfVotes) {
                    if (proposals[x].priceCharged < winningBudget) {
                        winningNumberOfVotes = proposals[x].numberOfPublicVotes;
                        winningProposal = proposals[x];
                    }
                } else if (
                    proposals[x].numberOfPublicVotes > winningNumberOfVotes
                ) {
                    winningNumberOfVotes = proposals[x].numberOfPublicVotes;
                    winningProposal = proposals[x];
                }
            }
        }

        winningProposal._proposalState = ProposalState.SUCCESSFULL;

        for (uint256 x = 0; x < numberOfProposals; x++) {
            if (proposals[x].tenderID == _tenderID) {
                if (proposals[x].proposalID != winningProposal.proposalID) {
                    proposals[x]._proposalState = ProposalState.UNSUCCESSFULL;
                }
            }
        }
    }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------         VIEW FUNCTIONS        --------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function viewAllProposals() public view returns (Proposal[] memory) {
        Proposal[] memory tempProposal = new Proposal[](numberOfProposals);

        for (uint256 i = 0; i < numberOfProposals; i++) {
            tempProposal[i] = proposals[i];
        }

        return tempProposal;
    }
    
    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------------        GETTER FUNCTION        --------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function getProposal(uint256 _proposalID)
        public
        view
        returns (Proposal memory)
    {
        return proposals[_proposalID];
    }
    

    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------------        MODIFIERS       --------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    modifier onlyCitizen(address citizen) {
        uint256 _citizenID = _citizen.getUserID(msg.sender);
        require(_citizenID <= _citizen.numberOfCitizens(), "ONLY CITIZENS");
        _;
    }
}