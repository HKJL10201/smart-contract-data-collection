//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "hardhat/console.sol";

contract VotingContract {
  address payable public owner;

  // events make it easier to track what happened on the blockchain even though that info is public
  event NewProposalOrVote(address indexed from, uint256 timestamp, string name);

  struct Proposal {
    string name; // short name for the proposal
    string description; // description of the proposal
    uint256 voteCount; // the amount of votes that the proposal has
  }

  struct Voter {
    bool voted; // wether the address has voted or not
    bool proposed; // wether the address has proposed or not
  }

  // an array the contains all current proposals
  Proposal[] public proposals;

  // each address gets a Voter struct
  mapping(address => Voter) public voters;

  // TODO make it such that on deployment you can change proposa/vote prices

  // on deployment we create an initial proposal and set prices
  constructor(string memory _proposal_name, string memory _proposal_description)
    payable
  {
    owner = payable(msg.sender);

    proposals.push(Proposal(_proposal_name, _proposal_description, 1));
  }

  // returns an array with all current Proposal structs
  // hint for the frontend: the Proposal structs will be non-associative arrays that you need to convert to objects
  function getProposals() public view returns (Proposal[] memory) {
    return proposals;
  }

  // returns a Proposal based on its index in the proposals array
  function getProposal(uint256 _index) public view returns (Proposal memory) {
    return proposals[_index];
  }

  function getVoter() public view returns (Voter memory) {
    return voters[msg.sender];
  }

  // checks if address has proposed yet and if enough funds and then add his new Proposal to the proposals array
  function sendProposal(
    string memory _proposal_name,
    string memory _proposal_description
  ) external payable {
    Voter storage sender = voters[msg.sender];
    require(!sender.proposed, "You already proposed.");

    uint256 cost = 0.002 ether;
    require(msg.value >= cost, "Insufficient Ether provided");

    (bool success, ) = owner.call{ value: msg.value }("");
    require(success, "Failed to send money");

    proposals.push(Proposal(_proposal_name, _proposal_description, 1));
    sender.proposed = true;

    emit NewProposalOrVote(msg.sender, block.timestamp, "proposal");
  }

  // attempts to vote a proposal based on its index in the array of proposals
  function voteProposal(uint256 _index) external payable {
    // require that voter has never voted before
    Voter storage sender = voters[msg.sender];
    require(!sender.voted, "You already voted.");

    // require that voter has set the correct amount of ETH to be sent
    uint256 cost = 0.001 ether;
    require(msg.value >= cost, "Insufficient Ether provided");

    // require transaction to be confirmed
    (bool success, ) = owner.call{ value: msg.value }("");
    require(success, "Failed to send money");

    // change vote count and mark voter as 'voted'
    proposals[_index].voteCount += 1;
    sender.voted = true;

    // emit an event
    emit NewProposalOrVote(msg.sender, block.timestamp, "vote");
  }
}
