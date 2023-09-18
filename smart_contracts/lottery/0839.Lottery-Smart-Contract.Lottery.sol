pragma solidity ^0.8.0;

contract Lottery{
    address public owner;
    address payable [] public players;
    address payable public winner;

    constructor() public{
        owner = msg.sender;
    }

    modifier Owneronly{
        if(msg.sender == owner){
            _;
        }
    }
    
    function deposit() public payable{
        require(msg.value >= 1 ether);
        players.push(payable(msg.sender));
    }

    function RandomNumber() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,block.number)));
    }

    function pickWinner() Owneronly public{
        uint randomnumber = RandomNumber();
        uint index = randomnumber % players.length;

        winner = players[index];
        winner.transfer(address(this).balance);

        players = new address payable [](0);
          
    }

    
}