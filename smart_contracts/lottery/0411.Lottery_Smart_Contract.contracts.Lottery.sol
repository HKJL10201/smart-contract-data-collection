// SPDX-License-Identifier: UNLICENSED

// msg is a global variable to describe who just sent in a function indication
// msg.data     'data' field from tx
// msg.gas      amount of gas the current fn has available
// msg.sender   address of account that started fn call
// msg.value    amount if eth(in wei) that was sent along with the function call

// array in solidity is a reference type
// reference types

pragma solidity ^0.8.17;

contract Lottery {
    address public manager;
    // creates a dynamic array of only addresses
    address payable[] public players;

    // updates manager variable to the wallet of the contract creator
    constructor() {
        manager = msg.sender;
    }

    // enter into lottery by sending in some amount of ether
    // when we expect ether to be sent into fn, we use payable
    // when someone calls enter fn, we take their address and add it to the address array
    function enter() public payable {
        // require is used for validation, if false, fn is exited and no changes are made
        // basically saying require the wallet entering the lottery to send > x ether
        require(
            msg.value > 0.00001 ether,
            "A minimum of 0.00001 ETH is required to enter the lottery"
        );
        // msg.sender has the type 'address' instead of 'address payable' so we must convert it into
        // address payable before adding to array
        players.push(payable(msg.sender));
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.number, players)
                )
            );
    }

    function pickWinner() public restricted {
        // stores index of winner int the array
        uint256 index = random() % players.length;
        // must use this to find the contract
        address contractAddress = address(this);
        // 0xabc17631d transfers all of the balance entered into the lottery and send it to that address
        players[index].transfer(contractAddress.balance);
        // resets the player address array so we can run the lottery once pickWinner is ran
        // creates dynamic array with initial size of 0
        players = new address payable[](0);
    }

    // enforces that nobody can call pickWinner except person who originally called contract
    // modifiers are meant to reduce code we write
    // names can be anything
    modifier restricted() {
        require(msg.sender == manager);
        // like a target
        // imagine the underscore being like take out the fn from the called fn and placing it where _ is
        _;
    }

    // returns a list of aall players
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
