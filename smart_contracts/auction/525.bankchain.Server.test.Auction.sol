pragma solidity ^0.6.0;

import "./Ownable.sol";

import './AssetInterface.sol';

contract Auction is Ownable{
   
   bool isActive;
   
   //Asset which is on auction
   AssetInterface asset;
   
    uint public highestBid=0;
    address public highestBidder;
    
    mapping(address=>uint) public bidders;
    address[] bidderArray;
   
    event HighBidAlert(uint _bid, address _bidder);
    event bidWithdrawn(uint _bid, address _bidder);
    event newOwner(address _new);
    event auctionCanceled();
    event auctionEnded();
   
    constructor(address payable _asset) public {
        isActive=true;
        asset = AssetInterface(_asset);
        Ownable.transferOwnership(asset.owner());
    }
   
    function bid() public payable{
        assert(isActive);
        require(msg.sender!=owner(),"Owner cannot bid");
        assert(bidders[msg.sender]+msg.value>bidders[msg.sender]);
        require(bidders[msg.sender]+msg.value>highestBid,"Unnecessary Bid");
        bidders[msg.sender]+=msg.value;
        bidderArray.push(msg.sender);
        highestBid=bidders[msg.sender];
        highestBidder=msg.sender;
        emit HighBidAlert(highestBid,highestBidder);
    }
   
    function withdrawBid() public{
        assert(bidders[msg.sender]!=0 && highestBid!=bidders[msg.sender]);
        uint amount = bidders[msg.sender];
        bidders[msg.sender]=0;
        payable(msg.sender).transfer(amount);
        emit bidWithdrawn(amount,msg.sender);
    }
    
    function cancelAuction() public onlyOwner{
        isActive=false;
        for(uint i; i<bidderArray.length; i++){
                payable(bidderArray[i]).transfer(bidders[bidderArray[i]]);
        }
        emit auctionCanceled();
    }
    
    function toggleStopAuction() public onlyOwner{
        isActive=false;
        for(uint i; i<bidderArray.length; i++){
            if(bidderArray[i]!=highestBidder){
                payable(bidderArray[i]).transfer(bidders[bidderArray[i]]);
            }
        }
        asset.setNewOwner(highestBidder);
    }
    
    function endAuction() public onlyOwner{
        require(asset.owner()==highestBidder,"Ownership haven't changed yet");
        payable(owner()).transfer(highestBid);
        emit auctionEnded();
        emit newOwner(highestBidder);
    }
   
       function getBalance() view public returns(uint){
        return address(this).balance;
    }
   
      receive() external payable{}
   
}
