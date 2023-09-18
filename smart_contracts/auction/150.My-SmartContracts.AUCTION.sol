// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.10;

interface IERC721{
    function transferFrom(
    address from, 
    address to,  
    uint nftId 
    ) external; 
}



contract EnglishAuction {

    IERC721 public  nft;
    uint public nftId;
    address public seller;
    uint32 public endAt;
    bool public ended;

    uint public highestBid ;
    address public highestBidder;
    mapping (address => uint) public bids;

    event Start();
    event Bid(uint amount , address indexed Bidder);
    event Withdraw(uint amount , address indexed Bidder);

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid
    ){
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }


    function start()  external {
        require(msg.sender == seller , "not seller");
        ended = false;
        endAt = uint32(block.timestamp + 60);
        nft.transferFrom(seller , address(this) , nftId);
        emit Start();
    }

    function bid()  external payable {
            require(!ended, "not started");
            require(block.timestamp < endAt , "ended");
            require(msg.value > highestBid , "value less than the highest Bid");
            if(highestBidder != address(0)){
                     bids[highestBidder] += highestBid;
            }
           
            highestBid = msg.value;
            highestBidder = msg.sender;
            emit Bid(msg.value , msg.sender);

    }

    function withdraw() external { 
        require(bids[msg.sender] > 0 ,"YOu are not a bidder");
            uint bal = bids[msg.sender];
            bids[msg.sender] = 0;
            payable(msg.sender).transfer(bal);

    }



}