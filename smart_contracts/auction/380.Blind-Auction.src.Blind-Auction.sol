// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BlindAuction {

    uint256 public AuctionStart;
    uint256 public AuctionDuration;
    uint256 public AuctionEnd;
    address public Owner;
    address public Admin;
    address public winner;

    mapping(address => Bid) public Bids;

    address[] public Bidders;

    struct Bid {
        bytes32 CommitHash;
        uint256 Amount;
        uint timeofBid;
    }

    struct AuctionedItem {
        address nftAddress;
        uint256 tokenId;
        address owner;
    }

    AuctionedItem public ItemtobeAuctioned;

    event AuctionStarted(uint256 _starttime, address _owner);

    constructor(uint256 _AuctionDuration, address _Admin){
        AuctionDuration = _AuctionDuration;
        Admin = _Admin;
    }

    function CommitBid(uint _amount, bytes32 _salt) public {
        require(block.timestamp < AuctionEnd, "Auction has ended");
        uint256 _amountinEther = _amount * 1 ether;
        bytes32 _commitedHash = keccak256(abi.encodePacked(_amountinEther, _salt));
        Bids[msg.sender].CommitHash = _commitedHash;
        Bids[msg.sender].timeofBid = block.timestamp;
        Bidders.push(msg.sender);
    }


    function RevealBid(uint _amount, bytes32 _salt) public {
        require(block.timestamp > AuctionEnd, "Auction is still ongoing");
        uint256 _amountinEther = _amount * 1 ether;
        bytes32 _commitedHash = keccak256(abi.encodePacked(_amountinEther, _salt));
        require(_commitedHash == Bids[msg.sender].CommitHash, "Invalid amount or salt");
        Bids[msg.sender].Amount = _amount;
    }

    function createAuction(address _nftContract,uint _tokenId) public {
        Owner = msg.sender;
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Only the owner of an NFT can auction it");
        ItemtobeAuctioned = AuctionedItem(_nftContract, _tokenId, msg.sender);
        AuctionStart = block.timestamp;
        AuctionEnd = AuctionStart + AuctionDuration;
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        emit AuctionStarted(block.timestamp, Owner);
    }

    function getWinner() public returns (address _winner) {
        require(msg.sender == Admin, "Only Admin can call this function");
        _winner;
        for (uint i; i < Bidders.length; i++){
            if (Bids[Bidders[i]].Amount > Bids[_winner].Amount){
                _winner = Bidders[i];
            } 
        }
        if (_winner == address(0)){
            cancelAuction();
        }
        winner = _winner;
    }


    function claimItem() public payable {
        require(block.timestamp > AuctionEnd, "Auction still ongoing");
        require(msg.sender == winner, "Only winner can claim NFT");
        require(msg.value == Bids[msg.sender].Amount, "Send the amount you used to bid");
        IERC721(ItemtobeAuctioned.nftAddress).transferFrom(address(this), winner, ItemtobeAuctioned.tokenId);
    }

    function withdrawFunds() public {
        require(msg.sender == ItemtobeAuctioned.owner, "Only Item owner can withdraw funds");
        (bool success,) = payable(ItemtobeAuctioned.owner).call{value: Bids[winner].Amount}("");
        require(success, "Failed to send funds");
    }

    function cancelAuction() public {
        require(msg.sender == Admin, "Only Admin can cancel an auction");
        AuctionEnd = block.timestamp;
        IERC721(ItemtobeAuctioned.nftAddress).transferFrom(address(this), ItemtobeAuctioned.owner, ItemtobeAuctioned.tokenId);
    }


    fallback() external payable {}

    receive() external payable {}
}