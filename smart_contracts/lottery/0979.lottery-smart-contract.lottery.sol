//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

// this contract will deploy the Auction contract

contract AuctionCreator{

    Auction[] public auctions;

    function createAuction() public{

        Auction newAuction = new Auction(payable(msg.sender));

        auctions.push(newAuction); // adding the address of the instance to the dynamic array

    }

}

contract Auction{

    address payable public owner;

    uint public startBlock;

    uint public endBlock;

    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}

    State public auctionState;

    uint public highestBindingBid;

    address payable public highestBidder;

    mapping(address => uint) public bids;

    uint bidIncrement;

    constructor(address payable eoa){

        owner = eoa;

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

    modifier onlyOwner(){

        require(msg.sender == owner);

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

    function min(uint a, uint b) pure internal returns(uint){

        if (a <= b){

            return a;

        }else{

            return b;

        }

    }

    function cancelAuction() public onlyOwner{

        auctionState = State.Canceled;

    }

    function placeBid() public payable notOwner afterStart beforeEnd returns(bool){

        require(auctionState == State.Running);

        require(msg.value > 0.001 ether);

        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]){

            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);

        }else{ // highestBidder is another bidder

             highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);

             highestBidder = payable(msg.sender);

        }

    return true;

    }

    function finalizeAuction() public{

       require(auctionState == State.Canceled || block.number > endBlock);

       require(msg.sender == owner || bids[msg.sender] > 0);

       address payable recipient;

       uint value;

       if(auctionState == State.Canceled){

           recipient = payable(msg.sender);

           value = bids[msg.sender];

       }else{// auction ended, not canceled

           if(msg.sender == owner){

               recipient = owner;

               value = highestBindingBid;

           }else{

               if (msg.sender == highestBidder){

                   recipient = highestBidder;

                   value = bids[highestBidder] - highestBindingBid;

               }else{

                   recipient = payable(msg.sender);

                   value = bids[msg.sender];

               }

           }

       }

       

       bids[recipient] = 0;

       

       recipient.transfer(value);

     

    }

}