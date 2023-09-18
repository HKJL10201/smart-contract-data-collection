// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract Lottery {
    uint ticketNoCounter;
    uint lotteryDeploymentTime = block.timestamp;
    uint lotteryBalance;

    constructor() {
        lotteryDeploymentTime = block.timestamp;
    }

    enum TicketTier {
        Full,
        Half,
        Quarter,
        Invalid
    }

    mapping(address => uint[]) public ticketNosArray;
    mapping(address => uint256) public balance;
    mapping(uint => LotteryInfo) public lotteryInfos;
    mapping(uint => uint) public moneyCollectedForEachLottery;
    mapping(uint => uint) public totalPrizeMoney;
    mapping(uint => Ticket) ticketsFromOutside;

    event TicketBought(uint ticketNo, uint lotteryNo, bytes32 ticketHash, address ticketOwner);

    struct Ticket {
        address owner;
        uint ticketNo;
        uint lotteryNo;
        bytes32 ticketHash;
        uint8 status;
        bool active;
        TicketTier ticketTier;
    }

    struct LotteryInfo {
        uint lotteryNo;
        uint startTimestamp;
        uint[] winningTickets;
        uint[] ticketNosInLottery;
    }

    /// @notice calculates the current lottery number based on the lottery deployment timestamp
    /// @return lotteryNo lottery number
    function lotteryNoCalculator() public view returns (uint) {
        uint currentTime = block.timestamp;
        uint timePassed = currentTime - lotteryDeploymentTime;
        uint lotteryNo = (timePassed / (60 * 60 * 24 * 7)) + 1;
        return lotteryNo;
    }

    /// @notice add money on users account balance
    function depositEther() public payable {
        balance[msg.sender] += msg.value;
    }

    /// @notice substracts the amount of given ether and sends it back und the user
    /// @param amount of ether to be withdrawn
    function withdrawEther(uint amount) public payable {
        require(balance[msg.sender] >= amount, "insufficient balance");
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    /// @notice transfers the left-over money from a certain lottery to the following lottery after the prize amount has been substracted
    /// @param lottery_no actual lottery number
    /// @param  prize prize which will be add to amount of winnable money in that lottery
    function transferAmount(uint lottery_no, uint prize) private {
        require(
            moneyCollectedForEachLottery[lottery_no] >= prize,
            "Lottery is invalid, because there is not enough money in the Lottery for the prizes"
        );
        totalPrizeMoney[lottery_no] += prize;
        uint transferAmnt = moneyCollectedForEachLottery[lottery_no] - prize;
        moneyCollectedForEachLottery[lottery_no + 1] += transferAmnt;
    }

    /// @notice function by which user can buy ticket by his choice, checks tier first and creates a Ticket
    /// @param hash_rnd_number random hash number which is given by the user to buy the ticket
    /// @param tier chosen type of ticket, can be 2 finneys , 4 finneys , 8 finneys
    function buyTicket(bytes32 hash_rnd_number, int tier) public {
        ticketNoCounter += 1;
        uint lottery_no = lotteryNoCalculator();
        TicketTier ticketTier;

        if (tier == 3) {
            require(
                balance[msg.sender] > 2 * (10 ** 15),
                "insufficient balance for quarter ticket"
            );
            ticketTier = TicketTier.Quarter;
        } else if (tier == 2) {
            require(
                balance[msg.sender] > 4 * (10 ** 15),
                "insufficient balance for half ticket"
            );
            ticketTier = TicketTier.Half;
        } else if (tier == 1) {
            require(
                balance[msg.sender] > 8 * (10 ** 15),
                "insufficient balance for full ticket"
            );
            ticketTier = TicketTier.Full;
        }

        if (lottery_no >= 3) {
            if (!(lotteryInfos[lottery_no - 2].winningTickets.length == 3)) {
                pickWinner(lottery_no - 2);
                totalPrizeMoney[lottery_no - 2] = calculateTotalPriceValue(
                    lottery_no - 2
                );
                transferAmount(lottery_no - 2, totalPrizeMoney[lottery_no - 2]);
            }
        }

        ticketsFromOutside[ticketNoCounter].owner = msg.sender;
        ticketsFromOutside[ticketNoCounter].ticketNo = ticketNoCounter;
        ticketsFromOutside[ticketNoCounter].lotteryNo = lottery_no;
        ticketsFromOutside[ticketNoCounter].ticketHash = hash_rnd_number;
        ticketsFromOutside[ticketNoCounter].status = 0;
        ticketsFromOutside[ticketNoCounter].active = true;
        ticketsFromOutside[ticketNoCounter].ticketTier = ticketTier;

        ticketNosArray[msg.sender].push(ticketNoCounter);
        balance[msg.sender] -= getamount(ticketTier);
        lotteryBalance += getamount(ticketTier);
        lotteryInfos[lottery_no].ticketNosInLottery.push(ticketNoCounter);
        moneyCollectedForEachLottery[lottery_no] += getamount(ticketTier);

        emit TicketBought( ticketsFromOutside[ticketNoCounter].ticketNo,ticketsFromOutside[ticketNoCounter].lotteryNo, ticketsFromOutside[ticketNoCounter].ticketHash, ticketsFromOutside[ticketNoCounter].owner);
    }

    /// @notice revealing the number that user provided us at reveal stage
    /// @param ticket_no users ticket number
    /// @param random_number number he used to buy the ticket
    function revealRndNumber(uint ticket_no, uint random_number) public {
        require(
            ticket_no <= ticketNoCounter,
            "There is no ticket with this number in the system"
        );
        require(
            ticketsFromOutside[ticket_no].owner == msg.sender,
            "You are not the owner of this ticket"
        );
        require(
            ticketsFromOutside[ticket_no].lotteryNo ==
                (lotteryNoCalculator() - 1),
            "incorrect time to reveal"
        );
        require(
            ticketsFromOutside[ticket_no].status == 0,
            "Sorry, you have already revealed"
        );
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, random_number));
        if (hash == ticketsFromOutside[ticket_no].ticketHash) {
            ticketsFromOutside[ticket_no].status = 1;
        } else {
            revert("Incorrect number!");
        }
    }

    /// @notice helper function to calculate the buy-price of a ticket given by its tier
    /// @param tier type of ticket (Full, Half, Quarter)
    /// @return amount buy-value of the ticket
    function getamount(TicketTier tier) public pure returns (uint) {
        uint amount;
        if (tier == TicketTier.Full) {
            amount = 8 * (10);
        } else if (tier == TicketTier.Half) {
            amount = 4 * (10);
        } else if (tier == TicketTier.Full) {
            amount = 2 * (10);
        } else {
            amount = 0;
        }
        return amount;
    }

    /// @notice function which enables users to get a ticket refund. Sends back amount to his account and decreases balance of lottery
    /// @param ticket_no number of ticket user wants to withdraw
    function collectTicketRefund(uint ticket_no) public {
        require(
            ticket_no <= ticketNoCounter,
            "There is no ticket with this number in the system"
        );
        require(
            ticketsFromOutside[ticket_no].owner == msg.sender,
            "You are not the owner of this ticket"
        );
        require(
            ticketsFromOutside[ticket_no].lotteryNo == (lotteryNoCalculator()),
            "You cannot refund anymore"
        );
        uint lottery_no = ticketsFromOutside[ticket_no].lotteryNo;
        TicketTier tier = ticketsFromOutside[ticket_no].ticketTier;
        uint amount = getamount(tier);
        balance[msg.sender] += amount;
        moneyCollectedForEachLottery[lottery_no] -= amount;
        lotteryBalance -= amount;
        ticketsFromOutside[ticket_no].active = false;
    }

    /// @notice function which gives user the number of the ticket by a given index and lottery number
    /// @param i th ticket user wants to get
    /// @param lottery_no number of lottery user is referring to
    /// @return ticketNo number of the wanted ticket
    /// @return status status, if the ticket is revealed or not
    function getIthOwnedTicketNo(
        uint i,
        uint lottery_no
    ) public view returns (uint, uint8) {
        require(
            lottery_no <= (lotteryNoCalculator()),
            "Lottery has not started yet"
        );
        require(
            ticketNosArray[msg.sender].length >= i,
            "You don`t have that many tickets"
        );

        uint ticketNo;
        uint8 status;

        for (uint k = 0; k < ticketNosArray[msg.sender].length; k++) {
            
            if (
                ticketsFromOutside[ticketNosArray[msg.sender][k]].lotteryNo ==
                lottery_no
            ) {
                
                   ticketNo= ticketsFromOutside[ticketNosArray[msg.sender][k + i - 1]]
                        .ticketNo;
                    status = ticketsFromOutside[ticketNosArray[msg.sender][k + i - 1]]
                        .status;
                
            }
        }

        return(ticketNo,status);
    }

    /// @notice gives back the last bought ticket`s ticket number and it`s status
    /// @param lottery_no number of lottery user is referring to
    /// @return uint number of the wanted ticket
    /// @return uint8 status, if the ticket is revealed or not
    function getLastOwnedTicketNo(
        uint lottery_no
    ) public view returns (uint, uint8) {
        require(
            ticketNosArray[msg.sender].length > 0,
            "You don`t have any tickets"
        );
        uint lastOwnedTicketNo;

        for (uint i = 0; i < ticketNosArray[msg.sender].length; i++) {
            if (
                ticketsFromOutside[ticketNosArray[msg.sender][i]].lotteryNo >
                lottery_no
            ) {
                lastOwnedTicketNo = ticketNosArray[msg.sender][i - 1];
            }
        }

        return (
            lastOwnedTicketNo,
            ticketsFromOutside[lastOwnedTicketNo].status
        );
    }

    /// @notice picks three random winner tickets of a lottery by the given lottery number. Those winner tickets can be then found
    ///         in WinningTickets Array in which we save the ticket number of the three winners ticket
    /// @param lottery_no number of lottery we are referring to
    function pickWinner(uint lottery_no) private {
        if (lotteryInfos[lottery_no].ticketNosInLottery.length < 3) {
            revert(
                "There is not enough ticket for picking winners, lottery is cancelled!"
            );
        }

        require(
            lotteryNoCalculator() >= lottery_no + 2,
            "You cannot pick the winner for this lottery."
        );

        uint numberofTickets = lotteryInfos[lottery_no]
            .ticketNosInLottery
            .length - 1;

        uint index1 = uint(keccak256(abi.encodePacked(block.timestamp + 1))) %
            (numberofTickets);
        lotteryInfos[lottery_no].winningTickets.push(index1);

        uint index2 = uint(keccak256(abi.encodePacked(block.timestamp + 2))) %
            (numberofTickets);

        while (index1 == index2) {
            uint i = 1;
            index2 =
                uint(keccak256(abi.encodePacked(block.timestamp + 2, i))) %
                (numberofTickets);
            i++;
        }

        lotteryInfos[lottery_no].winningTickets.push(index2);

        uint index3 = uint(keccak256(abi.encodePacked(block.timestamp + 3))) %
            (numberofTickets);

        while (index3 == index1 || index3 == index2) {
            uint i = 0;
            index3 =
                uint(keccak256(abi.encodePacked(block.timestamp + 2, i))) %
                (numberofTickets);
            i++;
        }

        lotteryInfos[lottery_no].winningTickets.push(index3);
        totalPrizeMoney[lottery_no] += calculateTotalPriceValue(lottery_no);
    }

    /// @notice calculates the won price of the th-winning ticket. We determine which winning ticket is referred to and then compute the won prize
    /// on the amount of ether existing in the givin lottery number.
    /// @param thPrice the th-price which`s value we want to calculate
    /// @param lottery_no number of lottery we are referring to
    /// @return uint amount won by the ticket
    function calculateSinglePriceValue(
        uint thPrice,
        uint lottery_no
    ) private returns (uint) {
        // TODO: This can be private
        require(
            thPrice == 1 || thPrice == 2 || thPrice == 3,
            "Invalid price type!"
        );
        require(lottery_no <= lotteryNoCalculator(), "Invalid lottery number!");
        uint prize;

        uint winnerTicketNo = lotteryInfos[lottery_no].ticketNosInLottery[
            lotteryInfos[lottery_no].winningTickets[thPrice - 1]
        ];
        if (thPrice == 1) {
            if (
                ticketsFromOutside[winnerTicketNo].ticketTier == TicketTier.Full
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 2;
            } else if (
                ticketsFromOutside[winnerTicketNo].ticketTier == TicketTier.Half
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 4;
            } else if (
                ticketsFromOutside[winnerTicketNo].ticketTier ==
                TicketTier.Quarter
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 8;
            }
        } else if (thPrice == 2) {
            if (
                ticketsFromOutside[winnerTicketNo].ticketTier == TicketTier.Full
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 4;
            } else if (
                ticketsFromOutside[winnerTicketNo].ticketTier == TicketTier.Half
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 8;
            } else if (
                ticketsFromOutside[winnerTicketNo].ticketTier ==
                TicketTier.Quarter
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 16;
            }
        } else if (thPrice == 3) {
            if (
                ticketsFromOutside[winnerTicketNo].ticketTier == TicketTier.Full
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 8;
            } else if (
                ticketsFromOutside[winnerTicketNo].ticketTier == TicketTier.Half
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 16;
            } else if (
                ticketsFromOutside[winnerTicketNo].ticketTier ==
                TicketTier.Quarter
            ) {
                prize = moneyCollectedForEachLottery[lottery_no] / 32;
            }
        } else {
            prize = 0;
        }
        return (prize);
    }

    /// @notice this function calculates the total value of the winners tickets in a specifiv lottery
    /// @param lottery_no number of lottery we are referring to
    /// @return uint amount won by the ticket
    function calculateTotalPriceValue(uint lottery_no) private returns (uint) {
        uint firstprice = calculateSinglePriceValue(1, lottery_no);
        uint secondprice = calculateSinglePriceValue(2, lottery_no);
        uint thirdprice = calculateSinglePriceValue(3, lottery_no);
        uint totalpricevalue = firstprice + secondprice + thirdprice;
        return totalpricevalue;
    }

    /// @notice this function finds the i-th winning ticket in a given lottery. By using findTicketInfosFromNo function
    /// information about the ticket can be easily found
    /// @param i i-th ticket index
    /// @param lottery_no number of lottery we are referring to
    /// @return ticket_no number of the i-th won ticket
    /// @return amount amount of money won by the ticket
    function getIthWinningTicket(
        uint i,
        uint lottery_no
    ) public returns (uint ticket_no, uint amount) {
        require(
            lottery_no <= (lotteryNoCalculator()),
            "Lottery you are requesting has not started yet!"
        );

        require(lotteryNoCalculator() >= 3, "You cannot pick winner!");
        require(
            lotteryNoCalculator() >= lottery_no + 2,
            "Too early to collect ticket prize!"
        );

        if (!(lotteryInfos[lottery_no].winningTickets.length == 3)) {
            pickWinner(lottery_no);
            totalPrizeMoney[lottery_no] = calculateTotalPriceValue(lottery_no);
            transferAmount(lottery_no, totalPrizeMoney[lottery_no]);
        }
        require(
            i == 1 || i == 2 || i == 3,
            "Invalid number of winning ticket!"
        );
        uint ticket_index = lotteryInfos[lottery_no].winningTickets[i - 1];
        ticket_no = lotteryInfos[lottery_no].ticketNosInLottery[ticket_index];

        (, ticket_index) = findTicketInfosFromNo(ticket_no);
        amount = calculateSinglePriceValue(i, lottery_no);
        return (ticket_no, amount);
    }

    /// @notice checks if a ticket given by it`s ticket number and the lottery number is a winning ticket. Since we safe the winning ticket in a specific
    ///         array (winningTickets[]), we can easily compare the ticket numbers
    /// @param lottery_no number of lottery we are referring to
    /// @param ticket_no number of ticket we are referring to
    /// @return prize amount of money won by the ticket if it is a winning ticket, zero if not
    function checkIfTicketWon(
        uint lottery_no,
        uint ticket_no
    ) public returns (uint) {
        require(lotteryNoCalculator() >= 3, "You cannot pick winner!");
        require(
            ticket_no <= ticketNoCounter,
            "The ticket you are requesting does not exist"
        );
        require(
            ticketsFromOutside[ticket_no].owner == msg.sender,
            "You are not the owner!"
        );
        require(
            ticketsFromOutside[ticket_no].status == 1,
            "You have not revealed the random number yet!"
        );
        require(
            lotteryNoCalculator() >= lottery_no + 2,
            "Too early to collect ticket prize!"
        );
        if (!(lotteryInfos[lottery_no].winningTickets.length == 3)) {
            pickWinner(lottery_no);
            totalPrizeMoney[lottery_no] = calculateTotalPriceValue(lottery_no);
            transferAmount(lottery_no, totalPrizeMoney[lottery_no]);
        }

        uint prize;
        bool boolean;
        uint firstPrizeWinnerTicketNo = lotteryInfos[lottery_no]
            .ticketNosInLottery[lotteryInfos[lottery_no].winningTickets[0]];
        uint secondPrizeWinnerTicketNo = lotteryInfos[lottery_no]
            .ticketNosInLottery[lotteryInfos[lottery_no].winningTickets[1]];
        uint thirdPrizeWinnerTicketNo = lotteryInfos[lottery_no]
            .ticketNosInLottery[lotteryInfos[lottery_no].winningTickets[2]];
        if (ticket_no == firstPrizeWinnerTicketNo) {
            prize = calculateSinglePriceValue(1, lottery_no);
            boolean = true;
        } else if (ticket_no == secondPrizeWinnerTicketNo) {
            prize = calculateSinglePriceValue(2, lottery_no);
            boolean = true;
        } else if (ticket_no == thirdPrizeWinnerTicketNo) {
            prize = calculateSinglePriceValue(3, lottery_no);
            boolean = true;
        } else {
            boolean = false;
            prize = 0;
        }

        return prize;
    }

    /// @notice function which gives user the number of the ticket by a given index and lottery number
    /// @param ticket_no ticket number
    /// @return lotteryNo lottery number
    /// @return index of the ticket in ticketNosArray
    function findTicketInfosFromNo(
        uint ticket_no
    ) public view returns (uint, uint) {
        uint lotteryNoCounter = lotteryNoCalculator();
        for (
            uint lottery_no = 0;
            lottery_no < lotteryNoCounter + 1;
            lottery_no++
        ) {
            for (
                uint index = 0;
                index < ticketNosArray[msg.sender].length;
                index++
            ) {
                if (ticketsFromOutside[ticket_no].ticketNo == ticket_no) {
                    return (lottery_no, index);
                }
            }
        }
    }

    /// @notice collects the price of a winning ticket, adds it to the senders balance then
    /// @param lottery_no number of lottery we are referring to
    /// @param ticket_no number of ticket we are referring to
    /// @return uint amount of money won by the ticket
    function collectTicketPrize(
        uint lottery_no,
        uint ticket_no
    ) public returns (uint) {
        require(
            lottery_no <= (lotteryNoCalculator()),
            "Lottery you are requesting has not started yet!"
        );
        require(
            ticket_no <= ticketNoCounter,
            "The ticket you are requesting does not exist"
        );
        require(
            ticketsFromOutside[ticket_no].status == 1,
            "Ticket is not revealed"
        );
        require(
            ticketsFromOutside[ticket_no].owner == msg.sender,
            "You are not the owner!"
        );

        require(lotteryNoCalculator() >= 3, "You cannot pick winner!");
        require(
            lotteryNoCalculator() >= lottery_no + 2,
            "Too early to collect ticket prize!"
        );

        if (!(lotteryInfos[lottery_no].winningTickets.length == 3)) {
            pickWinner(lottery_no);
            totalPrizeMoney[lottery_no] = calculateTotalPriceValue(lottery_no);
            transferAmount(lottery_no, totalPrizeMoney[lottery_no]);
        }
        uint prize;
        uint prizeIndex;
        for (uint i = 0; i < 3; i++) {
            if (
                lotteryInfos[lottery_no].ticketNosInLottery[
                    lotteryInfos[lottery_no].winningTickets[i]
                ] == ticket_no
            ) {
                prizeIndex = i;
                prize = calculateSinglePriceValue(prizeIndex + 1, lottery_no);
                break; // Exit the loop if the ticket is found
            }
        }

        lotteryBalance -= prize;
        moneyCollectedForEachLottery[lottery_no] -= prize;
        balance[msg.sender] += prize;
        return prize;
    }

    ///@notice getter function for the balance of a sender
    ///@return uint sender`s balance
    function getBalance() public view returns (uint) {
        return balance[msg.sender];
    }

    
    //mapping(address => uint[]) public ticketNosArray;

    function getTicketNosArray() public view returns(uint[] memory) {

        uint[] memory result = new uint[](ticketNosArray[msg.sender].length);
        for(uint j=0; j<ticketNosArray[msg.sender].length; j++ ){
         result[j] = ticketNosArray[msg.sender][j];
        }
        return result;
    }
}
