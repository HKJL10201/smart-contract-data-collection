// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
  function purchase(uint256 _tokenId) external payable;
  function getPrice() external view returns (uint256);
  function available(uint256 _tokenId) external view returns (bool);
}

interface ICryptoDevsNFT {
  // returns the number of NFTs owned by the given address
  function balanceOf(address owner) external view returns (uint256);

  // return a tokenID at given index for owner
  function tokenOfOwnerByIndex(address owner, uint256 index)
      external
      view
      returns (uint256);
}

contract CryptoDevsDAO is Ownable {
  struct Proposal {
    // the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
    uint256 nftTokenId;
    // the UNIX timestamp until which this proposal is active. Proposal can be executed after
    // the deadline has been exceeded.
    uint256 deadline;
    // number of yay votes for this proposal
    uint256 yayVotes;
    // number of nay votes for this proposal
    uint256 nayVotes;
    // whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
    bool executed;
    // a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already
    // been used to cast a vote or not
    mapping(uint256 => bool) voters;
  }

  // Create a mapping of ID to Proposal
  mapping(uint256 => Proposal) public proposals;
  // Number of proposals that have been created
  uint256 public numProposals;

  IFakeNFTMarketplace nftMarketplace;
  ICryptoDevsNFT cryptoDevsNFT;

  constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
  }

  modifier nftHolderOnly() {
    require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
    _;
  }

  // createProposal allows a CryptoDevsNFT holder to create a new proposal in the DAO
  // param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if
  // this proposal passes.
  // Returns the proposal index for the newly created proposal
  function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
    require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
    Proposal storage proposal = proposals[numProposals];
    proposal.nftTokenId = _nftTokenId;
    proposal.deadline = block.timestamp + 5 minutes;
    numProposals++;
    
    return numProposals - 1;
  }

  modifier activeProposalOnly(uint256 proposalIndex) {
    require(proposals[proposalIndex].deadline > block.timestamp, "DEADLINE_EXCEEDED");
    _;
  }

  enum Vote {
    YAY,
    NAY
  }

  function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex) {
    Proposal storage proposal = proposals[proposalIndex];
    
    uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
    uint256 numVotes = 0;

    for (uint256 i = 0; i < voterNFTBalance; i++) {
      uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
      if (proposal.voters[tokenId] == false) {
        numVotes++;
        proposal.voters[tokenId] = true;
      }
    }
    require(numVotes > 0, "ALREADY_VOTED");

    if (vote == Vote.YAY) {
      proposal.yayVotes += numVotes;
    } else {
      proposal.nayVotes += numVotes;
    }
  }

  modifier inactiveProposalOnly(uint256 proposalIndex) {
    require(proposals[proposalIndex].deadline <= block.timestamp, "DEADLINE_NOT_EXCEEDED");
    require(proposals[proposalIndex].executed == false, "PROPOSAL_ALREADY_EXECUTED");
    _;
  }

  function executeProposal(uint256 proposalIndex)
    external
    nftHolderOnly
    inactiveProposalOnly(proposalIndex) {
    Proposal storage proposal = proposals[proposalIndex];

    // If the proposal has more YAY votes than NAY votes
    // purchase the NFT from the FakeNFTMarketplace
    if (proposal.yayVotes > proposal.nayVotes) {
      uint256 nftPrice = nftMarketplace.getPrice();
      require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
      nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }
    proposal.executed = true;
  }

  function withdrawEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  receive() external payable {}
  fallback() external payable {}
}
