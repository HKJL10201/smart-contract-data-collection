// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IProposal.sol";

interface ITreasury {

  function getProposalStateDetails(uint256 _proposalID) external view returns (IProposal.ProposalState);

  function payPhaseOne(uint256 _proposalID) external;

  function closePhaseOne(uint256 _proposalID) external;

  function payPhaseTwo(uint256 _proposalID) external;

  function closePhaseTwo(uint256 _proposalID) external;

  function payPhaseThree(uint256 _proposalID) external;

  function closePhaseThree(uint256 _proposalID) external;

  function payPhaseFour(uint256 _proposalID) external;

  function closePhaseFour(uint256 _proposalID) external;

}