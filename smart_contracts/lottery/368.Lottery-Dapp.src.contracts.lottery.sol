// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

contract Lottery{
    address payable[] public players;
    address payable public manager;
    uint playerIndex;
    event PlayerAdded(uint playerNumber, address playerAddress);
    event WinnerPicked(address winner);

    constructor(){
        playerIndex = 1;
        manager = payable(msg.sender);
        players.push(manager);
        playerIndex++;
    }

    receive() external payable{
        require(msg.sender != manager, "Manger cannot join lottery");
        require(msg.value == 0.1 ether);
        
        players.push(payable(msg.sender));
        emit PlayerAdded(playerIndex, msg.sender);
        playerIndex++;
    }
    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 3);

        uint r = random();
        address payable winner;

        uint winnersPrize = (getBalance() * 90) / 100;
        uint managerFee = (getBalance() * 10) / 100;

        uint index = r % players.length;
        winner = players[index];
        manager.transfer(managerFee);
        winner.transfer(winnersPrize);
        emit WinnerPicked(winner);
        players = new address payable[](0);// resetting the lottery
    }
}