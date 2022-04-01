//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address public manager; // owner
    address payable[] public participants; // these ppl will send money to this contract to get registered to lottery

    constructor() {
        manager = msg.sender; // setting manager as the owner of this contract
    }

    receive() external payable {
        // to recieve funds
        require(msg.value == 1 ether); // participant should send 1 ether for the transaction to be valid, else revert
        participants.push(payable(msg.sender)); // adding the address in participants array, which sent ether to this contract
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager); // this function (getBalance) can only we called my the manager
        return address(this).balance; // getting balance of this address (the cintract)
    }

    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participants.length
                    )
                )
            ); // this gives a very large random number
    }

    function selectWinner() public payable {
        require(msg.sender == manager); // this function (selectWinner) can only we called my the manager
        require(participants.length >= 3); // there should be atleast 3 valid participants to run this function

        uint256 r = random(); // using above defined function to get a random value
        uint256 index = r % participants.length; // so that index lies in range of 0-participant.length

        address payable winner = participants[index]; // address of winner who will get ethers

        winner.transfer(getBalance()); // transfer the entire balance from contract address to winner address

        participants = new address payable[](0); // reseting the participants array
    }
}
