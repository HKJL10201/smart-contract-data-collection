// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Lottery
{
    address public manager ;
    address[] public players; 

    constructor () {
        manager = msg.sender;
    }

     fallback() external payable
    {
        require(msg.value>0.01 ether,"insufficient balance");
        players.push(msg.sender);
        
    } 

    function showBalance() external view returns (uint ){
        return (address(this).balance);
    }
    
    function random() internal view returns (uint256){
        uint x;
        return uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,x)));
    }


    function luckydraw() public {
     require(manager==msg.sender,"not authorised to perform operation");

        uint index = random()%players.length;
        address payable lucky = payable (players[index]);
        lucky.transfer(address(this).balance);
    }
}