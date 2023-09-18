// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Auction {
    address payable public auctioneer;
    uint public sTimeBlock;
    uint public eTimeBlock;

    uint public highestPayableBid;
    uint public bidInc;

    enum Auc_status {Running, Ended, Cancelled}
    Auc_status public auctionStatus;

    address payable public highestBidder;
    mapping(address => uint) public bids;

    error invalidStatus(string, address);

    constructor(){
        auctioneer = payable(msg.sender);
        sTimeBlock = block.number;
        eTimeBlock = sTimeBlock + 240; // 15 sec = 1 block, 1min = 4 block, 1hour = 240
        bidInc = 1 ether;
        auctionStatus = Auc_status.Running;
    }

    modifier notOwner(){
        require(msg.sender != auctioneer, "You can not bid to your own auction!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auctioneer, "Unauthorized!");
        _;
    }

    modifier checkStatus() {
        if(block.number < sTimeBlock || block.number > eTimeBlock){
            revert invalidStatus("The auction is not running right now!", msg.sender);
        }
        _;
    }

    function min(uint x, uint y) pure private returns(uint){
        if(x <= y){
            return x;
        }else{
            return y;
        }
    }

    function endAuc() public onlyOwner{
        auctionStatus = Auc_status.Ended;
    }

    function bid() payable public notOwner checkStatus{
        require(auctionStatus == Auc_status.Running, "The auction isn't running right now!");
        require(msg.value >= 1 ether, "Bid value must be grater than 1 eth");

        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestPayableBid, "Bid amount is lower!");

        bids[msg.sender] = currentBid;

        if(currentBid < bids[highestBidder]){
            highestPayableBid = min(currentBid + bidInc, bids[msg.sender]);
        }else{
            highestPayableBid = min(currentBid, bids[msg.sender] + bidInc);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuc() public {
        require(auctionStatus != Auc_status.Running || block.number > eTimeBlock);
        require(bids[msg.sender] > 0, "You have no eth left!");

        address payable user;
        uint value;

        if (auctionStatus == Auc_status.Cancelled){
            user = payable(msg.sender);
            value = bids[msg.sender];
        }

        if (msg.sender == auctioneer){
            user = auctioneer;
            value = highestPayableBid;
        }else if (msg.sender == highestBidder){
            user = highestBidder;
            value = bids[msg.sender] - highestPayableBid;
        }else {
            user = payable(msg.sender);
            value = bids[msg.sender];
        }
        bids[msg.sender] = 0;
        user.transfer(value);
    }
}
