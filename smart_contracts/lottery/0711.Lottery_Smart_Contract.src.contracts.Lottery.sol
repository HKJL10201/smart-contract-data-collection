pragma solidity >=0.5.0 <0.9.0;

contract Lottery {

    address payable[] public players; // A dynamic array of Ethereum addresses participating in the lottery.
    address public manager;
    address payable public winner;

    constructor() public {
        manager = msg.sender;
    }

    // This receive function will be automatically called when someone sends ether to our contract address.
    function addPlayer() public payable {
        require(msg.value >= 0.1 ether);
        players.push(msg.sender);
    }

    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager);
        return address(this).balance; // Return the contract balance.
    }

    // Now we need to calculate a random number, which will be used to select the winner of the lottery
    // (more on that later). But unlike many other programming languages solidity
    // doesn't have an in-built function for it. Therefore we need to write our own function for this.
    function random() public view returns(uint256) { // We want our function to return a large random number.
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
        // In Solidity version 0.5.0 the keccak256 function takes only one argument, but in previous versions
        // it could take more. Keep that in mind!
    }

    function selectWinner() public {
        require(msg.sender == manager);
        require(players.length >= 3);
        uint r = random();
        winner = players[(r % players.length)];
    }

    function transferMoneyToWinner() public {
        require(msg.sender == manager);
        winner.transfer(address(this).balance);
        players = new address payable[](0);

    }




}
