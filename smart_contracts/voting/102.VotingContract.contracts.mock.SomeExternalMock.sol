// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "../interfaces/IExternal.sol";

contract SomeExternalMock is IExternal {
    uint256 incrementCount;
    
    function counter() internal {
        incrementCount++;
    }
    
    function viewCounter() public view returns(uint256) {
        return incrementCount;
    }
    
    // function returnFuncSignature() public view returns(string memory) {
    //     //abi.encodePacked(bytes4(keccak256(abi.encodePacked('counter',"()"))));
    //     return "0x61bc221a";
    // }
    
    function getNumber(address addr, uint256 blockNumber) public view returns(uint256 number) {
        bytes32 blockHash = blockhash(blockNumber);
            
        number = (uint256(keccak256(abi.encodePacked(blockHash, addr))) % 1000000);
        
    }
    function getHash(uint256 blockNumber) public view returns(bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
        
        
    }
    
    function vote(VoterData[] calldata voteData, uint256 weight) override external returns(bool success) {
        //counter();
        incrementCount = incrementCount + weight;
        return true;
    }
}
