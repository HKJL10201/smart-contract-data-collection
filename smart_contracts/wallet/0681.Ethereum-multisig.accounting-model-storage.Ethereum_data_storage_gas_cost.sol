pragma solidity 0.8.2;
pragma abicoder v2;
// Storage design


// first contract stores struct only in a mapping
contract StoreStruct01{
    
    // struct that needs to be stored
    struct Entity{
        uint data;
        address adrs;
    }
    
    mapping (address => Entity) public EntMap;
    
    function addEntity(address address_, uint data_) public {
        Entity memory newEntity = Entity(data_, address_);
        EntMap[address_] = newEntity;
    }
    
}

//second contract stores struct only in an array
contract StoreStruct02{
    
    // struct to be stored
    struct Entity{
        uint data;
        address adrs;
    }
    
    Entity[] public EntArr;
    
    function addEntity(address address_, uint data_) public {
        Entity memory newEntity = Entity(data_, address_);
        EntArr.push(newEntity);
    }
    
}


// Check the gas costs in the logs
