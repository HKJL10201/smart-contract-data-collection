// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Auction{
    address payable public owner;//The address which deploys the contract
    /*Auction require both starting and ending time in solidity setting time is tricky
    block timestamps are set by miners so its not a recommended pratice to use the 
    global function block.timestamp instead we must calculate time based on the block
    number*/
    uint public startBlock;
    uint public endBlock;
    //We will also have description like images and all we will save all that on IPFS as storing
    //Storing it on blockchain can be very expensive
    string public ipfsHash;
    
    enum State {Started,Running,Ended,Cancelled}
    State public auctionState;

    uint public highestBindingBit;
    address payable public highestBidder;

    //We declare an mapping variable called bids that will store the address and the value sent
    mapping(address => uint) public bids;

    uint bidIncerement;

    //The contract will automatically bid upto to given amount in steos of the increment
    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;//block.number is the current block
        endBlock = startBlock + 40320;//40320 is the number of seconds/15 in a week so that is the end time
        ipfsHash = "";
        bidIncerement = 100;
    }

    //A function modifier to specify not Owner
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    //A function modifier for aunction to run between the start and the end blocks
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

    //In solidity we in general dont have a min function
    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }
    }

    //We need to create function so that the users can place a bid
    function placeBid() public payable notOwner afterStart beforeEnd{
        require(auctionState == State.Running);//This ensure the auction is in running state
        require(msg.value >= 100); 

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBit);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBit = min(currentBid+bidIncerement,bids[highestBidder]);
        }else{
            highestBindingBit = min(currentBid,bids[highestBidder]+bidIncerement);
            highestBidder = payable(msg.sender);
        }
    }
    //Now we need to see how to cancel the auction,Only the owner can call this function to cancel the function
    function cancelAuction() public onlyOwner{
        auctionState = State.Cancelled;
    }

    /*If the auction is over or it is cancelled by the owner and now the users want their funds back 
    The better way is we dont proactively send back the funds to the users that didnt win the auction
    It is preffed to use the "Withdrawl pattern
    We must send ETH only to the users only if he actually requests for it we can avoid a lot of vulnerabilites
    using this*/
    function finalizeAuction() public{
        require(auctionState == State.Cancelled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);
        //The abhove means that the address who wants to finliaze the account is the owner or an bidder
        
        //Find the address that will receive the funds 
        address payable recepient;
        uint value;

        if(auctionState == State.Cancelled){
            //This is when auction is canceled and every bidder gets its money
            recepient = payable(msg.sender);
            value = bids[msg.sender];//This is the value the bidder has already sent in the auction
        }else{
            //This is when auction is ended
            if(msg.sender == owner){
                recepient = owner;
                value = highestBindingBit;
            }else{
                //This is a bidder
                if(msg.sender == highestBidder){
                    recepient = highestBidder;
                    value = bids[highestBidder]-highestBindingBit;
                }else{
                    //This is neither the owner not the winner its just one of the bidders
                    recepient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        //Before transfering the funds to the recepient we need to reset the bids of th recepient to zero
        //Or else it will create a large vulnearbilty where the bidder able to get refund more than once
        bids[recepient] = 0;//He wont be a bidder anymore
        recepient.transfer(value);
    }


}

