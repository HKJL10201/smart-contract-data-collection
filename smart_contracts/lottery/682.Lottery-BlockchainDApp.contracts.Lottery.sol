pragma solidity ^0.4.19;

contract Lottery{
    address private manager;
    address[] private participants;

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether);
        participants.push(msg.sender);
    }

    function getParticipant(uint _index) public view returns (address){
        return participants[_index];
    }

    function pickWinner() public returns (address){
        uint index = winnerIndex();
        address winner =  participants[index];
        winner.transfer(this.balance);
        participants = new address[](0);
        return winner;
    }

    function winnerIndex() private view returns (uint){
        uint index = uint(keccak256(block.difficulty, now, participants)) % participants.length;
        return index;
    }

}
