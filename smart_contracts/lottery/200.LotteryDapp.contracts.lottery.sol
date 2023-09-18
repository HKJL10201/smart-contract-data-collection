pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    // address[] public empty;

    function Lottery() public {
        manager = msg.sender; //manager address and send ether from selected account
    }

    function enter() public payable {
        require(msg.value > 0.01 ether); //conditions check
        players.push(msg.sender); //player address
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(block.difficulty, now, players)); //make a hash(difficulty, now, players)
    }

    function pickWinner() public restricated {
        uint256 index = random() % players.length; //modulus
        players[index].transfer(address(this).balance);//this is the instant of currnet contrat and balance is the currnet balance in account
        //   players = empty;

        players = new address[](0); // players array will be empty
    }

    modifier restricated() {
        //use of modifier
        require(msg.sender == manager);
        _; //indicated the all code will run after run first line of this function
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}
