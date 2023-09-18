pragma solidity >=0.4.21 <0.7.0;
pragma experimental ABIEncoderV2;

contract Lottery {
    address public manager;
    address payable[] public players;
    address payable public winnerAddress;

    constructor() public {
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Must be a Manager");
        _;
    }

    function register() public payable {
        require(msg.value > 0.1 ether, "Not enough ether provided");
        players.push(msg.sender);
    }

    function chooseWinner() public onlyOwner {
        uint256 index = random() % players.length;
        //Transfer is inbuilt method to transfer money.
        //Balance is contract property to hold current balance/money
        players[index].transfer(address(this).balance);
        winnerAddress = players[index];
        players = new address payable[](0); //reset players address array
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, players)));
    }
}
