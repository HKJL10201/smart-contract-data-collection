//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{

    address payable[] public lot_1_players;
    address payable[] public lot_2_players;
    address public manager;

    constructor(){
        manager = msg.sender;
    }

    receive () payable external{
        require(msg.value == 1 ether || msg.value == 2 ether);
        if(msg.value == 1 ether){
            lot_1_players.push(payable(msg.sender));
        }
        else{
            lot_2_players.push(payable(msg.sender));
        }
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager,"You are not the manager");
        return address(this).balance;
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, 
       (lot_1_players.length+lot_2_players.length))));
    }

    function pickWinner() public{

        require(msg.sender == manager);
        require (lot_1_players.length >= 2 && lot_2_players.length >=2);

        address payable lot_1_winner;
        address payable lot_2_winner;
        uint index1 = random() % lot_1_players.length;
        uint index2 = random() % lot_2_players.length;

        lot_1_winner = lot_1_players[index1];
        lot_2_winner = lot_2_players[index2];

        uint totalBalance = getBalance();
        lot_1_winner.transfer((totalBalance/10)*3);
        lot_2_winner.transfer((totalBalance/10)*7);

        lot_1_players = new address payable[](0);
        lot_2_players = new address payable[](0);
    }
}
