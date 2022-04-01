pragma solidity ^0.4.17 ;

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        // Get address of sender
        manager = msg.sender;
    }

    function enter() public payable {
     require(msg.value > .01 ether);
     players.push(msg.sender);
     }

    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted {

        //Use modulus operator to determine index of
        //winning player
        uint index = random() % players.length;
        //Transfer ether balance to winner
        players[index].transfer(this.balance);
        //Create new empty players array
        players = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    //Return array of players
    function getPlayers() public view returns (address[]) {
        return players;
    }
}
