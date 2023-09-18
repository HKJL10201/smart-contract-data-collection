// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

//Goerli contractAddress = 0x8b6eEA13e5092073AfE2B04edDB68f3A13567324

//Ganache contractAddress = 0xe461DEf9CDEE12e5E9603dA806E1D1906ef236f4

contract Lottery {
    address payable[] public players;
    address manager;
    address payable public winner;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 1 ether, "Please pay 1 ether only");
        players.push(payable(msg.sender));
    }

    function balance() public view returns (uint256) {
        //to get the balance of the contract
        require(msg.sender == manager, "You are not the manager");
        return (address(this).balance);
    }

    function random() internal view returns (uint256) {
        //generating random to pick the winner randomly
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function pickWinner() public {
        require(msg.sender == manager, "You are not the manager");
        require(players.length >= 3, "Players are < 3");

        uint256 random_ = random();
        uint256 index = random_ % players.length; //remainder is always < players.length

        winner = players[index];
        winner.transfer(balance()); //transfering ethers to the winner

        players = new address payable[](0); //making the array empty
    }

    function allPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
