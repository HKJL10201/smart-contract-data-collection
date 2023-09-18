pragma solidity ^0.5.1;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
contract Store is Ownable{
    
   mapping(string=>uint) private voterList;
    
     address private factoryAddress;
     
     function setFactoryAddress (address _factory) public onlyOwner {
         factoryAddress = _factory;
     }
     function addVoter(string memory voter) public {
         require(msg.sender==factoryAddress);
        voterList[voter]++;
    }
    
     function voterExist(string memory voter) public view returns(bool) {
        if(voterList[voter]>0)
            return true;
        else
            return false;
    }
}