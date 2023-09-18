pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    address[] public winners;

    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        // ensure some ether value is included with the fn call.
        require(msg.value >= .001 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        // pseudo-random as all elements of hash can be figured out.
        return uint(keccak256(block.difficulty, now, players));
    }
    
    modifier restricted() {
        // takes fn that we've modified with 'restricted', runs it in place of '_;'
        // allows application of DRY.
        require(msg.sender == manager);
        _;
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        // transfers all eth currently held in contract to the address held at the 
        // winner's index in players array
        players[index].transfer(this.balance);
        winners.push(players[index]);
        resetLottery();
    }
    
    function resetLottery() public {
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}

