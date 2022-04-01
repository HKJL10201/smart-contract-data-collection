pragma solidity ^0.4.17;

contract Lottery {
    // address data type with public access
    // access is public for front-end
    address public manager;
    address[] public players;

    function Lottery() public{
        // whenever we create a contract
        // we receive the sender's address
        manager = msg.sender;
    }

    // payable keyword is for funcs that send
    // ether 
    function enter() public payable {
        // require a transaction of .01 eth
        // to enter lottery
        require(msg.value > .01 ether);

        // send along some amount of ETH
        players.push(msg.sender);
    }

    function random() private view returns (uint256) {
        // pseudo random number generator
        return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted {
        // require that only manager can
        // use this function
        // send ETH to winner's address
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        // empty player list for next round
        players = new address[](0);
    }

    modifier restricted() {
        // function modifier that only 
        // allows the manager to use
        // the function
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        // returns lists of players
        return players;
    }

}