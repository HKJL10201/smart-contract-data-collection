pragma solidity 0.8.2;

// The problem with solidity libraries of mappings vs arrays is discussed 
// the issue is if we have a mapping, then is is really easy to access its elements with a key
// however, the problem is that we can not know all the elements of the mapping 
// because there is no loop over mapping keys in solidity
//
// In contrast this is easy to solve using arrays, but
// the drawback is that if we would like to access a particular
// element in the array, we would have to loop over the entire array
// this is more expensive as the array gets bigger
//
// A common solution is to use:
// Mapping with usnortered index and delete

contract MutableMappings{
    
    // create a mappping where its elements are structs
    struct entityStruct{
        uint info;
        uint iPointer; // will bind address to the position of the array in EntsList where, its corresponding address is stored
    }
    
    mapping(address => entityStruct) public Ents;
    address[] public EntsList;
    
    // 
    function isEntity(address address_) public view returns(bool is_Entity){
        if (EntsList.length == 0){return false;}
        return EntsList[Ents[address_].iPointer] == address_;
    }
    
    // get the length of the number of clients registered in the array (EntsList) and mappping (Ents)
    function get_EntsList_len() public view returns(uint len){
        return EntsList.length;
    }
    
    // add new client to the struct (and consequently to EntList array)
    function newEntity(address address_, uint info_) public returns(bool success){
        if (isEntity(address_)){
            revert ();
        }
        Ents[address_].info = info_;
        EntsList.push(address_);
        Ents[address_].iPointer = EntsList.length - 1;
        return true;
    }
    
    // delete by moving the last element and replacing it in the position of the element to be deleted
    function deleteEntity(address address_) public returns(bool success){
        if (!isEntity(address_)){
            revert();
        }
        uint mapping2delete = Ents[address_].iPointer;  // grab the id pointer of the element to be deleted
        address elem2reuse = EntsList[EntsList.length -1]; // grab the last element in the array to be reused
        EntsList[mapping2delete] = elem2reuse;  // replace
        EntsList.pop();                   // pop 
        Ents[elem2reuse].iPointer = mapping2delete;
        delete Ents[address_];
        return true;
    }
}
