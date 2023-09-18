pragma solidity ^0.5.9;

contract Lottery {
    struct Item {
        uint itemId;
        address[] playerTokens;
    }

    //Beneficieries
    address payable public owner;
    address payable public otherOwner;

    //Item list and winners
    Item[3] public items;
    address[3] public winners;

    //True when lottery is finished
    bool public finished;

    constructor() public payable {
        owner = msg.sender;
        otherOwner = address(0x153dfef4355E823dCB0FCc76Efe942BefCa86477);
        for(uint i=0; i<3; i++){
            items[i] = Item({itemId:i, playerTokens: new address[](0)});
        }
        finished = false;
    }

    function bid(uint itemId) public payable minVal notFinished nonOwner {
        items[itemId].playerTokens.push(msg.sender);
    }

    function revealWinners() public notFinished onlyOwners{
        for(uint i=0; i<3; i++){
            if(items[i].playerTokens.length !=0){
                uint rand = random() % items[i].playerTokens.length;
                winners[i] = items[i].playerTokens[rand];
            }
            else {
                winners[i] = address(0); //Could be redundant
            }
        }
        finished = true;
    }

    function withdraw() public payable onlyOwners{
        msg.sender.transfer(address(this).balance);
    }

    function random() view private returns(uint){return uint(keccak256(abi.encodePacked(block.difficulty, now)));}

    //These functions are needed for the Reveal and Am I Winner buttons
    function tokenCounts() public view returns(uint[3] memory){
        uint[3] memory tokens;
        for(uint i=0; i<3; i++){
            tokens[i] = items[i].playerTokens.length;
        }
        return tokens;
    }

    function amIWinner() public view isFinished returns(uint[3] memory){
        uint[3] memory wonItems;
        for(uint i=0; i<3; i++){
            if(winners[i] == msg.sender){
                wonItems[i] = i+1; // 0 coresponds to loss and 1-3 corresponds to item won
            }
            else {
                wonItems[i] = 0;
            }
        }
        return wonItems;
    }

    //Modifiers
    modifier minVal(){
        if(msg.value != 0.01 ether){
            revert();
        }
           _;
    }

    modifier notFinished(){
        if(finished){
            revert();
        }
           _;
    }

    modifier isFinished(){
        if(!(finished)){
            revert();
        }
           _;
     
    }

    modifier onlyOwners(){
        if(!(msg.sender == owner || msg.sender == otherOwner)){
             revert();        
        }
            _;
    }

    modifier nonOwner() {
        if( msg.sender == owner || msg.sender == otherOwner){
            revert();
        }
            _;
    }
}