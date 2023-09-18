pragma solidity 0.5.16;

contract Lottery{
    address public manager;
    address payable[] public players;
    address payable public winner;
    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);
       
        players.push(msg.sender);
    }

    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,now,players)));
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        winner =  players[index];
        players = new address payable[](0); //resets the contract for further use
    }

    function getPlayers() public view returns (address payable[] memory){
        return players;
    }

}