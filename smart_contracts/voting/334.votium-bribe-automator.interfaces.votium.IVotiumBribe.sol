// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVotiumBribe {
    struct Proposal {
      uint256 deadline;
      uint256 maxIndex;
    }

    event Bribed(address _token, uint256 _amount, bytes32 indexed _proposal, uint256 _choiceIndex);

    /// @param _proposal bytes32 of snapshot IPFS hash id for a given proposal
    function proposalInfo(bytes32 _proposal) external view returns (Proposal memory)    ;

    function depositBribe(address _token, uint256 _amount, bytes32 _proposal, uint256 _choiceIndex) external;
}