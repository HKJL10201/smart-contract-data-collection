pragma solidity ^0.6.0;

import "./Ownable.sol";
import './AssetInterface.sol';
import './AuctionManager.sol';

contract Auction is Ownable {

    bool isActive;
    bool isNotified=false;
    address manager;

    //Asset which is on auction
    AssetInterface asset;

    uint highestBid;
    address highestBidder;

    mapping(address=>uint)  bidders;
    address[]  bidderArray;

    event auctionStarted(address _auction, address _asset);
    event HighBidAlert(uint _bid, address _bidder);
    event bidWithdrawn(uint _bid, address _bidder);
    event newOwner(address _new);
    event auctionCanceled(address _auction, address _asset);
    event auctionEnded(address _auction, address _asset);
    event setOwner(address newOwner);

    constructor(address payable _asset, address _manager) public {
        asset = AssetInterface(_asset);
        require(msg.sender==asset.owner(),"Only Asset owner can start auction");
        manager=_manager;
    }

    function startAuction() public onlyOwner{
        isActive=true;
        notifyAuctionManager(manager);
        emit auctionStarted(address(this),address(asset));
    }

    function bid() public payable{
        assert(isActive&&isNotified);
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
        emit bidWithdrawn(amount,msg.sender);
        payable(msg.sender).transfer(amount);
    }

    function cancelAuction() public onlyOwner{
        isActive=false;
        for(uint i; i<bidderArray.length; i++){
            if(bidders[bidderArray[i]]!=0){
                payable(bidderArray[i]).transfer(bidders[bidderArray[i]]);
            }
        }
        notifyAuctionManager(manager);
        emit auctionCanceled(address(this),address(asset));
        selfdestruct(payable(owner()));
    }

    function toggleStopAuction() public onlyOwner{
        isActive=false;
        emit setOwner(highestBidder);
        for(uint i; i<bidderArray.length; i++){
            if(bidderArray[i]!=highestBidder){
                payable(bidderArray[i]).transfer(bidders[bidderArray[i]]);
            }
        }
        notifyAuctionManager(manager);
    }

    function endAuction() public onlyOwner{
        assert(!isActive);
        require(asset.owner()==highestBidder,"Ownership haven't changed yet");
        emit auctionEnded(address(this),address(asset));
        emit newOwner(highestBidder);
        selfdestruct(payable(owner()));
    }

    function getBalance() view public returns(uint){
        return payable(address(this)).balance;
    }

    function getHighestBid() view public returns(uint,address){
        return (highestBid,highestBidder);
    }

    function getAssetOnAuction() view public returns(address){
        return address(asset);
    }

    function getMyBid() view public returns(uint bid){
        return bidders[msg.sender];
    }

    function notifyAuctionManager(address _manager) private onlyOwner{
        AuctionManager a = AuctionManager(_manager);
        isNotified=a.listenToAuctionStatus(isActive);
    }

    function ping() public view returns(bool){
        return isActive;
    }

}