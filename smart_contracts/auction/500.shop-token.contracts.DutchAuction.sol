pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./ShopToken.sol";

contract DutchAuction {
    using SafeMath for uint;

    // Auction Bid
    struct Bid {
        uint price;
        uint transfer;
        bool placed;
    }

    // Auction Stages
    enum Stages {
        AuctionDeployed,
        AuctionSetup,
        AuctionStarted,
        AuctionEnded
    }
    
    // Auction Ending Reasons
    enum Endings {
        Manual,
        TimeLimit,
        SoldOut,
        SoldOutBonus
    }

    // Auction Events
    event AuctionDeployed(uint indexed priceStart);
    event AuctionSetup();
    event AuctionStarted();
    event BidReceived(address indexed _address, uint price, uint transfer);
    event BidPartiallyRefunded(address indexed _address, uint transfer);
    event AuctionEnded(uint priceFinal, Endings ending);

    // Token contract reference
    ShopToken public token;

    // Current stage
    Stages public current_stage;

    // `address` ⇒ `Bid` mapping
    mapping (address => Bid) public bids;

    // Auction owner address
    address public owner_address;

    // Starting price in wei
    uint public price_start;

    // Final price in wei
    uint public price_final;

    // Token unit multiplier
    uint public token_multiplier = 10 ** 18;

    // Number of received wei
    uint public received_wei = 0;

    // Total number of token units for auction
    uint public initial_offering;

    // Oversubscription bonus
    uint public last_bonus;

    // Auction start time
    uint public start_time;

    // Auction duration, in days
    uint public duration = 30;

    // Precision for price calculation
    uint public precision = 10 ** 13;

    // Price decay rates per day
    uint[30] public rates = [
        precision,
        7694472807310,
        5920491178244,
        4555505837691,
        3505221579166,
        2697083212449,
        2075263343724,
        1596805736629,
        1228657831905,
        945387427708,
        727425785487,
        559715792577,
        430671794580,
        331379241228,
        254978856053,
        196192787434,
        150960006790,
        116155766724,
        89375738847,
        68769919219,
        52914827339,
        40715170006,
        31328176846,
        24105380484,
        18547819465,
        14271569251,
        10981220152,
        8449469985,
        6501421703,
        5002501251
    ];    

    // Stage modifier
    modifier atStage(Stages _stage) {
        require(current_stage == _stage);
        _;
    }

    // Owner modifier
    modifier isOwner() {
        require(msg.sender == owner_address);
        _;
    }

    // Constructor
    function DutchAuction(uint _priceStart) public {
        // Input parameters validation
        require(_priceStart > 0);

        // Set auction owner address
        owner_address = msg.sender;

        // Set auction parameters
        price_start = _priceStart;
        price_final = _priceStart;

        // Update auction stage and fire event
        current_stage = Stages.AuctionDeployed;
        AuctionDeployed(_priceStart);
    }

    // Default function
    function () public payable atStage(Stages.AuctionStarted) {
        placeBid();
    }

    // Setup auction
    function setupAuction(address _tokenAddress, uint offering, uint bonus) public isOwner atStage(Stages.AuctionDeployed) {
        // Initialize external contract type
        require(_tokenAddress != 0x0);        
        token = ShopToken(_tokenAddress);
        uint balance = token.balanceOf(address(this));

        // Verify & Initialize starting parameters
        require(balance == offering.add(bonus));        
        initial_offering = offering;
        last_bonus = bonus;

        // Update auction stage and fire event
        current_stage = Stages.AuctionSetup;
        AuctionSetup();
    }

    // Starts auction
    function startAuction() public isOwner atStage(Stages.AuctionSetup) {
        // Update auction stage and fire event
        current_stage = Stages.AuctionStarted;
        start_time = block.timestamp;
        AuctionStarted();
    }

    // Place bid
    function placeBid() public payable atStage(Stages.AuctionStarted) returns (bool) {
        // Allow only a single bid per address
        require(!bids[msg.sender].placed);

        // Declare local variables
        uint currentDays = getDays();
        uint currentPrice = getPrice();

        // Automatically end auction if date limit exceeded
        if (currentDays > duration) {       
            endImmediately(price_final, Endings.TimeLimit);
            return false;
        }

        // Check if value of received bids equals or exceeds the implied value of all tokens
        uint totalValue = currentPrice.mul(initial_offering);
        uint canAcceptWei = totalValue.sub(received_wei);
        if (msg.value > canAcceptWei) {
            // Place last bid with oversubscription bonus
            uint acceptedWei = canAcceptWei.add(currentPrice.mul(last_bonus));
            if (msg.value <= acceptedWei) {
                // Place bid with all available value
                placeBidInner(msg.sender, currentPrice, msg.value); 
            } else {
                // Place bid with available value
                placeBidInner(msg.sender, currentPrice, acceptedWei);

                // Refund remaining value
                uint returnedWei = msg.value.sub(acceptedWei);
                BidPartiallyRefunded(msg.sender, returnedWei);
                msg.sender.transfer(returnedWei);
            }

            // End auction
            endImmediately(currentPrice, Endings.SoldOutBonus);
        } else if (msg.value == canAcceptWei) {
            // Place last bid && end auction
            placeBidInner(msg.sender, currentPrice, canAcceptWei);
            endImmediately(currentPrice, Endings.SoldOut);
        } else {
            // Place bid and update last price
            placeBidInner(msg.sender, currentPrice, msg.value);

            if (currentPrice < price_final) {
                price_final = currentPrice;
            }            
        }

        return true;
    }

    // End auction
    function endAuction() public isOwner atStage(Stages.AuctionStarted) {
        // Update auction states and fire event
        uint price = getPrice();
        endImmediately(price, Endings.Manual);
    }

    // View tokens to be received during claim period
    function viewTokensToReceive() public atStage(Stages.AuctionEnded) view returns (uint) {
        // Throw if no bid exists
        require(bids[msg.sender].placed);

        uint tokenCount = bids[msg.sender].transfer.div(price_final);
        return tokenCount;
    }

    // Returns days passed
    function getDays() public atStage(Stages.AuctionStarted) view returns (uint) {
        return block.timestamp.sub(start_time).div(86400);
    }

    // Returns current price
    function getPrice() public atStage(Stages.AuctionStarted) view returns (uint) {
        uint _day = getDays();
        if (_day > 29) {
            _day = 29;
        }

        return price_start.mul(rates[_day]).div(precision);
    }

    // Private function to place bid and fire event
    function placeBidInner(address sender, uint price, uint value) private atStage(Stages.AuctionStarted) {
        // Create and save bid
        Bid memory lastBid = Bid({price: price, transfer: value, placed: true});
        bids[sender] = lastBid;

        // Fire event
        BidReceived(sender, price, value);

        // Update received wei value
        received_wei = received_wei.add(value);
    }

    // Private function to end auction
    function endImmediately(uint atPrice, Endings ending) private atStage(Stages.AuctionStarted) {
        price_final = atPrice;
        current_stage = Stages.AuctionEnded;
        AuctionEnded(price_final, ending);        
    }
}