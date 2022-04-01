pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    address public winner;

    function Lottery() public //constructor
    {
        manager = msg.sender; //msg global variable
    }

    function enter() public payable {
        require(msg.value > 0.01 ether); //global require function, ether would be automatically converted to wei
        players.push(msg.sender);
    }

    modifier admin() //function modifier, to reduce the amount of code that we'll write; think of this as a macro
    {
        require(msg.sender == manager);
        _;
    }

    function pickWinner()
        public
        admin //modifier inclusion comes before returns() and after access specifier
    {
        uint256 index = random() % players.length;
        address winnerAddress = players[index];
        winner = players[index];
        winnerAddress.transfer(this.balance); //this is reference to instance of current contract
        players = new address[](0); //creates a dynamic array of type address, (0) => initial size of 0
    }

    function random() private view returns (uint256) {
        //block global variable
        //now - current time
        return uint256(keccak256(block.difficulty, now, players));
        //sha3() - global function, keccak256() is same as sha3, sha3 is an instance of keccak
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}
