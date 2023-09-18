// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ITender {

    enum Province {
    EASTERN_CAPE,
    WESTERN_CAPE,
    GAUTENG,
    KWA_ZULU_NATAL,
    NORTHERN_CAPE,
    LIMPOPO,
    MPUMALANGA,
    NORTH_WEST,
    FREESTATE
    }

    enum TenderState {
        VOTING,
        APPROVED,
        DECLINED,
        PROPOSING,
        PROPOSAL_VOTING,
        AWARDED,
        DEVELOPMENT,
        CLOSED
    }

    struct Tender {
    uint256 tenderID;
    uint256 sectorID;
    uint256 dateCreated;
    uint256 closingDate;
    Province _province;
    TenderState _tenderState;
    uint256 numberOfVotes;

    //Percentage votes the tender needs to succeed 1000 - 10000
    uint256 threshold;

    //Out of 10: 10 being high priority
    uint256 priorityPoints;

    address admin;

    string placeOfTender;
    }

    function createTender(Tender calldata _tender) external;

    function viewAllTenders() external view returns (Tender[] calldata);

    function getTender(uint256 _tenderID) external view returns (Tender calldata);

    function voteForTender(uint256 _tenderID, uint256 _citizenID) external;

    function closeVoting(uint256 _tenderID) external;

    function setThreshold(uint256 _threshold, uint256 _tenderID) external;

    function closeTender(uint256 _tenderID) external;

    function openProposals(uint256 _tenderID) external;

    function closeProposals(uint256 _tenderID) external;

    function closeProposalVoting(uint256 _tenderID) external;

    function openProjectDevelopment(uint256 _tenderID) external;

    function closeProjectDevelopment(uint256 _tenderID) external;    
}