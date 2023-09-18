// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract auction{
uint public highestbindingbid;
mapping(address=>uint) public bids;
address public highestbidder;

enum state{
    open,closed,running
}
string public ipfshash;
uint bidincrement;
state public auctionstate;
address public owner;
uint public startblock;
uint public endblock;
constructor(){
startblock=block.number;
endblock=startblock+40320;
owner=msg.sender;
bidincrement=10;
ipfshash="";
auctionstate=state.running;
}

modifier notowner()
{
require (msg.sender!=owner);
_;

}
modifier afterstart(){
    require(block.number>=startblock);
    _;
}
function min(uint a,uint b) pure internal returns(uint){
    if(a<b){
        return a;
    }
    else{
        return b;
    }
}
modifier beforeend(){
    require(block.number<=endblock);
    _;
}
function balance() public view returns (uint){
return(address(this).balance);
}
function bid() public payable beforeend afterstart notowner returns(bool){
require (auctionstate==state.running);
uint currentbid=bids[msg.sender]+msg.value;
require (currentbid>highestbindingbid);
bids[msg.sender]=currentbid;
if (currentbid<=bids[highestbidder]){
    highestbindingbid=min(currentbid+bidincrement,bids[highestbidder]);
}else{
    highestbindingbid=min(currentbid,bids[highestbidder]+bidincrement);
  highestbidder=msg.sender;
}
return true;

}
modifier onlyowner(){
    require(msg.sender==owner);
    _;
}
function cancelAuction() public onlyowner{
    auctionstate=state.closed;
}
function finalize() public  payable{
require (auctionstate==state.closed || block.number>endblock);
require(msg.sender==owner || bids[msg.sender]>0);
address payable recepient;
uint value;
if (auctionstate==state.closed){
    recepient=payable(msg.sender);
    value=bids[msg.sender];

}else{
    if(msg.sender==owner){
        recepient=payable(owner);
        value=highestbindingbid;
    }
    else{
        if(msg.sender==highestbidder){
            recepient=payable(highestbidder);
            value=bids[highestbidder]-highestbindingbid;
        }
        else{
            recepient=payable(msg.sender);
            value=bids[msg.sender];
        }
    }
}

recepient.transfer(value);
}

}