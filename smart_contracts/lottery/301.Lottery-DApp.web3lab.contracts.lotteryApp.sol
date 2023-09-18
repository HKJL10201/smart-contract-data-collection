// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract lotteryApp {
    //   1. A manager address
    address public manager;
    //   2. Participants address
    address payable[] public participants;
    address payable public winner;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(
            msg.value == 0.0001 ether,
            "Need to pay 0.0001 ether to participate in the lottery"
        );
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager, "You are not the manager");
        return address(this).balance;
    }

    function randomNumberGenerator() private view returns (uint256) {
        uint256 timestamp = block.timestamp;
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        timestamp,
                        participants.length
                    )
                )
            );
    }

    function getParticipantLength() public view returns (uint256) {
        require(msg.sender == manager, "You are not the manager");
        return participants.length;
    }

    function allParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    function luckyWinner() public {
        require(msg.sender == manager, "You are not the manager");
        //   4. start lottery (min 3 lottery)
        require(
            participants.length >= 3,
            "At least 3 person needed to start a lottery"
        );
        uint256 rand = randomNumberGenerator();

        uint256 index = rand % getParticipantLength();
        winner = participants[index];
        //   3.  Send lottery fee to Manager
        winner.transfer(getBalance());

        // Need to revert the transaction
        participants = new address payable[](0);
    }
}

//    Deploying 'lotteryApp'
//    ----------------------
//    > transaction hash:    0xa767348175e481ae026682319030fba19d12458c6e392bc059aee83c1b878b36
//    > Blocks: 1            Seconds: 8
//    > contract address:    0x344c7D718534Bcec6677aD499A282EfeB041E6B2
//    > block number:        8622418
//    > block timestamp:     1678334724
//    > account:             0x026D2c1e816a206f45A9919D75564f303B6D1DD9
//    > balance:             0.267928244047637065
//    > gas used:            781275 (0xbebdb)
//    > gas price:           10.185440139 gwei
//    > value sent:          0 ETH
//    > total cost:          0.007957629744597225 ETH
