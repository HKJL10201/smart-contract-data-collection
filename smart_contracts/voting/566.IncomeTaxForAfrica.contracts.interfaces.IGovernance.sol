// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGovernance {
  
  function setSuperAdmin(address _newSuperAdmin) external;

  function setTenderAdmin(uint256 _tenderID, address _admin) external;

  function setSectorAdmin(uint256 _sectorID, address _newAdmin) external;

  //function changeCompanyAdmin(uint256 _companyID, address _newAdmin) external;
  
  function setSupervisor(uint256 _proposalID, address _newSupervisor) external;

  function fundTreasury(uint256 _amount) external;

  function updateBudget(uint256 _sectorID, uint256 _newBudget) external;
}