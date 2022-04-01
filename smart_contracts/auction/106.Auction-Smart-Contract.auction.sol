//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

//Creation of infinite number of contracts assigning the owner of the Auction to the eoa that called createAuction()
contract AuctionCreator{
    Auction[] public auctions;

    function createAuction() public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

//Base Auction contract
contract Auction{

    address payable public owner;
    uint public startBlock; 
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Cancelled}
    State public auctionState; 

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids; //the keys are the addresses of the bidders, and the corresponding values are the amounts they have sent.
    uint bidIncrement;

    constructor(address eoa){
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number; 
        endBlock = startBlock + 3; 
        ipfsHash = "";
        bidIncrement = 1000000000000000000;
    }


    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }


    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function cancelAuction() public onlyOwner(){
        auctionState = State.Cancelled;
    }

    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }

     }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 100);
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement , bids[highestBidder]);
        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuction() public{
        require(auctionState == State.Cancelled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0); //only the owner or a bidder, can finalize the auction 

        address payable recipient; 
        uint value;

        if(auctionState == State.Cancelled){ //auction was cancelled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else{ //auction ended (not cancelled) 
            if(msg.sender == owner){ //this is the owner 
                recipient = owner;
                value = highestBindingBid;
            }else{ //this is a bidder
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{ //this is neither the owner nor the highestBidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];

                }       
             }
         }
        //resetting the bids of the recipient to zero 
        bids[recipient] = 0; 

        //sends value to the recipient 
        recipient.transfer(value);
     }
}
