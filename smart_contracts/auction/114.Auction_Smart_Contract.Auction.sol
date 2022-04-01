//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

// this contract will deploy the Auction contract
contract auctioncreator{

    //This dynamic array will store all the auctions deployed by the function
    Auction[] public auctions;

    //function that will deploy contract Auction:
    function createauction()public{
        Auction newauction=new Auction(msg.sender);
        auctions.push(newauction);
    }
}

contract Auction{

    address payable public owner;
    uint startblock;
    uint endblock;
    string ipfshash;

    uint public highestbindingbid;
    address payable public highestbidder;
    uint public bidincrement;

    enum state{started,running,ended,canceled}
    state public auctionstate;
    mapping (address=>uint) public bids;

    constructor(address eoa){
        owner=payable(eoa);
        startblock=block.number;
        endblock=startblock+40320;
        ipfshash="";
        bidincrement=1000000000000000000;
        auctionstate=state.running;
    }

    modifier notowner(){
        require(msg.sender!=owner);
        _;
    }

    modifier afterstart(){
        require(block.number>startblock);
        _;
    }

    modifier beforeend(){
        require(block.number<endblock);
        _;
    }

    modifier onlyowner(){
        require(msg.sender==owner);
        _;
    }

    function min(uint a,uint b)pure internal returns(uint){
        if(a<b){
            return a;
        }
        else{
            return b;
        }
    }

    //function to place a bid:
    function placebid()public payable notowner afterstart beforeend{
        require(auctionstate==state.running);
        require(msg.value>=1 ether);

        uint currentbid=bids[msg.sender]+msg.value;
        require(currentbid>highestbindingbid);
        bids[msg.sender]=currentbid;

        if(currentbid<=bids[highestbidder]){
            highestbindingbid=min(currentbid+bidincrement,bids[highestbidder]);
        }
        else{
            highestbindingbid=min(currentbid,bids[highestbidder]+bidincrement);
            highestbidder=payable(msg.sender);
        }

    }

    // only the owner will able to the Auction
    function cancelauction()public onlyowner{
        auctionstate=state.canceled;
    }

    function finalize()public{
        require(auctionstate==state.canceled || block.number>endblock);
        require(msg.sender==owner || bids[msg.sender]>0);

        uint value;
        address payable recipient;

        if(auctionstate==state.canceled){
            recipient=payable(msg.sender);
            value=bids[msg.sender];
        }

        else{
            if(msg.sender==owner){
                //owner of the auction
                recipient=owner;
                value=highestbindingbid;
            }
            else{
                if(msg.sender==highestbidder){
                    //Highest bidder
                    recipient=highestbidder;
                    value=bids[highestbidder]-highestbindingbid;
                }
                else{
                    //Regular Bidder
                    recipient=payable(msg.sender);
                    value=bids[msg.sender];
                }
            }
        }
        //reseting the bids
        bids[recipient]=0;

        //transfering funds
        recipient.transfer(value);


    } 

}
