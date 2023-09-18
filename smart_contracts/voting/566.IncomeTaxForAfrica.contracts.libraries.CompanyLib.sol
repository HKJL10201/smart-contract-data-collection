// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IProposal.sol";

library CompanyLib {

  struct TaxPayerCompany {
    uint256 companyID;
    uint256 numberOfEmployees;
    uint256 proposalID;
    address admin;
    address wallet;
    string name;
    mapping(uint256 => bool) employees;
    mapping(uint256 => IProposal.Proposal) currentProposals;
    uint256 numberOfProposals;
  }

}