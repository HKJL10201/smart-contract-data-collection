pragma solidity ^0.6.0;

contract lottery {
    address public manager;
    address payable[] public participants;
    address public winner;

    constructor () public {
        manager = msg.sender;
    }

    function enterLottery() public payable {
        require(msg.value >= 0.1 ether,"Not enough Ethers to Enter in Lottery");
        participants.push(msg.sender);
    }

    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, participants)));
    }

     function pickWinner() public  {
         require(msg.sender == manager, "Only Owner can Pick Winner");

        uint index = random() % participants.length;

        // the entitre balance of this contract to the winner.
        participants[index].transfer(address(this).balance);
        // set winner
        winner = participants[index];
        // clear players and start over.
        participants = new address payable[](0);
    }
}