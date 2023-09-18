// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "..//interfaces/IGovernance.sol";
import "./Citizen.sol";
import "./Proposal.sol";
import "./Sector.sol";
import "./Tender.sol";
import "./TaxPayerCompany.sol";
import "./Treasury.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Governance is IGovernance, Ownable, ReentrancyGuard {

  address public superAdmin;
  address public USDAddress;

  IERC20 USDC;

  Citizen public _citizen;
  Proposal public _proposal;
  Tender public _tender;
  Sector public _sector;
  TaxPayerCompany public _company;
  Treasury public _treasury;

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------  EVENTS        ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  event SetSuperAdmin(address previousSuperAdmin, address newAdmin, uint256 time);
  event SetTenderAdmin(uint256 tenderID,address previousAdmin, address newAdmin, uint256 time);
  event SetSectorAdmin(uint256 sectorID, address newAdmin, uint256 time);
  event ChangeCompanyAdmin(uint256 companyID,address previousAdmin, address newAdmin, uint256 time);
  event SetSupervisor(uint256 proposalID, address previousSupervisor, address newSupervisor, uint256 time);

  event TreasuryBalanceUpdated(uint256 newBalance);
  event SectorBudgetUpdated(uint256 newBudget);

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------  CONSTRUCTOR        ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  constructor (address _USDC) {
    USDAddress = _USDC;
    USDC = IERC20(_USDC);
    superAdmin = msg.sender;

    _proposal = new Proposal();

    _proposal.createProposal(IProposal.Proposal({
      proposalID: 0,
      tenderID:0,
      sectorID:0,
      companyID:0,
      priceCharged:0,
      numberOfPublicVotes:0,
      supervisor:msg.sender,
      storageHash:"",
      _proposalState: IProposal.ProposalState.PROPOSED
    }), msg.sender);
  }


    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------  ACCESS FUNCTIONS       ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  function setSuperAdmin(address _newSuperAdmin) public onlySuperAdmin(){
        require(_newSuperAdmin != address(0), "CANNOT BE ZERO ADDRESS");

        address previousSuperAdmin = superAdmin;

        superAdmin = _newSuperAdmin;

        emit SetSuperAdmin(previousSuperAdmin, superAdmin, block.timestamp);
  }

  //_proposal.getProposal(_proposalID)._proposalState
  function setTenderAdmin(uint256 _tenderID, address _admin) public onlySuperAdmin(){
        require(_admin != address(0), "CANNOT BE ZERO ADDRESS");

        address previousAdmin =  _tender.getTender(_tenderID).admin;

        _tender.getTender(_tenderID).admin = _admin;

        emit SetTenderAdmin(_tenderID, previousAdmin, _admin, block.timestamp);
  }


  function setSectorAdmin(uint256 _sectorID, address _newAdmin) public onlyOwner {
    require(_newAdmin != address(0), "CANNOT BE ZERO ADDRESS");

    _sector.getSector(_sectorID).sectorAdmin = _newAdmin; 

    emit SetSectorAdmin(_sectorID, _newAdmin, block.timestamp);
  }

  // function changeCompanyAdmin(uint256 _companyID, address _newAdmin) public onlyAdmin (_companyID) {
  //       require(_newAdmin != address(0), "CANNOT BE ZERO ADDRESS");
  //       require(_companyID <= _company.numberOfCompanies(), "NOT A VALID COMPANY ID");

  //       address previousAdmin = _company.getCompanyAdmin(_companyID);
  //       _company.getCompany(_companyID).admin = _newAdmin;

  //       emit ChangeCompanyAdmin(_companyID, previousAdmin, _newAdmin, block.timestamp);
  // }
  
  function setSupervisor(uint256 _proposalID, address _newSupervisor) public onlySupervisor(_proposalID) {
    require(_newSupervisor != address(0), "CANNOT BE ZERO ADDRESS");
    require(_proposalID <= _proposal.numberOfProposals(), "NOT A VALID COMPANY ID");

    address previousSupervisor =  _proposal.getProposal(_proposalID).supervisor;

    _proposal.getProposal(_proposalID).supervisor = _newSupervisor;

    emit SetSupervisor(_proposalID, previousSupervisor, _newSupervisor, block.timestamp);
  } 

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------  GENERAL FUNCTIONS       ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  function fundTreasury(uint256 _amount) public onlySuperAdmin() nonReentrant {

    USDC.transfer(_treasury.treasuryAddress(), _amount);

    emit TreasuryBalanceUpdated(_amount);
  }

  function updateBudget(uint256 _sectorID, uint256 _newBudget) public onlySuperAdmin() {
    _sector.getSector(_sectorID).budget = _newBudget;

    emit SectorBudgetUpdated(_newBudget);
  }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------  GETTER FUNCTION        ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

  function getSuperAdmin() public view returns (address) {
    return superAdmin;
  }

    //----------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------  MODIFIERS        ---------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

   modifier onlyAdmin(uint256 _tenderID) {
        require(msg.sender == _tender.getTender(_tenderID).admin, "ONLY ADMIN");
        _;
    }

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "ONLY SUPER ADMIN");
        _;
    }

    modifier onlySupervisor(uint256 _proposalID) {
        IProposal.Proposal memory currentProposal = _proposal.getProposal(_proposalID);

        require(msg.sender == _proposal.getProposal(_proposalID).supervisor, "ONLY SUPERVISOR");
        _;
    }
}