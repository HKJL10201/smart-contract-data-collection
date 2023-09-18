pragma solidity ^0.4.17;
contract Auction {

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
    
    uint bidderCount=0;

    function Auction() public payable{    

	beneficiary = msg.sender;
        uint[] memory emptyArray;
        items[0] = Item({itemId:0,itemTokens:emptyArray});
        items[1] = Item({itemId:1,itemTokens:emptyArray});
        items[2] = Item({itemId:2,itemTokens:emptyArray});
    }
    

    function register() public payable{
        
        
        bidders[bidderCount].personId = bidderCount;
	      bidders[bidderCount].addr = msg.sender;
        
        bidders[bidderCount].remainingTokens = 5; // only 5 tokens
        tokenDetails[msg.sender]=bidders[bidderCount];
        bidderCount++;
    }
    
    function bid(uint _itemId, uint _count) public payable{
    	if(_itemId > 2) { revert(); }
	    if(tokenDetails[msg.sender].remainingTokens == 0 || tokenDetails[msg.sender].remainingTokens < _count) { revert(); }
        uint balance=tokenDetails[msg.sender].remainingTokens - _count;
        tokenDetails[msg.sender].remainingTokens=balance;
        bidders[tokenDetails[msg.sender].personId].remainingTokens=balance;
        
        Item storage bidItem = items[_itemId];
        for(uint i=0; i<_count;i++) {
            bidItem.itemTokens.push(tokenDetails[msg.sender].personId);    
        }
    }

    modifier onlyOwner {
        require(msg.sender == beneficiary);
        _;
    }
    
    
    function revealWinners() public onlyOwner{

        for (uint id = 0; id < 3; id++) {
            Item storage currentItem=items[id];
            if(currentItem.itemTokens.length != 0){
              uint randomIndex = (block.number / currentItem.itemTokens.length)% currentItem.itemTokens.length; 
              uint winnerId = currentItem.itemTokens[randomIndex];
              winners[id] = bidders[winnerId].addr;           
            }
        }
    } 

    function getPersonDetails(uint id) public constant returns(uint,uint,address){
        return (bidders[id].remainingTokens,bidders[id].personId,bidders[id].addr);
    }

}
