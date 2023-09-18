//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

contract creater{

    address public owner;
    auction[] public deployedAuctions;

    constructor(){
        owner = msg.sender;
    }

    function deployAuction() public {
        auction new_Auction = new auction(msg.sender);
        deployedAuctions.push(new_Auction);
    }
}


contract auction{

        address payable public owner;
        uint public startblock;
        uint public endblock;
        uint public currentblock = block.number;
        string public ipfshash;

        enum State{started, running,ended,canceled}
        State public Auctionstate ;

        mapping(address => uint) public bids;
        

        address payable public highestbidder ;
        uint public highestbindingbid;


        uint  bidincrement;

        constructor(address EOA){
            owner = payable(EOA);
            Auctionstate = State.running;
            startblock = block.number;
            endblock = startblock + 4 ; //for 8 hours
            ipfshash = "";
            bidincrement = 0.01 ether;
            

        }

        modifier auctionstart( ){
            require(block.number  >= startblock);
            _;
        }

        modifier auctionend(){
            require(block.number <= endblock);
            _;
        }

        modifier auctionrunning(){
            require(Auctionstate == State.running);
            _;
        }

        modifier notOwner(){
            require(msg.sender != owner,"owner cant bid");
            _;
        }

        modifier onlyOwner(){
            require(msg.sender == owner);
            _;
        }

        function min(uint a, uint b) internal pure returns(uint ){
            if(a > b){
                return a;
            }else{
                return b;
            }
        }

        function cancelauction() public  onlyOwner{
            Auctionstate = State.canceled ;
        }


        function bid() public payable notOwner auctionstart auctionend auctionrunning{
            require(msg.value > 0.02 ether,"not enough price");

            uint currentbid = bids[msg.sender] + msg.value;
            require(currentbid > bids[highestbidder]);

            bids[msg.sender] = currentbid;

            if(currentbid < bids[highestbidder]){
                highestbindingbid = min(currentbid + bidincrement , bids[highestbidder]);
            }else{
                highestbindingbid = min(currentbid, bids[highestbidder] + bidincrement);
                highestbidder = payable(msg.sender);
            }
            currentblock = block.number;

        }

        function status() internal  {
            if(Auctionstate == State.canceled){
                Auctionstate = State.canceled ;
            }else{
               Auctionstate = State.running;
                
            }
        }


        function paymentsettle() public {
            require(Auctionstate == State.canceled || block.number > endblock);
            uint value;
            address payable recepient ;


            if(Auctionstate == State.canceled){
                recepient = payable(msg.sender);
                value = bids[msg.sender];

            }else{
                if(msg.sender == owner){
                    recepient = payable(msg.sender);
                    value = highestbindingbid;
                }else {
                    if(msg.sender == highestbidder){
                    recepient = payable(msg.sender);
                    value = bids[highestbidder] - highestbindingbid ;
                   }else{
                    recepient = payable(msg.sender);
                    value = bids[msg.sender];
                   }
                }
            }

                if(block.number >= endblock) {
                Auctionstate = State.ended;

                }else{
                    Auctionstate = State.running;
                }



            recepient.transfer(value);
            
            bids[msg.sender] = 0 ;

        }
      
}
