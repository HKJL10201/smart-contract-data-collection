// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface IERC721{
   
   function transferFrom(address from,address to,uint nftID ) external;
}

contract EnglishAuction{
    IERC721 public immutable nft;              
    uint public immutable nftId;                      
    address payable public immutable seller;
    uint32 public endAt;
    bool public started;
    bool public ended;
    address public highest_bidder;
    uint public highest_Bid;
    mapping(address => uint) public bids;
    event start();
    event bid(address sender,uint amount);
    event withdrawEvent(address receiver,uint amount);
    event End(address highest_bidder,uint highest_Bid);

    constructor(address _nft,uint _nftid,uint startingbid){
        nft = IERC721(_nft);
        nftId = _nftid;
        seller = payable(msg.sender); 
        highest_Bid = startingbid; 
    }

    function Start() public {
        require(msg.sender == seller," only owner can start it ");
        require(!started,"already started");

        started =  true;
        endAt = uint32(block.timestamp + 60);

        nft.transferFrom(seller,address(this),nftId);

       emit start();
    
    }

    function Bid() external payable{
        require(started,"not started yet");
        require(block.timestamp < endAt);
        require(msg.value < highest_Bid ,"bid is less than highest bid");

        if(highest_bidder != address(0)){
            bids[highest_bidder]+=highest_Bid;
        }

        highest_Bid = msg.value;
        highest_bidder = msg.sender;

        emit bid(msg.sender,msg.value);
    }

    function withdraw() external{

        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit withdrawEvent(msg.sender,bal);


    }

    function end() public{
        require(started,"not started yet");
        require(!ended,"ended");
        require(block.timestamp >= endAt,"time period is not ended yet");

        ended = true;

        if(highest_bidder != address(0)){
        nft.transferFrom(address(this),highest_bidder,nftId);
        seller.transfer(highest_Bid);}else{
            nft.transferFrom(address(this),seller,nftId);
        }

        emit End(highest_bidder,highest_Bid);

    }
}