pragma solidity ^0.8.7;

contract Lottery{
    address payable [] public players;
    address payable public manager;

    constructor(){
        manager =payable(msg.sender);
    }

//reciving function
    receive() external payable{
        require(msg.value == 0.1 ether);
        //require(msg.sender != manager);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function random()public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function pickWinner()public{
        //require(msg.sender == manager);///
        require(players.length >= 3);
        
        uint r = random();
        uint index = r%players.length;

        address payable winner = players[index];
        
        uint managerCommission = (getBalance() * 10)/100;
        uint winnerPrize = (getBalance() * 90)/100;

        payable(manager).transfer(managerCommission);

        winner.transfer(winnerPrize);

        players = new address payable[](0);
    }
}