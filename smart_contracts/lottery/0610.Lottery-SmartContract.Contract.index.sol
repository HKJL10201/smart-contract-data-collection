pragma solidity ^0.4.26;
contract Lottery{
    address public manager;
    address[] public users;

    function Lottery() public{
        manager = msg.sender;
    }

    function enterEvent() public payable{
        require(msg.value > 0.1 ether);
        users.push(msg.sender);
    }

    function pickRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, now, users)));
    }

    function pickWinner() public restricted{
        uint index = pickRandomNumber() % users.length;
        users[index].transfer(this.balance);
        users =  new address[](0);
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns(address[]){
        return users;
    }
}