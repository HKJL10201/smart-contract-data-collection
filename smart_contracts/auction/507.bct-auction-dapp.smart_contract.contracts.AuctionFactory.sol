pragma solidity >=0.5.17 <0.9.0;

import "./SimpleAuction.sol";

contract AuctionFactory {

    struct Organiser {
        bool active;
        uint ratingSum;
        uint numberOfRates;
    }

    address[] public owners;
    mapping(address => Organiser) public ratings;
    mapping(address => mapping(address => mapping(address => bool))) public hasVoted;

    address[] public allAuctions;

    function createAuction(uint _biddingTime) public returns(address createdAuction) {
        SimpleAuction newSimpleAuction = new SimpleAuction(_biddingTime, payable(msg.sender));
        allAuctions.push(address(newSimpleAuction));

        if(!ratings[msg.sender].active) {
            ratings[msg.sender].active = true;
            owners.push(msg.sender);
        }

        return address(newSimpleAuction);
    }

    function getAllAuctions() public view returns(address[] memory) {
        return allAuctions;
    }

    function getOwners() public view returns(address[] memory) {
        return owners;
    }

    function canRate(address owner, address auction) public view returns(bool) {
        if(msg.sender == owner
                || !ratings[owner].active
                || block.timestamp > SimpleAuction(auction).auctionEndTime()
                || owner != SimpleAuction(auction).beneficiary()
                || hasVoted[owner][auction][msg.sender]) {
            return false;
        }
        if (SimpleAuction(auction).highestBidder() != msg.sender
                && SimpleAuction(auction).pendingReturns(msg.sender) == 0) {
            return false;
        }
        return true;
    }

    function rate(address owner, address auction, uint8 rate) public {
        require(rate <= 5, "Maximum value for rate is 5.");
        require(rate > 0, "Minimum value for rate is 1.");
        require(canRate(owner, auction), "You're not allowed to rate.");
        hasVoted[owner][auction][msg.sender] = true;
        ratings[owner].ratingSum += rate;
        ratings[owner].numberOfRates++;
    }

}