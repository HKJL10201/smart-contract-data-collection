pragma solidity ^0.6.0;

import './Auction.sol';

contract AuctionManager{

    //add events to notify the client

    mapping(address=>Auction) onGoingAssetAuction;

    event auctionStatus(string status, address _auction);

    function listenToAuctionStatus(bool _status) public returns(bool){
        onGoingAssetAuction[Auction(msg.sender).getAssetOnAuction()] = Auction(msg.sender);
        if(!_status){
            onGoingAssetAuction[Auction(msg.sender).getAssetOnAuction()]=Auction(address(0));
            emit auctionStatus("Ended",address(0));
        }else{
            emit auctionStatus("Started",msg.sender);
        }
        return (_status);
    }

    function getAuctionStatus(address _asset) view public returns(address auction, bool status){
        address _temp = address(onGoingAssetAuction[_asset]);
        if(_temp==address(0)){
            return (address(0),false);
        }else {
            return (_temp,onGoingAssetAuction[_asset].ping());
        }
    }
}
