 // SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract Seller{


event HighestBidIncrease(address bidder, uint amount);

event AuctionEnded(address winner, uint amount);


// Parameters

address payable p ublic retailerAddress; // Retailer's address

address payable public sellerAddress; // Seller's address

address public highestBidder; // Highest Bidder Account Address


uint public auctionStartTime; // Auction Start time (date in timestamp)

uint public auctionEndTime; // Auction End Time (date in timestamp)

uint public network_serial_number_of_the_seller; // Network Serial Number of the Seller

uint public initial_bidding_price; // Minimum accepted Buing Price - bid init price

uint public highestBidPrice; // Highest Bid Price

uint public electricity_supply_start_time; // Electricity Supply Start Time (# of Days after Auction Starts)

uint public electricity_supply_end_time; // Electricity Supply End Time (# of Days after Auction Ends)

uint public supply_amount; // Electricity Supply Amount

uint public retailerTransferAmount; // Transfer Amount of the Retailer

uint public sellerTransferAmount; // Transfer Amount of the Seller

uint public transferAmount;

uint public deployDate; // Date of Deploy the Smart Contract

bool ended = false; // false: auction ended , true: Auction pending

bool sellerPaid = false; // false: not paid yet , true: already paid

bool adjustmentComplete = false; // true: adjustment complete

mapping (address => uint) public pendingReturns; // track of what addresses has bid and #

modifier onlySeller {

require(msg.sender == sellerAddress);

_;

}


// -------------------- Adding Money to Smart Contract ------------------------- //

// Only Highest Bider can call this function with the amount he needs to pay (transferAmount)

function addEthToSC() public payable {

require(msg.sender == highestBidder, "You need to be Highest Bider in order to call this function");

require(msg.value == transferAmount, "You have to pay the correct amount to validate your highest bid");

pendingReturns[msg.sender] = 0;

}

// -------------------- Get Smart Contract's Balance -------------------------- //

// --- The Balance Contains only the Highest Bider's Amount (transferAmount) -- //

function getBalance() public view onlySeller returns(uint) {

return address(this).balance;

}

// -------------------- Smart Contract Initializations -------------------------- //

constructor(address payable _retailerAddress, address payable _sellerAddress, uint _network_serial_number_of_the_seller, uint _electricity_supply_start_time, uint _electricity_supply_end_time, uint _supply_amount, uint _initial_bidding_price, uint _auctionStartTime, uint _biddingTime)

{

deployDate = block.timestamp;

retailerAddress = _retailerAddress;

sellerAddress = _sellerAddress;

network_serial_number_of_the_seller = _network_serial_number_of_the_seller;

electricity_supply_start_time = _electricity_supply_start_time;

electricity_supply_end_time = _electricity_supply_end_time;

supply_amount = _supply_amount;

initial_bidding_price = _initial_bidding_price;

auctionStartTime = _auctionStartTime;

auctionEndTime = auctionStartTime + _biddingTime;

}

    // --------------------------- Buyers Auction ----------------------------------- //

// ------ This function called by Buyers by Biding with a Higher Bid Price ------ //

function buyers_auction(uint _buyers_network_serial_number, uint _buyer_bid_price)

