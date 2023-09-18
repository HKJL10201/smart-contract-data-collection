pragma solidity ^0.4.26;

contract Lottery {
    address public manager;
    address public lastWinner;
    address [] public players;
    

    constructor () public {
        manager = msg.sender;

    }

    //create random number
    function random() private view returns (uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    function winner() public restricted {

        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        lastWinner = players[index];
        players = new address[](0);
    }

    function checkEntries() public view returns (address []){
        return players;
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    


}