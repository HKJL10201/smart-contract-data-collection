// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/ITender.sol";
import "./Sector.sol";
import "./Citizen.sol";
import "./Proposal.sol";

contract Tender is ITender {

    address public owner;

    Sector public _sector;
    Citizen public _citizen;

    uint256 public numberOfTenders;

    mapping(uint256 => Tender) public tenders;
    
    Proposal public _proposalContract;

    event TenderCreated(Tender _tender);
    event VoteSubmitted(address _voter, uint256 _tenderVotedFor, uint256 _tendersNumberOfVotes);
    event VoteClosed(uint256 _tenderVoteIsClosedFor);
    event UpdatedThreshold(uint256 _oldValue, uint256 _newValue);
    event TenderClosed(uint256 _tenderThatIsClosed);
    event ProposalOpened(uint256 _tenderProposalOpenFor);
    event ProposalClosed(uint256 _tenderThatProposalIsClosed);
    event ProposalVotingClosed(uint256 _tenderThatProposalVotingIsClosed);
    event OpenDevelopment(uint256 _tenderThatDevelopmentIsOpen);
    event CloseDevelopment(uint256 _tenderThatDevelopmentIsClosed);
    event UpdateAdmin(uint256 _tenderAdminIsUpdated, address _oldAdmin, address _newAdmin);
    event UpdateSuperAdmin(address _oldSuperAdmin, address _newSuperAdmin);

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------         CREATE FUNCTIONS        --------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function createTender(Tender memory _tender) public {

        _tender._tenderState = TenderState.VOTING;
        _tender.tenderID = numberOfTenders;
        _tender.numberOfVotes = 0;
        _tender.dateCreated = block.timestamp;
        _tender._province = Province.EASTERN_CAPE;

        tenders[numberOfTenders] = _tender;

        _sector.getSector(_tender.sectorID).numberOfTenders++;

        numberOfTenders++;

        emit TenderCreated(tenders[numberOfTenders - 1]);

    }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------         VIEW FUNCTIONS        --------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------


    function viewAllTenders() public view returns (Tender[] memory) {
        
        Tender[] memory tempTender = new Tender[](numberOfTenders);

        for (uint256 i = 0; i < numberOfTenders; i++) {
            tempTender[i] = tenders[i];
        }

        return tempTender;
    }

    // function getTender(uint256 _tenderID) public view returns (Tender calldata){
    //     return tenders[_tenderID];
    // }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------         GENERAL FUNCTIONALITY        ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function voteForTender(uint256 _tenderID, uint256 _citizenID) public onlyCitizen(msg.sender) {
        require(
            tenders[_tenderID]._tenderState == TenderState.VOTING,
            "TENDER NOT IN VOTING STAGE"
        );

        require(_citizen.getCitizen(_citizenID).totalPriorityPoints < tenders[_tenderID].priorityPoints, "NOT ENOUGH PRIORITY POINTS");

        uint256 tenderPriorityPoints = tenders[_tenderID].priorityPoints;

        _citizen.getCitizen(_citizenID).totalPriorityPoints -= tenderPriorityPoints;
        tenders[_tenderID].numberOfVotes++;

        emit VoteSubmitted(msg.sender, _tenderID, tenders[_tenderID].numberOfVotes);
        
    }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------         ONLY-ADMIN FUNCTIONALITY        ------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    /** 
        Calculating whether a project should progress to next voting stage based on how many votes it recieved
     */
    function closeVoting(uint256 _tenderID) public onlyAdmin(_tenderID) {

        uint256 totalTenderVotes = tenders[_tenderID].numberOfVotes;
        uint256 tenderThreshold = tenders[_tenderID].threshold;

        if (totalTenderVotes > (_citizen.numberOfCitizens() * tenderThreshold / 10000)) {
            tenders[_tenderID]._tenderState = TenderState.APPROVED;
        } else {
            tenders[_tenderID]._tenderState = TenderState.DECLINED;
        }

        emit VoteClosed(_tenderID);

    }

    function setThreshold(uint256 _threshold, uint256 _tenderID) public onlyAdmin(_tenderID) {

        uint256 oldThreshold = tenders[_tenderID].threshold;
        tenders[_tenderID].threshold = _threshold;

        emit UpdatedThreshold(oldThreshold, tenders[_tenderID].threshold);

    }

    function closeTender(uint256 _tenderID) public onlyAdmin(_tenderID){

        require(tenders[_tenderID]._tenderState == TenderState.DEVELOPMENT || block.timestamp >= tenders[_tenderID].closingDate, "NOT ALLOWED TO CLOSE TENDER");

        tenders[_tenderID]._tenderState == TenderState.CLOSED;    

        emit TenderClosed(_tenderID);

    }

    function openProposals(uint256 _tenderID) public onlyAdmin(_tenderID){

        require(tenders[_tenderID]._tenderState == TenderState.APPROVED, "TENDER NOT APPROVED");
        
        tenders[_tenderID]._tenderState == TenderState.PROPOSING;    

        emit ProposalOpened(_tenderID);

    }

    function closeProposals(uint256 _tenderID) public onlyAdmin(_tenderID){

        require(tenders[_tenderID]._tenderState == TenderState.PROPOSING, "NOT IN PROPOSING STATE");

        tenders[_tenderID]._tenderState == TenderState.PROPOSAL_VOTING;   

        emit ProposalClosed(_tenderID); 
    }

    function closeProposalVoting(uint256 _tenderID) public onlyAdmin(_tenderID){

        require(tenders[_tenderID]._tenderState == TenderState.PROPOSAL_VOTING, "NOT CURRENT VOTING");

        _proposalContract.calculateWinningProposals(_tenderID);

        tenders[_tenderID]._tenderState == TenderState.AWARDED; 

        emit ProposalVotingClosed(_tenderID);  
    }

    function openProjectDevelopment(uint256 _tenderID) public onlyAdmin(_tenderID){

        require(tenders[_tenderID]._tenderState == TenderState.AWARDED, "NOT AWARDED");

        tenders[_tenderID]._tenderState == TenderState.DEVELOPMENT;

        emit OpenDevelopment(_tenderID);

    }

    function closeProjectDevelopment(uint256 _tenderID) public onlyAdmin(_tenderID){

        require(tenders[_tenderID]._tenderState == TenderState.DEVELOPMENT, "NOT IN DEVELOPMENT");

        tenders[_tenderID]._tenderState == TenderState.CLOSED;

        emit CloseDevelopment(_tenderID);

    }

    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------------        GETTER FUNCTION        --------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function getTender(uint256 _tenderID) public view returns (Tender memory){
        return tenders[_tenderID];
    }

    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------------        MODIFIERS       --------------------------------
    //----------------------------------------------------------------------------------------------------------------------

     modifier onlyCitizen(address citizen) {
        uint256 _citizenID = _citizen.getUserID(msg.sender);
        require(_citizenID <= _citizen.numberOfCitizens(), "ONLY CITIZENS");
        _;
    }

     modifier onlyAdmin(uint256 _tenderID) {
        require(msg.sender == tenders[_tenderID].admin, "ONLY ADMIN");
        _;
    }

}