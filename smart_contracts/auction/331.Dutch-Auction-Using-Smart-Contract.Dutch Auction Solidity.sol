pragma solidity >=0.4.22 <0.7.0;
//SPDX-License-Identifier: 	AFL-3.0

//
//Steps to use the contract
//1. Deploy contract
//2. Use the DAuction function to set the item number, start price, reserve price, and the price decrease rate (the decrement for the price)
//3. Use the startBidding function to start the bidding for the auction
//4. When the dutch auction receives a bid it will call getPrice to get the updated price and then calls bid 
//(Make sure when bidding that there is enough gas)
//Optional: getPrice function will get the updated price of the auction item. Only works when the step is StepBeginBidding
//Once the auction ends the beneficiary can withdraw the asking price amount to their own address
//If the winning bid makes a bid over the asking price, the over bid amount can also be withdrawn back to the winning bid address
//In this case the time period before the next price decrease is set to 5 minutes, however it can be changed in the GetPrice Function
//All prices in DAuction Function are in WEI!
//
contract DuchAuction {
    address payable public beneficiary;
    uint public ReservePrice; //price at whiich the auction will end
    uint public StartPrice; // starting price
    uint public PriceDecreaseRate; //price decrease rate
    uint public FinalPrice; //price at the end of the auction
    uint public ItemAuction; //item that will be auctioned
    uint public AuctionTime; // Auction start time when startbidding function is called
    uint public UpdatedPrice; //Updated price for the auction
    uint public multiplier; //multiplier for the price decrease
    uint public overbidAmount; //Amount that was over the asking price so bidder can withdraw
    Steps public Step;
    
    address payable public winningBidAddress; //address of the winning bid

//Creating specic events of the Auction

    event AuctionBegan(); //Auction start
    event Bid(address _from); //The address of the bidder 
    event AuctionEnd(uint _FinalPrice); // Auction ended at final Price
    
// designing stages of the auction 

    enum Steps {
      StepBegin, //beneficiary starts an auction
      StepBeginBidding, //start acceptting bids
      StepStopBidding, //stop accepting bids i.e. price < reserve price
      StepEnd // auction ended
    }
    
//modifier

// functionality at specific step that check at which step the auction is at the moment

    modifier AtStep(Steps _Step) {
        require(Step == _Step);
        _;
    }

//modifier to allow only auction owner to do certain things

    modifier OnlyOwner() {
        require(msg.sender == beneficiary, "Only contract owner can do this");
        _;
    }
//constructor

    function DAuction(uint _ItemAuction, uint _StartPrice, uint _ReservePrice, uint _PriceDecreaseRate) public {
        beneficiary = msg.sender;
        ItemAuction = _ItemAuction;
        StartPrice = _StartPrice;
        ReservePrice = _ReservePrice;
        PriceDecreaseRate = _PriceDecreaseRate;
        Step = Steps.StepBegin;
        
    }
    
    receive() external payable{
        GetPrice();
        bid();
    }

// Making the start of the auction possible only for the beneficiary additionaly it will define the start of the auction time
    function startbidding() public OnlyOwner AtStep(Steps.StepBegin)
    {
        Step = Steps.StepBeginBidding;
        AuctionTime = block.timestamp;
        emit AuctionBegan();
    }

//function to decrease item's price over time
    function GetPrice() public AtStep(Steps.StepBeginBidding) returns (uint)
    {
        //use auction start time and current time to create a multiplier to decrease the price
        multiplier = (now - AuctionTime)/(5 minutes);
        UpdatedPrice = StartPrice - (PriceDecreaseRate * multiplier);
        return UpdatedPrice; //items price will decrease by decreasing rate based on the auction stage
        
    }
    
//Run this function when the contract receives a bid
//Check that the bid is equal or higher than the asking price before accepting the bid
//Update the step of the contract

    function bid() public payable AtStep(Steps.StepBeginBidding) {
        uint price = UpdatedPrice;
        // Do not accept the bid if its lower than the current price
        require(msg.value >= price, "Bid lower than asking price");
        if (msg.value > price) {
            overbidAmount = msg.value - price; //calculate the amount over the asking price
            
        }
        winningBidAddress = msg.sender;
        
        //If end price is lower than the reserve price abort the auction       
        if(price < ReservePrice) {
            FinalPrice = 0; // Thus final price will be quall to 0 i.e. no items sold
            Step = Steps.StepStopBidding; //Eventually moving on to the stop bidding step
            emit AuctionEnd(0);
        }
        else {
            FinalPrice = UpdatedPrice;
            Step = Steps.StepStopBidding;
        }
        
        emit Bid(msg.sender);
    }
    
//Allow the winning bidder to withdraw any amount that was over the asking price
    function withdraw() public AtStep(Steps.StepEnd) {
    require(overbidAmount > 0, "There is no overbid amount to withdraw");
    winningBidAddress.transfer(overbidAmount);
    }
    
//Allow beneficiary to withdraw the winning bid
    function ownerwithdraw() public OnlyOwner AtStep(Steps.StepStopBidding)  {
        uint ownderWithdrawAmount = UpdatedPrice;
        
        beneficiary.transfer(ownderWithdrawAmount);
        //However this time its indicative of the Auction end
        Step = Steps.StepEnd;
        emit AuctionEnd(FinalPrice);
    }
}
        
