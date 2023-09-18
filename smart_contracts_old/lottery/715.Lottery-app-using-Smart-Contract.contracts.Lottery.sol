contract Lottery {
    address public owner;
    address payable[] players;

    constructor() {
        owner = msg.sender;
    }

    function entry() public payable {
        require(msg.value >= 1 ether);
        players.push(payable(msg.sender));
    }

    function random() public view returns (uint256) {
        // return
        uint256 initialNumber;
        return
            uint256(keccak256(abi.encodePacked(initialNumber++))) %
            players.length;
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             block.timestamp,
        //             block.difficulty,
        //             msg.sender
        //         )
        //     )
        // ) % players.length;
    }

    function playersList() public view returns (address payable[] memory) {
        return players;
    }

    function winner() public {
        uint256 winnerIndex = random();
        address payable winner = players[winnerIndex];
        winner.transfer(address(this).balance);
        players = new address payable[](0);
    }

    modifier onlyForOwner() {
        require(msg.sender == owner);
        _; ///Function body place holder rest of
        ///the code will exucate by replaceing "_;" here
    }
}
