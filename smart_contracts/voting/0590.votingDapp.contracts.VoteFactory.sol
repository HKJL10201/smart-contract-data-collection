pragma solidity ^0.5.1;


import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Poll.sol";

contract Voterfactory is Ownable {

    using Lpoll for address;
    address private storageContract;    
    Poll [] pollAddList; 
    uint len;
    
    constructor (address _store) public 
    {
        storageContract = _store;
        len=0;
    }
  
    function createPoll(string memory question) public {
        Poll obj = new Poll(question,storageContract);
        pollAddList.push(obj);
        len++;
    }
    
    function addVoter(string memory hash) public onlyOwner {
        storageContract.callAddVoter(hash);    
    }
    
    function getPollAddList(uint index) public view returns(Poll){
        return pollAddList[index];
    }
    
    function getPollSize() public view returns(uint)
    {
        return len;   
    }
    function getStorageContract() public view returns (address)
    {
        return storageContract;
    }
    
    function setStorageContract(address _store) public onlyOwner {
        storageContract = _store;        
    }

}

