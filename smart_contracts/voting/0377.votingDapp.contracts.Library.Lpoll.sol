pragma solidity ^0.5.1;

import "../Storage.sol";

library Lpoll {
    function callVoterExist(address _storageContract, string memory voterHash) public view returns (bool)
    {
        return  Store(_storageContract).voterExist(voterHash);
    }
    
    function callAddVoter(address _storageContract, string memory voterHash) public
    {
        Store(_storageContract).addVoter(voterHash); 
    }
} 