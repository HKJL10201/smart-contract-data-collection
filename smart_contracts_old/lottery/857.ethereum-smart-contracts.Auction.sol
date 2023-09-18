//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

contract AuctionCreator{

    Auction[] public auctions;

    //create new instance of auctions contracts
    function createAuction() public{

        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction{

    //owner of auction
    address payable public owner;

    //start block of auction
    uint public startBlock;

    //end block of auction
    uint public endBlock;

    string public ipfsHash;

    //enum to define the states of auction
    enum State {Started, Running, Ended, Cancelled}

    //store auction state
    State public auctionState;

    //store highest binding bid
    uint public highestBindingBid;

    //store highest bidder
    address payable public highestBidder;

    //mapping of accounts to bids
    mapping(address => uint) public bids;

    uint bidIncrement;


    constructor(address eoa){

        owner = payable(eoa);

        auctionState = State.Running;

        startBlock = block.number;

        //in a week 40320 blocks are generated
        //endBlock = startBlock + 40320

        //for testing
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

    //get the minimum of two numbers
    function min(uint a, uint b) pure internal returns(uint){

        if(a <= b){

            return a;
        }
        else{

            return b;
        }
    }

    //cancel the auction
    function cancelAuction() public onlyOwner{

        //change the state of auction to cancelled
        auctionState = State.Cancelled;


    }

    //place a bid
    function placeBid() public payable notOwner afterStart beforeEnd{

        //check the state of auction is running
        require(auctionState == State.Running);
        //value sent should be greater than 100 wei
        require(msg.value >= 100);

        //calculate the current bid of address
        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestBindingBid);

        //store the current bid of address
        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){

            //highestBindingBid = minimum(total bid by user + bidIncrement, highestBid)
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }

        else{

            highestBindingBid = min(currentBid, bids[highestBidder] +  bidIncrement);

             //highestBindingBid = minimum(total bid by user ,bidIncrement, highestBid + bidIncrement)
            highestBidder = payable(msg.sender);
        }
        
    }

    //finalise the auction
    function finalizeAuction() public {

        //check if auction has ended
        require(auctionState == State.Cancelled || block.number > endBlock);

        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;

        uint value;

        //auction cancelled
        if(auctionState == State.Cancelled){

            recipient = payable(msg.sender);

            //get the amount bidded by sender
            value = bids[msg.sender];


        //auction ended not cancelled
        }else{

            //this is the owner
            if(msg.sender == owner){


                recipient = owner;

                //get highest binding bid
                value = highestBindingBid;
            }

            //this is a bidder
            else {
             
              if(msg.sender == highestBidder){

                  recipient = highestBidder;
                  value = bids[highestBidder] - highestBindingBid;
              }
              
              //neither owner nor highestBidder
              else{

                recipient = payable(msg.sender);
                value = bids[msg.sender];

              }

            }

        }

       //resetting the bids of the recipient as zero
        bids[recipient] = 0;

        recipient.transfer(value);


    }
}