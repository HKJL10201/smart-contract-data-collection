//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
*@author Julius Raynaldi 
* inspired by ethhole.com/challenge advertisement auction project
*/

contract Advertion is Ownable {
    event BidSuccess(address bidder, uint value, string imageLink);
    event LinkChanged(string imageLink,string targetLink);
    
    string public imageLink;
    string public targetLink;
    uint public duration = 24*60*60;
    uint public refundTime = 15*60;
    uint public endTime;
    uint public submitTime;
    uint public currentBid;
    address public bidder;

    function bid(string memory _imageLink, string memory _targetLink) external payable{
        if(block.timestamp - submitTime < 15*60) {
            (bool success, ) = address(bidder).call{value : currentBid}("");
            require(success, "bid failed");
        }
        if(endTime<block.timestamp) currentBid = 0.001 * 10**9; 
        require(msg.value > currentBid, "Not Enought for bidding ");
        
        imageLink = _imageLink;
        endTime = block.timestamp + duration;
        bidder = msg.sender;
        currentBid = msg.value;
        targetLink= _targetLink;

        emit BidSuccess(msg.sender, msg.value, imageLink);
    }

    function changeLink(string memory _imageLink, string memory _targetLink) external {
        require(msg.sender == bidder, "Not last bidder");
        imageLink = _imageLink;
        targetLink = _targetLink;
        emit LinkChanged(_imageLink, _targetLink);
    }

    function setDuration(uint _duration) external onlyOwner{
        duration = _duration;
    }

    function setRefundTime(uint _time) external onlyOwner{
        refundTime = _time;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance-currentBid}("");
        require(success,"failed to withdraw");
    }
}