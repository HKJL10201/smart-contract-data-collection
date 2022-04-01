pragma solidity ^0.4.24;

contract Lottery{
    address public manager;
    address[] public players;

    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable{
        require(msg.value > .01 ether, "Send more than .01 ether please!");
        players.push(msg.sender);
    }

    function pickWinner() public restricted{
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    }

    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function getPlayers() public view returns (address[]){
        return players;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    // function modifier
    modifier restricted(){
        require(msg.sender == manager, "Only owner of contract allows to call.");
        _;
    }
}