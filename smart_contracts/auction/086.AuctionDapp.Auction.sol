// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0; 
contract Auction {
    
    // declare the data types to be used
    struct Item {
        uint8 itemId; // id of the item
        uint8 itemToken; // current token for this item.
        int8 personId;  // the id of the person who offers the highest bid.
        string itemInfos; // info of the item
    }
    struct Person {
        uint8 personId; // the id of the person
        uint8 tokens; // the current tokens hold by the person
        address personAddress; // address of this person
    }
    enum AuctionState {beforeStart, Started, End}
    
    // declare variables to be used
    Item[] private items;
    Person[] private persons; 
    mapping (address => uint8) addressToPersonId;
    
    AuctionState public auctionState;
    uint8 public numberofPerson;
    uint8 public numberofItem;
    address public beneficiary_address;
    

    
    constructor() {
        beneficiary_address  = msg.sender;
        numberofPerson = 0;
    }
    
    modifier onlyBeneficiary{
        // only beneficiary can call the function
        require(msg.sender == beneficiary_address);
        _;
    }
    
    modifier beforeStart {
        // only call the function at the beforeStart state
        require(auctionState == AuctionState.beforeStart, "the state of auction is not beforeStart");
        _;
    }
    
    modifier onlyStarted {
        // only call the function at the started state
        require(auctionState == AuctionState.Started, "the sate of auction is not started");
        _;
    }
    
    function registerPerson(address _address, uint8 tokens) public beforeStart onlyBeneficiary{
        persons.push(Person(numberofPerson, tokens, _address));
        addressToPersonId[_address] = numberofPerson;
        numberofPerson = numberofPerson + 1;
    }
    
    function registerItem(string memory itemInfo) public beforeStart onlyBeneficiary{
        items.push(Item(numberofItem, 0, -1, itemInfo));
        numberofItem = numberofItem + 1;
    }
    
    function startAuction() public beforeStart onlyBeneficiary{
        require(auctionState == AuctionState.beforeStart, "the state of auction is not beforeStart");
        auctionState = AuctionState.Started;
    }
    
    function bid(uint8 tokens, uint8 itemId) public onlyStarted{
        
        require(msg.sender == persons[addressToPersonId[msg.sender]].personAddress, "person is not registered");
        require(itemId < numberofItem && itemId >= 0, "invalid itemId");
        require(persons[addressToPersonId[msg.sender]].tokens > tokens, "no enough token");
        require(items[itemId].itemToken < tokens, "bidding less the the highest offer");
        
        uint8 tmp_amount;
        // change the state of previous person
        if (items[itemId].personId != -1){
            tmp_amount = persons[uint8(items[itemId].personId)].tokens  + items[itemId].itemToken;
            persons[uint8(items[itemId].personId)].tokens = tmp_amount;
        }
        // change the state of item
        items[itemId].itemToken = tokens;
        items[itemId].personId = int8(persons[addressToPersonId[msg.sender]].personId);
        
        // change the state of the person
        tmp_amount = persons[addressToPersonId[msg.sender]].tokens - tokens;
        persons[addressToPersonId[msg.sender]].tokens = tmp_amount;
    }
    
    function stopAuction() public onlyStarted onlyBeneficiary{
        auctionState = AuctionState.End;
    }
    
    function addTokens(address _address, uint8 tokens) public onlyBeneficiary{
        require(auctionState != AuctionState.End, "the auction is already end");
        
        // be careful. Whether _address is registered is not checked. Make sure
        // you add tokens to the _address that is registered.
        
        uint8 amount = persons[addressToPersonId[_address]].tokens + tokens;
        persons[addressToPersonId[_address]].tokens = amount;
    }
    
    function showItem(uint8 itemId) public view returns(uint8, int8, string memory){
        return (items[itemId].itemToken, items[itemId].personId, items[itemId].itemInfos);
    }
    
    function showPerson(uint personId) public view returns(uint8, address) {
        return (persons[personId].tokens, persons[personId].personAddress);
    }
}