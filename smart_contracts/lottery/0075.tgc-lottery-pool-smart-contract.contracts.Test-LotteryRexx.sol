// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

//  $$$$$$\   $$$$$$\  $$$$$$$\
// $$  __$$\ $$  __$$\ $$  __$$\
// $$ /  \__|$$ /  $$ |$$ |  $$ |
// $$ |$$$$\ $$ |  $$ |$$$$$$$  |
// $$ |\_$$ |$$ |  $$ |$$  __$$<
// $$ |  $$ |$$ |  $$ |$$ |  $$ |
// \$$$$$$  | $$$$$$  |$$ |  $$ |
//  \______/  \______/ \__|  \__|

// @title : TGC Lottery Pool Contract
// @desc: A lottery pool contract for the TGC community where the odds are in REXX NFT holders' favor!
// @author: @ricogustavo
// @ig: https://instagram.com/tgcollective777
// @twitter: https://twitter.com/tgcollective777
// @github: https://github.com/the-generation-collective
// @url: https://tgcollective.xyz

interface testContract {
    function balanceOf(address account) external view returns (uint256);
}

contract TestLotteryRexx {
    testContract testOwner;

    uint256 public constant ticketPrice = 1 ether;
    uint256 public constant maxTickets = 10;
    uint256 public constant ticketCommission = 0.01 ether; // commission per ticket - 1% from ticket price
    uint256 public constant duration = 30 minutes; // The duration set for a round of lottery - 1 week

    uint256 public expiration;
    address public lotteryOperator;
    uint256 public operatorTotalCommission = 0;

    struct Winner {
        address winnerAddress;
        uint256 winningsAmount;
    }
    Winner[] public winners;

    struct LastWinner {
        address winnerAddress;
        uint256 winningsAmount;
    }
    LastWinner[] public lastWinners;

    uint8 public positionOnePercentage = 60;
    uint8 public positionTwoPercentage = 25;
    uint8 public positionThreePercentage = 15;

    mapping(address => uint256) public winnings;
    address[] public tickets;

    modifier isOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is not the lottery operator"
        );
        _;
    }

    constructor() {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
        testOwner = testContract(0xc8860Ebad4Bb6a857B5618ec348F71B6E9c23588);
    }

    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddressWithMessage(address _address)
        public
        view
        returns (uint256, string memory)
    {
        if (winnings[_address] > 0) {
            return (
                winnings[_address],
                "Congratulations on finishing podium for this round!"
            );
        } else {
            return (winnings[_address], "Better luck next time!");
        }
    }

    function BuyTickets() public payable {
        require(
            msg.value % ticketPrice == 0,
            "You must send the exact amount of MATIC."
        );
        uint256 numOfTicketsToBuy = msg.value / ticketPrice;

        require(
            numOfTicketsToBuy <= RemainingTickets(),
            "Not enough tickets available."
        );

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }
    }

    function DrawWinnerTicket() public isOperator {
        require(tickets.length > 0, "No tickets were purchased");

        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber1 = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        uint256 randomNumber2 = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, blockHash, randomNumber1)
            )
        );
        uint256 randomNumber3 = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, blockHash, randomNumber2)
            )
        );

        uint256 winningTicket1 = randomNumber1 % tickets.length;
        uint256 winningTicket2 = randomNumber2 % tickets.length;
        uint256 winningTicket3 = randomNumber3 % tickets.length;

        // check if the user who bought the ticket is holding the NFT
        uint256 nftBalance = testOwner.balanceOf(msg.sender);

        if (nftBalance > 0) {
            // increase the odds based on the number of NFTs the user has
            // 1. if the user has 1 to 3 NFT, increase the odds by 2%
            // 2. if the user has 4 to 6 NFT, increase the odds by 6%
            // 3. if the user has 7 NFT, increase the odds by 10%
            if (nftBalance >= 1 && nftBalance <= 3) {
                winningTicket1 =
                    (winningTicket1 + (randomNumber3 % 10) + 2) %
                    tickets.length;
                winningTicket2 =
                    (winningTicket2 + (randomNumber3 % 10) + 2) %
                    tickets.length;
                winningTicket3 =
                    (winningTicket3 + (randomNumber3 % 10) + 2) %
                    tickets.length;
            } else if (nftBalance >= 4 && nftBalance <= 6) {
                winningTicket1 =
                    (winningTicket1 + (randomNumber3 % 10) + 6) %
                    tickets.length;
                winningTicket2 =
                    (winningTicket2 + (randomNumber3 % 10) + 6) %
                    tickets.length;
                winningTicket3 =
                    (winningTicket3 + (randomNumber3 % 10) + 6) %
                    tickets.length;
            } else if (nftBalance == 7) {
                winningTicket1 =
                    (winningTicket1 + (randomNumber3 % 10) + 10) %
                    tickets.length;
                winningTicket2 =
                    (winningTicket2 + (randomNumber3 % 10) + 10) %
                    tickets.length;
                winningTicket3 =
                    (winningTicket3 + (randomNumber3 % 10) + 10) %
                    tickets.length;
            }
        }

        Winner memory winner1;
        winner1.winnerAddress = tickets[winningTicket1];
        winner1.winningsAmount =
            ((tickets.length * (ticketPrice - ticketCommission)) * 60) /
            100;
        winners.push(winner1);

        Winner memory winner2;
        winner2.winnerAddress = tickets[winningTicket2];
        winner2.winningsAmount =
            ((tickets.length * (ticketPrice - ticketCommission)) * 25) /
            100;
        winners.push(winner2);

        Winner memory winner3;
        winner3.winnerAddress = tickets[winningTicket3];
        winner3.winningsAmount =
            ((tickets.length * (ticketPrice - ticketCommission)) * 15) /
            100;
        winners.push(winner3);

        LastWinner memory lastWinner1;
        lastWinner1.winnerAddress = tickets[winningTicket1];
        lastWinner1.winningsAmount =
            ((tickets.length * (ticketPrice - ticketCommission)) * 60) /
            100;
        lastWinners.push(lastWinner1);

        LastWinner memory lastWinner2;
        lastWinner2.winnerAddress = tickets[winningTicket2];
        lastWinner2.winningsAmount =
            ((tickets.length * (ticketPrice - ticketCommission)) * 25) /
            100;
        lastWinners.push(lastWinner2);

        LastWinner memory lastWinner3;
        lastWinner3.winnerAddress = tickets[winningTicket3];
        lastWinner3.winningsAmount =
            ((tickets.length * (ticketPrice - ticketCommission)) * 15) /
            100;
        lastWinners.push(lastWinner3);

        operatorTotalCommission += (tickets.length * ticketCommission);
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function restartDraw() public isOperator {
        require(tickets.length == 0, "Cannot Restart Draw as Draw is in play");

        delete tickets;
        expiration = block.timestamp + duration;
    }

    function getWinningsForWinner(address _winner)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i].winnerAddress == _winner) {
                return winners[i].winningsAmount;
            }
        }
        return 0;
    }

    function checkWinningsAmount() public view returns (uint256) {
        return getWinningsForWinner(msg.sender);
    }

    function WithdrawWinnings() public {
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i].winnerAddress == msg.sender) {
                address payable winner = payable(msg.sender);
                winner.transfer(winners[i].winningsAmount);
                winners[i].winningsAmount = 0;
                break;
            }
        }
        require(
            getWinningsForWinner(msg.sender) == 0,
            "Caller is not a winner or already withdrew winnings"
        );
    }

    function RefundAll() public {
        require(block.timestamp >= expiration, "the lottery not expired yet");

        for (uint256 i = 0; i < winners.length; i++) {
            address payable to = payable(winners[i].winnerAddress);
            to.transfer(winners[i].winningsAmount);
            winners[i].winnerAddress = address(0);
            winners[i].winningsAmount = 0;
        }
        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
    }

    function WithdrawCommission() public isOperator {
        address payable operator = payable(msg.sender);

        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;

        operator.transfer(commission2Transfer);
    }

    function AreWinners() public view returns (bool, string memory) {
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i].winnerAddress == msg.sender) {
                if (i == 0) {
                    return (true, "Congrats! You won the first prize");
                } else if (i == 1) {
                    return (true, "Congrats! You won the second prize");
                } else if (i == 2) {
                    return (true, "Congrats! You won the third prize");
                }
            }
        }
        return (false, "You are not a winner");
    }

    function CurrentWinningRewards() public view returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](3);

        rewards[0] =
            ((tickets.length * (ticketPrice - ticketCommission)) *
                positionOnePercentage) /
            100;

        rewards[1] =
            ((tickets.length * (ticketPrice - ticketCommission)) *
                positionTwoPercentage) /
            100;

        rewards[2] =
            ((tickets.length * (ticketPrice - ticketCommission)) *
                positionThreePercentage) /
            100;

        return rewards;
    }

    function RemainingTickets() public view returns (uint256) {
        return maxTickets - tickets.length;
    }
}
