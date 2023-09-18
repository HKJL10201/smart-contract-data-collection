// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Proposal.sol";
import "./TaxPayerCompany.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IProposal.sol";
import "../interfaces/ITaxPayerCompany.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Treasury is ITreasury, Ownable, ReentrancyGuard {

  uint256 public treasuryBalance;

  IERC20 USDC;
  address public USDAddress;
  address public treasuryAddress = address(this);

  Proposal public _proposal;
  TaxPayerCompany public _company;
  //ITaxPayerCompany public _Icompany;

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------  EVENTS        ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  event PhaseOnePaid(uint256 proposalID, uint256 amount, uint256 time);
  event PhaseTwoApproved(uint256 proposalID);

  event PhaseTwoPaid(uint256 proposalID, uint256 amount, uint256 time);
  event PhaseThreeApproved(uint256 proposalID);

  event PhaseThreePaid(uint256 proposalID, uint256 amount, uint256 time);
  event PhaseFourApproved(uint256 proposalID);

  event PhaseFourPaid(uint256 proposalID, uint256 amount, uint256 time);
  event ProposalClosed(uint256 proposalID);

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------  CONSTRUCTOR         ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  constructor (address _USDC) {
    USDAddress = _USDC;
    USDC = IERC20(_USDC);
  }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------         VIEW FUNCTIONALITY       ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  function getProposalStateDetails(uint256 _proposalID) external view returns (IProposal.ProposalState) {
     return _proposal.getProposal(_proposalID)._proposalState;
  }

  //   ----------------------------------------------------------------------------------------------------------------------
  //   -----------------------------------------         ONLY SUPERVISOR FUNCTIONALITY        ---------------------------------------
  //   ----------------------------------------------------------------------------------------------------------------------

  function payPhaseOne(uint256 _proposalID) external onlySupervisor(_proposalID) nonReentrant {
    require(_proposal.getProposal(_proposalID)._proposalState == IProposal.ProposalState.PHASE_1, "NOT PHASE_1");
    
    treasuryBalance -= _proposal.getProposal(_proposalID).priceCharged/4;

    IProposal.Proposal memory p = _proposal.getProposal(_proposalID);

    uint256 _companyID = p.companyID;

    USDC.transfer(_company.getCompanyWallet(_companyID), _proposal.getProposal(_proposalID).priceCharged/4);

    emit PhaseOnePaid(_proposalID, _proposal.getProposal(_proposalID).priceCharged/4, block.timestamp);
  }

  function closePhaseOne(uint256 _proposalID) external onlySupervisor(_proposalID) {
    _proposal.getProposal(_proposalID)._proposalState = IProposal.ProposalState.PHASE_2;
  }

  function payPhaseTwo(uint256 _proposalID) external onlySupervisor(_proposalID) nonReentrant{
    require(_proposal.getProposal(_proposalID)._proposalState == IProposal.ProposalState.PHASE_2, "STILL IN PHASE ONE");

    treasuryBalance -= _proposal.getProposal(_proposalID).priceCharged/4;
    
    IProposal.Proposal memory p = _proposal.getProposal(_proposalID);

    uint256 _companyID = p.companyID;

    USDC.transfer(_company.getCompanyWallet(_companyID), _proposal.getProposal(_proposalID).priceCharged/4);

    emit PhaseTwoPaid(_proposalID, _proposal.getProposal(_proposalID).priceCharged/4, block.timestamp);
  }

  function closePhaseTwo(uint256 _proposalID) external onlySupervisor(_proposalID) {
    _proposal.getProposal(_proposalID)._proposalState = IProposal.ProposalState.PHASE_3;
  }

  function payPhaseThree(uint256 _proposalID) external onlySupervisor(_proposalID) nonReentrant {
    require(_proposal.getProposal(_proposalID)._proposalState == IProposal.ProposalState.PHASE_3, "STILL IN PHASE TWO");
        
    treasuryBalance -= _proposal.getProposal(_proposalID).priceCharged/4;

    IProposal.Proposal memory p = _proposal.getProposal(_proposalID);

    uint256 _companyID = p.companyID;

    USDC.transfer(_company.getCompanyWallet(_companyID), _proposal.getProposal(_proposalID).priceCharged/4);

    emit PhaseThreePaid(_proposalID, _proposal.getProposal(_proposalID).priceCharged/4, block.timestamp);
  }

  function closePhaseThree(uint256 _proposalID) external onlySupervisor(_proposalID) {
    _proposal.getProposal(_proposalID)._proposalState = IProposal.ProposalState.PHASE_4;
  }

  function payPhaseFour(uint256 _proposalID) external onlySupervisor(_proposalID) nonReentrant{
    require(_proposal.getProposal(_proposalID)._proposalState == IProposal.ProposalState.PHASE_4, "STILL IN PHASE THREE");

    treasuryBalance -= _proposal.getProposal(_proposalID).priceCharged/4;

    IProposal.Proposal memory p = _proposal.getProposal(_proposalID);

    uint256 _companyID = p.companyID;

    USDC.transfer(_company.getCompanyWallet(_companyID), _proposal.getProposal(_proposalID).priceCharged/4);

    emit PhaseFourPaid(_proposalID, _proposal.getProposal(_proposalID).priceCharged/4, block.timestamp);
  }

  function closePhaseFour(uint256 _proposalID) external onlySupervisor(_proposalID) {
    _proposal.getProposal(_proposalID)._proposalState = IProposal.ProposalState.CLOSED;
  }

    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------------        MODIFIERS       --------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  modifier onlySupervisor(uint256 _proposalID) {
      require(msg.sender == _proposal.getProposal(_proposalID).supervisor, "ONLY SUPERVISOR");
      _;
  }
}