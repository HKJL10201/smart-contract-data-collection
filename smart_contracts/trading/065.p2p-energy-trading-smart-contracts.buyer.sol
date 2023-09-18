

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// Electricity Buyer Deploys the Buyer Contract

contract Buyer{

// Parameters

address payable public retailerAddress; // Retatiler's address

address payable public buyerAddress; // Buyer's address same as contract address

uint public deployDate;

uint public auctionStartTime; // Auction Start Time (date in timestamp)

uint public auctionEndTime; // Auction End Time

uint public network_serial_number_of_the_buyer; // Network Serial Number of the Buyer

uint public initial_bidding_price; // maximum accepted selling Price - bid init price

address public lowestBidder; // Lowest Bidder Account Address

uint public lowestBidPrice; // Lowest Bid Price

uint public electricity_demand_start_time; // Electricity Demand Start Time

uint public electricity_demand_end_time; // Electricity Demand End Time

uint public demand_amount; // Electricity Demand Amount

uint public wholesalerTransferAmount; // Transfer amount of the Wholesaler

uint public sellerTransferAmount; // Transfer amount of the Seller

uint public lowestBidPriceAccepted; // Accepted Lowest Bid

uint public priceAmountDifference;

uint public newLowestBidPrice;

uint public withdrawAmount;

uint public retailerTransferAmount; // Transfer Amount of the Retailer

uint public lowestAmount;

uint public _deposit_amount;

mapping (address => uint) public buyersPendingReturns; // track of what addresses has bid how much

mapping (address => uint) public pendingReturns; // track of what addresses has bid how much

bool ended = false; // false: auction ended, true: Auction pending

bool public sellerPaid = false; // false: not paid yet, true: already paid

bool adjustmentComplete = false;

event AuctionEnded(

address winner,

uint amount

);


event buyerwithdrawal(

address indexed _from,

uint amount

);



modifier onlyBuyer {

require(msg.sender == buyerAddress);

_;

}


// Smart Contract Initializations

constructor (address payable _retailerAddress, address payable _buyerAddress, uint _network_serial_number_of_the_buyer, uint _electricity_demand_start_time, uint _electricity_demand_end_time, uint _demand_amount, uint _initial_bidding_price,uint _auctionStartTime, uint _biddingTime)

{

deployDate = block.timestamp;

retailerAddress = _retailerAddress;

buyerAddress = _buyerAddress;

network_serial_number_of_the_buyer = _network_serial_number_of_the_buyer;

electricity_demand_start_time = _electricity_demand_start_time;

electricity_demand_end_time = _electricity_demand_end_time;

demand_amount = _demand_amount;

initial_bidding_price = _initial_bidding_price;

auctionStartTime = _auctionStartTime; //in timestamp

auctionEndTime = auctionStartTime + _biddingTime;

lowestBidPriceAccepted = initial_bidding_price*demand_amount*(electricity_demand_end_time - electricity_demand_start_time);

_deposit_amount = lowestBidPriceAccepted;

}


    // This function called by the Buyer to deposit

function buyers_deposit() public onlyBuyer payable {

require(block.timestamp < auctionEndTime, "You did not deposit on time!" );

require(address(this).balance != 0, "You already made a deposit!!!");

require( msg.value == _deposit_amount,"The deposit amount is wrong!");

}


//Balance of the contract

function getBalance() public onlyBuyer view returns(uint) {

return address(this).balance;

}


// This function called by Sellers

function sellers_auction(uint _sellers_network_serial_number, uint _seller_bid_price)

public {

require(buyerAddress != msg.sender,"Only sellers can bid");

require(retailerAddress != msg.sender,"Only sellers can bid");

_seller_bid_price = _seller_bid_price*demand_amount*(electricity_demand_end_time - electricity_demand_start_time);

// initial_bidding_price = initial_bidding_price*demand_amount*(electricity_demand_end_time - electricity_demand_start_time);

require(block.timestamp >= auctionStartTime, "The auction has not started yet!");

require(block.timestamp <= auctionEndTime, "The auction has ended");

require(_sellers_network_serial_number == network_serial_number_of_the_buyer, "Network ser. Number must be the same");

require(_seller_bid_price < lowestBidPriceAccepted, "Bid price must be lower than initial seller's price");

if (lowestBidPrice != 0){

require(_seller_bid_price < lowestBidPrice, "There is already a lower/equal bid");

}

lowestBidder = msg.sender; // Seller address account = new lowest bidder

        lowestBidPrice = _seller_bid_price; // With lowest bid price = lowestBidPrice


// if new bid is lower than the initial bid price then

// calculate the difference and store it to buyer's address (mapping)

// for later withdrawal when auction ends

if (lowestBidPrice < lowestBidPriceAccepted){

//Smart Contracts Transfer price difference back to buyer's address

priceAmountDifference = lowestBidPriceAccepted - lowestBidPrice;

//priceAmountDifference = initial_bidding_price - lowestBidPrice;

buyersPendingReturns[buyerAddress] = priceAmountDifference; // store amount -> Bider's pending returns accoun

}

}


//Buyer calls withdraw function after the seller has been paid!!(a way to have less fees from txs)

function withdraw() public onlyBuyer payable {

require(sellerPaid == true, "Seller needs to be paid first!");

require(address(this).balance == priceAmountDifference, "Wallet balance too low to fund withdraw");

buyerAddress.transfer(address(this).balance);

emit buyerwithdrawal(msg.sender, address(this).balance);

}


// Pay the Seller

// Only lowest Bidder-seller can call this function

function pay_to_seller() public payable returns(bool) {

require(msg.sender == lowestBidder, "Only lowest Bider can call this function");

require(address(this).balance != 0, "A deposit from buyer was not made");

require(block.timestamp >= auctionEndTime, "The auction has not ended yet");

require(lowestBidPrice > 0, "Paying value must not be NULL");

require(sellerPaid == false, "Already paid the Seller");

lowestAmount = lowestBidPrice;

if (lowestAmount > 0) {

lowestBidPrice = 0;

payable(msg.sender).transfer(lowestAmount);

        }

sellerPaid = true;

return sellerPaid;

}


// AuctionEnd

function auctionEnd() public {


require(block.timestamp >= auctionEndTime, "The auction has not ended yet");

require(ended == false, "The Function auctionEnded has already been called");

ended = true;

emit AuctionEnded(lowestBidder, lowestBidPrice);

}

function adjustment(uint _actual_delivery_amount, uint _submited_volume, uint _wholesale_price, uint _retail_price)

public payable returns (bool){


require(block.timestamp > deployDate + ((electricity_demand_end_time)*(1 days)), "You cannot call this function yet!");

require(msg.sender == retailerAddress ,"Only the retailer or the buyer can call this function");

require(msg.sender == lowestBidder,"Only the retailer or the buyer can call this function");

require(sellerPaid == true, "Auction must be finished first and Seller to be paid");

require(demand_amount == _submited_volume, "Wrong submited volume amount!");

if (_actual_delivery_amount > _submited_volume) {

// Transfer amount from retailer -> seller

retailerTransferAmount = (_wholesale_price)*(_actual_delivery_amount - _submited_volume) ;

if (msg.sender == retailerAddress){

require(retailerTransferAmount == msg.value, "Wrong ammount!!");

payable(lowestBidder).transfer(retailerTransferAmount);

adjustmentComplete = true;

}

}

else if (_actual_delivery_amount < _submited_volume) {

// Transfer amount from seller -> retailer

            sellerTransferAmount = (_retail_price)*(_submited_volume - _actual_delivery_amount) ;

if (msg.sender == lowestBidder){

require(sellerTransferAmount == msg.value, "Wrong ammount!!");

payable(retailerAddress).transfer(sellerTransferAmount);

adjustmentComplete = true;

}

}

return adjustmentComplete;

}

}
