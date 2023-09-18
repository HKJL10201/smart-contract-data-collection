pragma solidity 0.6.0;

contract Auction {
    
    struct Item {
        
        uint itemId;
        uint[] itemToken;
        
    }
    
    struct Person{
       uint remainingToken;
       uint personId;
       address addr;
    }
    
    mapping(address => Person) tokenDetail;
    Person[4] bidders;
    
    Item[3] public items;
    address[3] public winners;
    address public beneficiary;
    
    uint bidderCount = 0;
    
    constructor()  public payable {
        
        beneficiary = msg.sender;
        uint[] memory emptyArray;
        items[0] = Item({  itemId:0,itemToken:emptyArray  });
        items[1] = Item({  itemId:1,itemToken:emptyArray  });
        items[2] = Item({  itemId:2,itemToken:emptyArray  });
        
    }
    
    function register() public payable {
        
        bidders[bidderCount].personId = bidderCount;
        bidders[bidderCount].addr = msg.sender;
        
        bidders[bidderCount].remainingToken = 5;
        
        tokenDetail[msg.sender]  = bidders[bidderCount];
        bidderCount++;
    }
    
    function bid(uint _itemId, uint _count ) public payable{
        
        if(tokenDetail[msg.sender].remainingToken < _count){ revert();}
        if(tokenDetail[msg.sender].remainingToken  == 0 ){ revert();}
        if(_itemId > 2){revert();}
        
        tokenDetail[msg.sender].remainingToken -= _count;
        
        bidders[tokenDetail[msg.sender].personId].remainingToken = tokenDetail[msg.sender].remainingToken;
        Item storage bidItem = items[_itemId];
        
        for(uint i = 0; i<_count; i++ ){
            
            bidItem.itemToken.push(tokenDetail[msg.sender].personId);
        }
    
    }
    
    function revealWinner() public view{
        
        for(uint id = 0; id<3; id++){
            Item storage currentItem = items[id];
            if(currentItem.itemToken.length != 0){
                uint randomIndex = (block.number/ currentItem.itemToken.length) % currentItem.itemToken.length;
                uint winnerId = currentItem.itemToken[randomIndex];
                address winner = bidders[winnerId].addr;
            }
            
        }
    }
    
    function getPersonDetails(uint id) public view  returns(uint, uint, address){
    
      return (bidders[id].remainingToken, bidders[id].personId, bidders[id].addr);
}

}
