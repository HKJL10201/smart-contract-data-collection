// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract smartAuction {
    mapping(address => uint) bindingBids;
    uint public highestBidAmount;
    address public highestBidderAddress;
    uint public bidIncrements;
    string public ipfsHash;

    address public  auctionOwner;

    enum auctionState {auctionStarted, auctionCurrentlyRunning, auctionCancelled, auctionCompleted}
    auctionState public state;

    receive() external payable {

    }

    fallback() external payable {

    }

    modifier validEntry() {
        require(msg.value >= 0.3 ether, "Insufficient Entry Amount");
        _;
    }

    modifier notOwner() {
        require(msg.sender != auctionOwner, "Owner cannot Participate in the Auction");
        _;
    }

    modifier onlyOwner() {
        require(auctionOwner == msg.sender, "You are not the Auction Owner");
        _;
    }

    modifier currenctAuctionState() {
        require(state == auctionState.auctionCurrentlyRunning, "Auction has not Started");
        _;
    }

    modifier stopAuction() {
        require(state == auctionState.auctionCancelled, "Soory! No More Entry. Auction has been Cancelled");
        _;
    }

    modifier completedAuction() {
        require(state == auctionState.auctionCompleted, "Sorry, Auction has been Completed, Try again Next TIme");
        _;
    }

    modifier validBids() {
        require(bindingBids[msg.sender] > 0, "Auction Has Ended");
        _;
    }


    constructor () {
        auctionOwner = payable (msg.sender);
        state = auctionState.auctionCurrentlyRunning;
        bidIncrements = 0.2 ether;
        ipfsHash = "";
    }

    // more like the tossing of a dice, which ever side has the highest bid wins

    function minBid(uint one, uint two) pure internal returns (uint) {
        if (one >= two) {
            return one;
        } else {
            return two;
        }

    }

    

    function enterAuction() public payable notOwner validEntry currenctAuctionState{
      uint currentBindingBids =  bindingBids[msg.sender] + msg.value;
      require(currentBindingBids > highestBidAmount, "Highest Binding Bid is greater than your current Bid");
      bindingBids[msg.sender] = currentBindingBids;

      if (currentBindingBids <= bindingBids[highestBidderAddress]) {
          highestBidAmount = minBid(currentBindingBids + bidIncrements, bindingBids[highestBidderAddress]);

      } else {
          highestBidAmount = minBid(currentBindingBids, bindingBids[highestBidderAddress] + bidIncrements);
          highestBidderAddress = payable(msg.sender);

      }

    }

    // An auction to get the balance of the auction

    function getAuctionBalance() public view returns (uint) {
        return address(this).balance;
    }

    // A function giving capacity to the owner to cancel the auction

    function cancelAuction () public onlyOwner {
        state = auctionState.auctionCancelled;
    }

    // A normal function to complete the auction 

    function auctionComplete() public onlyOwner completedAuction {
        state = auctionState.auctionCompleted;
    }

    // Function to end the auction and send ether to the winner of the aution

    function endAuction () public onlyOwner stopAuction validBids{

        address payable auctionWinner;
        uint valueDeposited;

        if (state == auctionState.auctionCancelled || 
            state == auctionState.auctionCompleted) {
                auctionWinner = payable(msg.sender);
                valueDeposited = bindingBids[msg.sender];
            } else {
                if (msg.sender == auctionOwner) {
                    auctionWinner != auctionOwner; 
                    valueDeposited = highestBidAmount;
                } else {
                    if (msg.sender == highestBidderAddress) {
                        auctionWinner == highestBidderAddress;
                        valueDeposited = bindingBids[highestBidderAddress] - highestBidAmount;
                    } else {
                        auctionWinner = payable(msg.sender);
                        valueDeposited = bindingBids[msg.sender];
                    }
                }
            }

            bindingBids[auctionWinner] = 0;
            auctionWinner.transfer(valueDeposited);


    }

    
}
