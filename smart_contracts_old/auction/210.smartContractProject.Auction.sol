pragma solidity ^0.4.17;
contract Auction {
    
    // Data
    //Structure to hold details of the item
    struct Item {
        uint itemId; // id of the item
        uint[] itemTokens;  //tokens bid in favor of the item
       
    }
    
   //Structure to hold the details of a persons
    struct Person {
        uint remainingTokens; // tokens remaining with bidder
        uint personId; // it serves as tokenId as well
        address addr;//address of the bidder
    }
 
    mapping(address => Person) tokenDetails; //address to person 
    Person [4] bidders;//Array containing 4 person objects
    
    Item [3] public items;//Array containing 3 item objects
    address[3] public winners;//Array for address of winners
    address public beneficiary;//owner of the smart contract
    
    uint bidderCount=0;//counter
    
    //functions

    function Auction() public payable {    //constructor
        beneficiary = msg.sender;
        uint[] memory emptyArray;
        items[0] = Item({itemId:0,itemTokens:emptyArray});
        items[1] = Item({itemId:1,itemTokens:emptyArray});
        items[2] = Item({itemId:2,itemTokens:emptyArray});
    }
    

    function register() public payable {
        bidders[bidderCount].personId = bidderCount;
        bidders[bidderCount].addr = msg.sender;
        bidders[bidderCount].remainingTokens = 5; // a constant amount of tokens for the sake of practice
        
        tokenDetails[msg.sender]=bidders[bidderCount];
        bidderCount++;
    }
    
    function bid(uint _itemId, uint _count) public payable {
        /*
            Bids tokens to a particular item.
            Arguments:
            _itemId -- uint, id of the item
            _count -- uint, count of tokens to bid for the item
        */

        if (tokenDetails[msg.sender].remainingTokens < _count) { revert(); }
        if (tokenDetails[msg.sender].remainingTokens == 0) { revert(); }
        if (_itemId > 2) { revert(); }
        
        uint balance = tokenDetails[msg.sender].remainingTokens - _count;
        
        tokenDetails[msg.sender].remainingTokens = balance;
        //then we update the same balance in bidders map.
        bidders[tokenDetails[msg.sender].personId].remainingTokens = balance;
        
        Item storage bidItem = items[_itemId];
        for(uint i=0; i<_count;i++) {
            bidItem.itemTokens.push(tokenDetails[msg.sender].personId);    
        }
    }
    
    // Part 2 Task 1. Create a modifier named "onlyOwner" to ensure that only owner is allowed to reveal winners
    //Hint : Use require to validate if "msg.sender" is equal to the "beneficiary".
    modifier onlyOwner {
        require( beneficiary == msg.sender);
        _;
    }
    
    
    function revealWinners() public onlyOwner{
        
        /* 
            Iterate over all the items present in the auction.
            If at least on person has placed a bid, randomly select          the winner */

        for (uint id = 0; id < 3; id++) {
            Item storage currentItem=items[id];
            if(currentItem.itemTokens.length != 0){
                // generate random# from block number 
                uint randomIndex = (block.number / currentItem.itemTokens.length)% currentItem.itemTokens.length; 
                // Obtain the winning tokenId
                uint winnerId = currentItem.itemTokens[randomIndex];
                // Assigning the winners
                winners[id] = bidders[winnerId].addr;                    
            }
        }
    } 

  //Miscellaneous methods: Below methods are used to assist Grading. Please DONOT CHANGE THEM.
    function getPersonDetails(uint id) public constant returns(uint,uint,address){
        return (bidders[id].remainingTokens,bidders[id].personId,bidders[id].addr);
    }

}
