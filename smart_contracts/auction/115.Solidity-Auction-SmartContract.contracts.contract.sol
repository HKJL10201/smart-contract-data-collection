// SPDX-License-Identifier: MIT

pragma solidity  >=0.8.10;


contract SomeContract{
    address public auctionBeneficiary;
    uint256 public auctionTime;
    bool public done;
    mapping(address => uint256) bids;
    uint256 public highestBid;
    address public highestBidder;


    constructor (
        address payable beneficiary,
        uint256 time
    ){
        auctionBeneficiary = beneficiary;
        auctionTime = block.timestamp + time;
    }
    event WithdrawFailure(address recipient, uint256 amount);
    event BidError(address addr);
    event BidSuccessful(address addr, uint256 amount);
    event AutctionEnded(uint256 highestBid, address highestBidder, uint256 finishedAt);
    event AuctionFailure(address addr, uint256 highestBid);

    function bid() payable public{
        if(!(block.timestamp>auctionTime) && done != true && msg.sender != auctionBeneficiary && msg.value> highestBid){
            
            bids[msg.sender] = msg.value;
            highestBid = msg.value;
            highestBidder = msg.sender;
            emit BidSuccessful(msg.sender, msg.value);
       
        }else{
            if(auctionTime < block.timestamp){
                endAuction();
            }
            emit BidError(msg.sender);
        }
    }
    function withdraw() payable public{
        if(!(msg.sender == highestBidder)){

        
        uint256 amount = bids[msg.sender];
        bids[msg.sender] = 0;
        if(!payable(msg.sender).send(amount)){
            emit WithdrawFailure(msg.sender, amount);
        }
        }else{
            emit WithdrawFailure(msg.sender, bids[msg.sender]);
        }
    }
    function endAuction() public{
       
        done = true;
        if (!payable(auctionBeneficiary).send(highestBid)){
            emit AuctionFailure(auctionBeneficiary, highestBid);
        }
        emit AutctionEnded(highestBid, highestBidder, auctionTime);
        
    }
}


