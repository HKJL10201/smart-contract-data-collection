// SPDX-License-Identifier: UNLICENSE

// Situation A XYZ organization create lottery time to time where people can participate and win lottery

// Features:
// 1. Manager can create lottery
// 2. Participants partcipate the lottery by giving 0.001 ether
// 3. A partcipant can have certain amount of entry
// 4. Manager only select the winner
// 5. Manager can also delete lottery if the there is no player
// 6. Each lottery will have certain time limit and after that manager can select winner

// Lottery Details can be:
// 1. name
// 2. Entry fee
// 3. Start date
// 4. End Date
// 5. Created Date
// 6. MaxEntryOfEachPerson
// 7. Minimum participant
// 8. Is lottery has started;
// 9. Is lottery has closed

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    string public manager_name;
    address public manager_address;

    constructor(string memory name) {
        manager_name = name;
        manager_address = msg.sender;
    }

    // ====Lottery functions====
    // Struucture of the details of the lottery
    struct LotteryStruct {
        string lotter_name;
        uint256 createdDate;
        uint256 startDate;
        uint256 endDate;
        uint256 entry_fees;
        uint8 maxEntryOfEachPerson;
        uint16 min_participant;
        bool isStarted;
        bool isClosed;
    }

    // String the lotteris
    LotteryStruct[] public lotteries;

    // Get all the lotteries
    function getLotteries() public view returns (LotteryStruct[] memory) {
        return lotteries;
    }

    // Create Lotteries
    function createLottery(
        string memory name,
        uint256 startDate,
        uint256 endDate,
        uint256 entryFees,
        uint8 maxEntryOfEachPerson,
        uint16 min_Particpant
    ) public onlyManager {
        require(
            startDate > block.timestamp,
            "Start date must be greater than current time"
        );
        require(
            endDate > startDate,
            "End date must be greater than start time"
        );
        LotteryStruct memory newLottery = LotteryStruct(
            name,
            block.timestamp,
            startDate,
            endDate,
            entryFees,
            maxEntryOfEachPerson,
            min_Particpant,
            false,
            false
        );
        lotteries.push(newLottery);
    }

    // Delete Lotteries
    function delteLottery(uint256 idx) public onlyManager {
        LotteryStruct[] memory newLotteries;
        for (uint256 i = 0; i < lotteries.length; i++) {
            if (i != idx) newLotteries[i] = lotteries[i];
        }
        lotteries = newLotteries;
    }

    // Update the lottery
    function updateLottery(
        uint256 idx,
        string memory name,
        uint256 startDate,
        uint256 endDate,
        uint256 entryFees,
        uint8 maxEntryOfEachPerson,
        uint16 min_Particpant
    ) public onlyManager {
        LotteryStruct storage updatedLottery = lotteries[idx];
        updatedLottery.lotter_name=name;
        updatedLottery.startDate=startDate;
        updatedLottery.endDate=endDate;
        updatedLottery.maxEntryOfEachPerson=maxEntryOfEachPerson;
        updatedLottery.min_participant=min_Particpant;
        updatedLottery.entry_fees=entryFees;
    }

    // Start the lottery
    function startLottery(uint idx) public onlyManager {
        LotteryStruct storage lottery = lotteries[idx];
        lottery.isStarted=true;
    }

    // Stop the Lottery
    function stopLottery() public onlyManager {
        LotteryStruct storage lottery = lotteries[idx];
        lottery.isClosed=true;
    }

    modifier onlyManager() {
        require(
            manager_address == msg.sender,
            "You are not permitted to do the oparation"
        );
        _;
    }
}
