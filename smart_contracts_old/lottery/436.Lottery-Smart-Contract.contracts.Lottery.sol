pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    // int public money;
    function Lottery() public {
        manager = msg.sender;
    }

    //since we expect the player to send some ether to enter into the lotterr, we need to mark this function as payable

    function enter() public payable {
        //checking if the player has sent more than .01 ether to enter into the lottery or not
        //require function is used for validation, if the function returns false, the entire fn exited & no changes r made to the contract
        require(msg.value > .0001 ether);
        players.push(msg.sender);
    }

    //there is no way in solidity to generate a random number
    //so we are trying to generate a "psudo random number" by using sha3 hashing algo and passing in it the block difficulty,
    //current time and the addresses of players. SInce sha3 function returns hash, we r type casting it to uint
    function random() private view returns (uint256) {
        return uint256(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted {
        uint256 winnerIndex = random() % players.length;
        players[winnerIndex].transfer(this.balance);
        //after picking a winner we want our lottery to restart, hence emptying the players array
        //allocating players to empty dynamic array with initial size 0, initial size is mention inside parenthesis (0)
        players = new address[](0);
    }

    //we use modifiers in order to have an early validation logic, we have used this in pickWinner fn, since only manager is allowed to call that fn

    modifier restricted() {
        //checking if the one who is calling this fn is manager or not
        //since as per our logic, only manager should be able to call pickWinner fn
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}
