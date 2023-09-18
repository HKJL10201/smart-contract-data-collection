// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBinnaDevsNFT.sol";
import "../interfaces/IFakeNFTMarketplace.sol";

contract BinnaDevsDAO is Ownable {
    struct Proprosal {
        // nftTokenId - the tokenID of the NFT to purchase from FakeNFTMarketplace
        // if the proposal passes
        uint256 nftTokenId;
        // deadline -  Proposal can be executed after the deadline has been exceeded.
        uint256 deadline;
        // yayVotes - number of yes votes for this proposal   
        uint256 yayVotes;
        // nayVotes - number of no votes for this proposal
        uint256 nayVotes;
        // executed - whether or not this proposal has been executed yet.
        // Cannot be executed before the deadline has been exceeded.
        bool executed;
        // voters - a mapping of BinnaDevsNFT tokenIDs to booleans indicating whether 
        // that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;
    }

    // Create an enum named Vote containing possible options for a vote
    enum Vote{
        YAY, // YAY - 0 
        NAY // NAY - 1
        }

    // Create a mapping of ID to Proposal to track all of the proposals
    mapping(uint256 => Proprosal) public proposals;

    // Number of proposals that have been created
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    IBinnaDevsNFT binnaDevsNFT;

    /**
     * Create a payable constructor which initializes the contract
     * instances for FakeNFTMarketplace and BinnaDevsNFT
     * The payable allows this constructor to accept an ETH deposit when it is being deployed
     */
    constructor(address _nftMarketplace, address _binnaDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        binnaDevsNFT = IBinnaDevsNFT(_binnaDevsNFT);
    }

    modifier nftHolderOnly(){
        require(binnaDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    /**
     * @dev createProposal allows a BinnaDevsNFT holder to create a new proposal in the DAO
     * @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace 
     * if this proposal passes
     * 
     * @return Returns the proposal index for the newly created proposal
     */
    function createProposal(uint256 _nftTokenId)
    external
    nftHolderOnly
    returns(uint256)
    {
        require(nftMarketplace.available(_nftTokenId) == true, "NFT_NOT_FOR_SALE");
        Proprosal storage proposal = proposals[numProposals];

        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    /**
     * @dev voteOnProposal allows a BinnaDevsNFT holder to cast 
     * their vote on an active proposal.
     * 
     * @param proposalIndex - the index of the proposal to vote on in the proposals array
     * @param vote - the type of vote they want to cast
     */
    function voteOnProposal(uint256 proposalIndex, Vote vote)
    external
    nftHolderOnly
    {
        require(proposals[proposalIndex].deadline > block.timestamp, "DEADLINE_EXCEEDED");
        // create an instance of Proprosal struct
        Proprosal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = binnaDevsNFT.balanceOf(msg.sender);
        // numVotes store number of NFTs a user can used to vote
        uint256 numVotes = 0;

        // Calculate how many NFTs are owned by the voter
        // that haven't already been used for voting on this proposal
        for(uint256 i = 0; i < voterNFTBalance; i++){
            uint256 tokenId = binnaDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] == false){
                numVotes++;
                proposal.voters[tokenId] == true;
            }
        }

        require(numVotes > 0, "ALREADY_VOTED");

        if(vote == Vote.YAY){
            proposal.yayVotes += numVotes;
        }else{
            proposal.nayVotes += numVotes;
        }
    }

    /**
     * @dev executeProposal allows any BinnaDevsNFT holder to execute a proposal
     * after it's deadline has been exceeded.
     * 
     * @param proposalIndex - the index of the proposal to execute in the proposals array
     */
    function executeProposal(uint256 proposalIndex)
    external
    nftHolderOnly
    {
        require(proposals[proposalIndex].deadline <= block.timestamp,"DEADLINE_NOT_EXCEEDED");
        require(proposals[proposalIndex].executed == false, "PROPOSAL_ALREADY_EXECUTED");

        // If the proposal has more YAY votes than NAY votes
        // purchase the NFT from the FakeNFTMarketplace
        Proprosal storage proposal = proposals[proposalIndex];
        if(proposal.yayVotes > proposal.nayVotes){
            uint nftPrice = nftMarketplace.getPrice();
            
            require(address(this).balance > nftPrice, "NOT_ENOUGH_FUNDS");

            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        
        proposal.executed = true;
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

     // Function to receive Ether. msg.data must be empty
    receive() external payable {}
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}