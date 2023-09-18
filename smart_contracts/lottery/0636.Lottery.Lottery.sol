pragma solidity ^0.8.18;
// SPDX-License-Identifier: MIT

contract Lottery {

    // players struct
    struct Person {
        uint personId;
        address addr;
        uint remainingTokens;
    }

    // items struct
    struct Item {
        uint itemId;
        uint[] itemTokens;
    }
    
    enum Stage {Init, Reg, Bid, Done} // execution stages
    Stage internal stage; // Stage variavle for the execution stages
    uint lotteries = 1; // lotteries count
    mapping(address => Person) tokenDetails; // mapping for players addresses
    Person [] internal bidders; // table of players
    Item [] internal items; // table of items
    address[] internal winners; // table of winners
    address internal beneficiary; // smart contract owner
    uint bidderCount = 0; // bidders count
    event Winner(address winnerAddr, uint itemId, uint lotteriesCount); // winner event to record winner's address, item's ID, and lottery count

    //constructor
    constructor(uint itemsNumber) payable{
        beneficiary = msg.sender;
        uint[] memory emptyArray;
        for (uint m = 0; m < itemsNumber; m++){
            items.push(Item({itemId:m, itemTokens:emptyArray}));
            winners.push(address(0)); 
        }
        stage = Stage.Init;
    }

    //modifier to check payment amount
    modifier hasMoney {
        require(msg.value >= 0.005 ether,"Not enough ethers");
        _;
    }

    //modifier to check remaining tokens
    modifier hasTokens(uint _count) {
        require(tokenDetails[msg.sender].remainingTokens >= _count, "Not enough tokens");
        _;
    }

    //modifier to check item's ID
    modifier isValid(uint _itemId) {
        bool flag = false;
        for (uint id = 0; id < items.length; id++) { 
            if(items[id].itemId == _itemId){
                flag = true;
            }
        }
        require(flag == true, "There is no item with this ID");
        _;
    }

    //modifier to check only-owner access
    modifier onlyOwner {
        require(msg.sender == beneficiary, "You are not the owner");
        _;
    }

    //function to check if a player have already registered
    function isRegistered() internal view returns (bool){
        bool flag = false;
        for (uint i = 0; i < bidderCount; i++){
            if(bidders[i].addr == msg.sender ){
                flag = true;
            }
        } 
        return flag;
    }

    //function for new player registration
    function register() public payable hasMoney{
        require(stage == Stage.Reg,"Not in reg stage");
        require(msg.sender != beneficiary,"You are the beneficiary");
        bidders.push(Person({personId:bidderCount, addr:msg.sender, remainingTokens:5}));
        require(!isRegistered(), "You have already registered");
        tokenDetails[msg.sender] = bidders[bidderCount];
        bidderCount++;
    }

    // function to bid _count tokens to _itemId item 
    function bid (uint _itemId, uint _count) public payable isValid(_itemId) hasTokens(_count){ 
        require(stage == Stage.Bid,"Not in bid stage");
        for (uint y = 0; y < _count; y++) {
            items[_itemId].itemTokens.push(tokenDetails[msg.sender].personId);
            tokenDetails[msg.sender].remainingTokens--;
        }
    }

    //random number generator function
    function generateRandomNumber(uint256 min, uint256 max) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender))) % (max - min + 1) + min;
        return random;
    }

    //function to reveal winner 
    function revealWinners() public payable onlyOwner {
        require(stage == Stage.Done,"Not in done stage");
        uint temp = 0;
        uint lgth = items.length;
        for (uint id = 0; id<lgth; id++) {
            if(items[id].itemTokens.length > 0 && winners[id] == address(0)){
                temp = generateRandomNumber(0, items[id].itemTokens.length-1);
                winners[id] = (findAddress(items[id].itemTokens[temp]));
                emit Winner(winners[id], id, lotteries);
            }
        }
    }

    //function to find address using player's id
    function findAddress(uint id) internal view returns(address){
        for(uint k =0; k<bidders.length; k++){
            if(bidders[k].personId == id){
                return bidders[k].addr;
            }
        }
        return address(0);
    }

    //function to withdraw ethers from contract's pool
    function withdraw() public payable onlyOwner{
        address payable recipient = payable(beneficiary);
        recipient.transfer(address(this).balance);
    }

    //function to reset lottery 
    function reset(uint numberOfItems) public payable onlyOwner{
        for(uint k =0; k<bidders.length; k++){
            delete tokenDetails[bidders[k].addr];
        }
        lotteries++;
        delete bidders;
        delete items;
        delete winners;
        bidderCount = 0;
        stage = Stage.Init;
        uint[] memory emptyArray;
        for (uint m = 0; m < numberOfItems; m++){
            items.push(Item({itemId:m, itemTokens:emptyArray}));
            winners.push(address(0)); 
        }
    }

    // function to advance state to next stage
    function advanceState() public payable onlyOwner{
        if(stage == Stage.Init){
            stage = Stage.Reg;
        }else if(stage == Stage.Reg){
            stage = Stage.Bid;
        }else if(stage == Stage.Bid){
            stage = Stage.Done;
        }
    }
}
