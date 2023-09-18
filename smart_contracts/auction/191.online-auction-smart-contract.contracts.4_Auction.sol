// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.4.0 <0.9.0;

contract Auction{

    mapping(address => uint) biddersData;
    uint highestBidAmount;
    address highestBidder;
    uint startTime = block.timestamp;
    uint endTime;
    address owner;

    // bool actionEnded = false;
    //     constructor(){
    //         owner.msg.sender;
    //     }

    // put new bid

    function putBid() public payable{

        uint calculatedAmount = biddersData[msg.sender] + msg.value;

        //verify value is not zero

        require(msg.value > 0, "Bid Cannot Be Zero!");

        //check session is not ended

        require(block.timestamp <= endTime, "Auction is Ended");

        //check highest bid

        require(calculatedAmount > highestBidAmount, "Highest Bid Already Present!");
        biddersData[msg.sender] = calculatedAmount;
        highestBidAmount = calculatedAmount;
        highestBidder = msg.sender;

    }

    // get contract balance (for testing purposes)

    // function getContractBalance() public view returns(uint){

    //     return address(this).balance;
    // }

    // get bidders bid and returns their address

    function getBidderBid(address _address) public view returns(uint){

        return biddersData[_address];
    }
    // get highest bidAmount

    function HighestBid() public view returns(uint){
        return highestBidAmount;
    }

    // get highest Bidder Address

    function HighestBidder() public view returns(address){
        return highestBidder;
    }

    //put endTime
    function putEndTime(uint _endTime) public {
        endTime = _endTime;
    }

    //withdraw bid 
    function withdrawBid(address payable _address) public {
        if (biddersData[_address] > 0){
            _address.transfer(biddersData[_address]);
        }
    }
}