public payable {

require(msg.sender != sellerAddress, "Only Buyers can call this function and make a Bid");

require(msg.sender != retailerAddress, "Only Buyers can call this function and make a Bid");

require(pendingReturns[highestBidder] == 0, "Previous Highest Bider must pay his Transfer Amount in able to continue the Auction");

require(block.timestamp >= auctionStartTime, "Auction has not started yet");

require(block.timestamp <= auctionEndTime, "The auction has already ended");

require(_buyers_network_serial_number == network_serial_number_of_the_seller, "Buyer's Network Serial Number must be the same as Seller's");

require(_buyer_bid_price > initial_bidding_price, "Biding price must be higher than initial seller's price");

require(_buyer_bid_price > highestBidPrice, "There is already a higher or equal biding price");

if ( address(highestBidder) == address(0x0)){

highestBidder = msg.sender;

} else {

// If new highest Bider then return money to previous highest Bider

payable(highestBidder).transfer(getBalance());

// And make his pending returns = 0

pendingReturns[highestBidder] = 0;

}

// UPDATE: new Highest Bider and new Highest Bid Price

highestBidder = msg.sender;

highestBidPrice = _buyer_bid_price;

// Transfer Amount Needed

transferAmount = highestBidPrice*supply_amount*(electricity_supply_end_time - electricity_supply_start_time);

// Store Transfer Amount => pendingReturns

// This Amount is the Amount Highest Bider needs

// to Pay the Smart Contract in Order to Validate his Highest Bid

if (highestBidPrice != 0){

pendingReturns[highestBidder] += transferAmount;

}

emit HighestBidIncrease(msg.sender, _buyer_bid_price);

    }

/* ---------------------------------------------------------------------------------- */

/* */

/* CALL addEthToSC() FUNCTION WITH THE PAYING AMOUNT TO MAKE THE HIGHEST BID VALID */

/* (transferAmount) */

/* ---------------------------------------------------------------------------------- */

// ---------------------------- Pay the Seller --------------------------------- //

function pay_to_seller()

public onlySeller returns(bool) {

require(getBalance() != 0, "Highest Bider didn't pay his Transfer Amount so the auction has no winners");

require(block.timestamp > auctionEndTime, "The auction has not ended yet");

require(highestBidPrice > 0, "Paying value must not be NULL");

require(sellerPaid == false, "Already paid the Seller");

// Transfer from S.Contract(last highest bider's amount) to Seller's Address

payable(msg.sender).transfer(getBalance());

sellerPaid = true;

return sellerPaid;

}

// ----------------------------- AuctionEnd ------------------------------------- //

// This Function is just to see if the auction has ended or not //

// After auction ends an event emit the winner and the highest bid //

function auctionEnd() public {

require(block.timestamp >= auctionStartTime, "Auction has not started yet");

require(block.timestamp >= auctionEndTime, "The auction has not ended yet");

require(ended == false, "The Function auctionEnded has already been called");

ended = true;

emit AuctionEnded(highestBidder, highestBidPrice);

}

// -------------------------- Audjustment --------------------------------------- //

function adjustment(uint _sellers_actual_delivery_amount, uint _submited_volume, uint _wholesale_price, uint _retail_price)

public payable returns(bool) {

require(block.timestamp > (deployDate + ((electricity_supply_end_time)*(1 days))), "Electicity Supply Days need to fulfill in able to call this function and make a purchase");

require(msg.sender == sellerAddress, "Only Sellers or Retailers can call this Function");

require(msg.sender == retailerAddress, "Only Sellers or Retailers can call this Function");

        require(supply_amount == _submited_volume, "Submited Volume must be equal as Supply Amount");

require(sellerPaid == true, "Auction must be finished first and Seller to be paid");

if (_sellers_actual_delivery_amount > _submited_volume) {

// Transfer amount from retailer -> seller

retailerTransferAmount = (_sellers_actual_delivery_amount - supply_amount)*_wholesale_price;

if (msg.sender == retailerAddress){

require(retailerTransferAmount == msg.value, "Wrong Transfer Amount");

payable(sellerAddress).transfer(retailerTransferAmount);

adjustmentComplete = true;

}

}

else if (_sellers_actual_delivery_amount < _submited_volume) {

// Transfer amount from seller -> retailer

sellerTransferAmount = (supply_amount - _sellers_actual_delivery_amount)*_retail_price;

if (msg.sender == sellerAddress){

require(sellerTransferAmount == msg.value, "Wrong Transfer Amount");

payable(retailerAddress).transfer(sellerTransferAmount);

adjustmentComplete = true;

}

}

return adjustmentComplete;

}

}
