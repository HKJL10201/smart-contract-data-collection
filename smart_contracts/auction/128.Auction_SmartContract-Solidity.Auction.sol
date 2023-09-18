// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Auction {
    ////////////////////////////////////////////////////////////////////////////////
    /*VARIABLE DECLARATION*/

    address payable private owner;

    address payable[] public bidders;
    mapping(address => uint256) private bids;

    uint256 private highestBindingBid = 0 ether;
    address payable private highestBidder;

    bool private isStarted = false;

    struct BidItem {
        string item;
        uint256 startingPrice;
        uint256 endingPrice;
    }

    BidItem bidItem;

    /*VARIABLE DECLARATION*/
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /*CONSTRUCTOR*/

    //setting owner of the contract
    constructor() {
        owner = payable(msg.sender);
        highestBidder = payable(owner);
        bidItem = BidItem("N/A", 0, 0);
    }

    /*CONSTRUCTOR*/
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /*MODIFIERS*/

    //modifer to check if the caller is the owner
    //used for owner specific questions
    modifier isOwner() {
        require(msg.sender == owner, "You do not have rigths");
        _;
    }

    //modifier to check if the auction has started
    //can only be started by the owner
    modifier isLaunched() {
        require(isStarted, "Bidding has not started yet");
        _;
    }

    //modifier to check if the auction has not already launched
    //can only be started by the owner
    modifier isNotLaunched() {
        require(!isStarted, "Bidding is already underway");
        _;
    }

    //modifier to checek if the caller is not the owner
    //used to restrict the owner from participating in the bid
    modifier isNotOwner() {
        require(msg.sender != owner, "The owner cannot place a bid");
        _;
    }

    /*MODIFIERS*/
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /*GETTER FUNCTIONS*/

    //public function to allow bidders to see how much they need to bid
    //requires that the owner has launched a bid
    function getHighestBid() external view isLaunched returns (uint256) {
        return highestBindingBid;
    }

    //public function to see the item bein bid on
    //requires that the owner has launched a bid
    function getBiddingItemDetails()
        external
        view
        isLaunched
        returns (
            string memory,
            uint256 startingPrice,
            uint256 endingPrice
        )
    {
        return (bidItem.item, bidItem.startingPrice, bidItem.endingPrice);
    }

    //public function to show the current highest bidder
    //requires that the owner has launched a bid
    function getHighestBidder() external view isLaunched returns (address) {
        return highestBidder;
    }

    //public function to show your last bid amount
    //requires that the owner has launched a bid
    function getYourLastBid() external view isLaunched returns (uint256) {
        return bids[msg.sender];
    }

    /*GETTER FUNCTIONS*/
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /*AUCTION FUNCTIONALITY*/

    //function only the owner can use to start a new bid - takes in the new bid details
    //can only be called if there isnt any bid currently taking place
    function startAuction(
        uint256 _initalPrice,
        uint256 _finalPrice,
        string memory _item
    ) external isOwner isNotLaunched {
        //setting bidding details and marking the auction as started
        bidItem.item = _item;
        bidItem.startingPrice = (_initalPrice * 1000000000000000000);
        bidItem.endingPrice = (_finalPrice * 1000000000000000000);
        isStarted = true;

        //setting the initial highest bid to the start price
        highestBindingBid = (_initalPrice * 1000000000000000000);
    }

    //function only the owner cna use to cancel the bid
    //will only be called if there is a bid currently taking place
    //returns all bids to their respective owners
    function cancleAuction() external isOwner isLaunched {
        //returning all bids back to their senders
        address payable returnAddr;
        for (uint256 index = 0; index < bidders.length; index++) {
            returnAddr = bidders[index];
            returnAddr.transfer(bids[returnAddr]);
        }

        //resetting all bids/bidder information
        resetValues();
    }

    //function only called by owner to finalize the current bid
    //returns any excess amount back to the higest bidder
    //checks if no bid has been placed, then does nothing
    //else it transfers the highest bid to the owner
    //returns all other bids to the losing bidders
    //will only be called if there is a bid currently taking place
    function finalizeAuction() external isOwner isLaunched {
        //paying the owner
        if (highestBindingBid != bidItem.startingPrice) {
            if (highestBindingBid > bidItem.endingPrice) {
                uint256 overflow = highestBindingBid - bidItem.endingPrice;
                owner.transfer(highestBindingBid - overflow);
                highestBidder.transfer(overflow);
            } else {
                owner.transfer(highestBindingBid);
            }

            //returning all bids back to their senders
            address payable returnAddr;
            for (uint256 index = 0; index < bidders.length; index++) {
                returnAddr = bidders[index];
                if (returnAddr == highestBidder) {
                    continue;
                } else {
                    returnAddr.transfer(bids[returnAddr]);
                }
            }

            //resetting all bids/bidder information
            resetValues();
        }
    }

    //internal function used to reset the bid/bidding information
    //also resets the bidding item details
    function resetValues() internal {
        isStarted = false;

        //reseting the BidItem Struct
        bidItem.item = "N/A";
        bidItem.startingPrice = 0;
        bidItem.endingPrice = 0;

        //resetting the highest bid value
        highestBidder = payable(address(0));

        //resting the array and the map
        for (uint256 index = 0; index < bidders.length; index++) {
            bids[bidders[index]] = 0;
            delete bidders[index];
        }
    }

    //payable function to place a bid
    //owner cannot place a bid
    //bid can only be placed if it is greater than the previous highest bid
    //allows for one caller to replace a bid ontop of their previous one
    function placeBid() external payable isNotOwner {
        require(
            !(highestBindingBid > bidItem.endingPrice),
            "Binding limit is complete"
        );
        uint256 totalBid = msg.value + bids[msg.sender];
        require(totalBid > highestBindingBid, "Not enough to place bid");
        if (totalBid == msg.value) {
            bidders.push(payable(msg.sender));
        }
        bids[msg.sender] = totalBid;
        highestBindingBid = totalBid;
        highestBidder = payable(msg.sender);
    }

    /*AUCTION FUNCTIONALITY*/
    ////////////////////////////////////////////////////////////////////////////////
}
