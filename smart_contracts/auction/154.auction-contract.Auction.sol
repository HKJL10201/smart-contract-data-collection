// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

// contract creator is used to indirectly create the auction contract.
// for scalability and security. mulitple users can create the auction.
contract AuctionCreator {
    Auction[] public auctions;

    function createAuction() public {
        // instance of Auction contract
        //Auction newAuction = new Auction(); //will return the contract address not the EOA address(owner)
        // so pass the msg.sender address to Auction contract
        Auction newAuction = new Auction(msg.sender);
        
        //save the contract address in array.
        auctions.push(newAuction);
    }
}

contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    // user defined type enum, no need of ';' at end.
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    // highest binding bid is the bid value the winner will pay, 
    // which is the sum of second highest bid + bidIncrement
    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    // constructor() { //normal contract call
        constructor(address eoa) { // if created through contract creator, address is sent from contract creator.

        // who deployed the contract is owner.
        //owner = payable(msg.sender); //normal contract call
        // if created through contract creator, address is sent from contract creator.
        owner = payable(eoa); 

        auctionState = State.Running;
        // block.number is global variable similar to msg. It returns the block number
        startBlock = block.number;
        //auction is valid for only 7 days and will end.
        // 7 days has 604,800(60 x 60 x 24 x 7) seconds.
        // ethereum takes 15 sec to create single block. So ( 604,800 / 15 ) = 40320 blocks.
        endBlock = startBlock + 40320; 

        ipfsHash = "";
        // bid will increment by 100 wei of previous bid.
        bidIncrement = 100;
    }

    // modifiers: used for code reuseability.
    // not the owner
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // returns the minimum value
    // pure: it doesn't alter the blockchain nor read from the blockchain
    function min(uint a , uint b) pure internal returns(uint) {
        if(a < b) {
            return a;
        } else {
            return b;
        }
    }

    function placeBid() public payable notOwner afterStart beforeEnd{
        // check if auction state is running
        require(auctionState == State.Running);
        // must pay more than 100 wei
        require(msg.value >= 100);

        // current bid is his sum of previous bid and his bid value
        uint currentBid = bids[msg.sender] + msg.value;
        // current bid must be more than highest binding bid
        require(currentBid > highestBindingBid);
        bids[msg.sender] = currentBid;

        // if current bid is less than highest bidder value
        if(currentBid <= bids[highestBidder]) {
            // highest binding bid is minimum of (currentBid + bidIncrement) and highest bider.
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }

    }

    function cancelBid() public onlyOwner{
        auctionState = State.Canceled;
    }

    // for security every bidder has to call this function to get money back.
    function finalizeAuction() public {
        // auction must be ended to finalize
        require(auctionState == State.Canceled || block.number > endBlock);
        // must be a owner or bidder
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled) { //if auction is cancelled
            // all bidder will get their money back
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else { //auction ended
                if(msg.sender == owner){ //for owner
                    recipient = payable(owner);
                    value = highestBindingBid; //will get highest binding bid
                } else { // for bidders
                        if(msg.sender == highestBidder) { //highest bidder
                            recipient = highestBidder;
                            value = bids[highestBidder] - highestBindingBid; //will get remaining from highest binding bid
                        } else { //neither the owner nor the highest bidder
                            recipient = payable(msg.sender);
                            value = bids[msg.sender]; //will get his bid amount
                        }
                }

        }

        // transfer the amount to recipient
        recipient.transfer(value);

        // but recipient can call fianlize func many times, so reset the amount
        bids[recipient] = 0;

    }
}