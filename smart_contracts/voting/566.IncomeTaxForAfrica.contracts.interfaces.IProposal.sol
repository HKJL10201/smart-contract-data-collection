// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IProposal {

    enum ProposalState {
        PROPOSED,
        UNSUCCESSFULL,
        SUCCESSFULL,
        PHASE_1,
        PHASE_2,
        PHASE_3,
        PHASE_4,
        CLOSED
    }

    struct Proposal {
        uint256 proposalID;
        uint256 tenderID;
        uint256 sectorID;
        uint256 companyID;
        uint256 priceCharged;
        uint256 numberOfPublicVotes;
        address supervisor;
        string storageHash;
        ProposalState _proposalState;
    }

    function createProposal(Proposal calldata _proposal, address _supervisor) external;

    function voteForProposal(uint256 _proposalID) external;

    function calculateWinningProposals(uint256 _tenderID) external;

    function viewAllProposals() external view returns (Proposal[] memory);

    function getProposal(uint256 _proposalID) external view returns (Proposal memory);

}