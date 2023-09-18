// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract lottery{
    address public manager ;
    address payable[] public players;

    constructor(){
        manager = msg.sender;

    }

    function alreadyEntered() view private returns (bool){
        for(uint i = 0 ; i<players.length;i++){
            if(players[i]==msg.sender)
            return  true;
        }
        return false;


    }

    function enter() payable  public {
        require(msg.sender!=manager,"Manager cannot enter" ); //check manager is not allowed
        require(alreadyEntered()== false,"Player already entered"); // check player
        require(msg.value >=1 ether,"Minimum must be payed");
        players.push(payable(msg.sender));  
    }

    function randonumber() view private returns(uint) { // random number 
         return uint(sha256(abi.encodePacked(block.difficulty,block.number,players)));
    }

    function pickWinner() public{ // winner picker function 
        require(msg.sender == manager,"only manager can pick the winner");
        uint index = randonumber()%players.length;// winner index         
        address contractAddress = address(this); 
        players[index].transfer(contractAddress.balance);
        players = new address payable[](0); 

        
    }

    function getplayers() view public returns (address payable[] memory ){

        return players;
        
    }


    

}   

