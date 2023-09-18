pragma solidity ^0.4.17;

contract Lottery {

    address public owner;
    address[] public playersArray;

    function Lottery() public {
        // Initialize owner to the eth address which deployed the contract
        owner = msg.sender;
    }

    function getPlayersArray() public view returns (address[]) {
        return playersArray;
    }

    function getPlayersArrayLength() public view returns (uint256) {
        return playersArray.length;
    }

    function joinLottery() public payable {
        require(msg.value > .01 ether);
        playersArray.push(msg.sender);
    }

    function pickWinner() public restrictedToOwner {
        uint256 index = random() % playersArray.length;

        playersArray[index].transfer(address(this).balance);
        playersArray = new address[](0);
    }



    /* HELPERS & MODIFIERS */

    modifier restrictedToOwner() {
        require(owner == msg.sender);
        _;
    }

    // TODO robust pseudo-random algorithm
    function random() private view returns (uint256) {
        return uint256(keccak256(block.difficulty, block.timestamp, playersArray));
    }
}