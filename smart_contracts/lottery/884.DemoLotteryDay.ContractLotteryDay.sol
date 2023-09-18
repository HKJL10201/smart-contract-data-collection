// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract ContractLotteryDay {
    struct Lottery {
        uint256 lotteryPeriod;
        uint256 openNumber;
        uint256 luckyPrizePool;
        uint256 playCount;
        bool isAdminVerify;
        mapping(address => bool) withdrawMap;
        mapping(uint256 => Player) players;
    }
    struct Player {
        uint256 luckNumber;
        uint256 lastNumber;
        string txHash;
        address playerAddress;
    }

    event LuckyNumber(address fromAddress);
    event LuckyBet(address fromAddress, uint256 lotteryCount, string txHash);
    mapping(uint256 => Lottery) private lotterys;
    uint256 private lotteryCount;
    uint256 private period = 1 days; //1days 1minutes
    address payable private manager;
    mapping(address => string) private addressExistsMap;
    mapping(uint256 => address) private addressIndexMap;
    uint256 private addressMapCount;

    constructor() {
        manager = payable(msg.sender);
        createLottery();
    }

    function testLotteryCount() public view returns (uint256) {
        return lotteryCount;
    }

    function testPlayer(
        uint256 lottery,
        uint256 player
    ) public view returns (Player memory) {
        Lottery storage nowLottery = lotterys[lottery];
        Player storage nowPlayer = nowLottery.players[player];
        return nowPlayer;
    }

    function testLottery(uint256 lottery) public view returns (uint[4] memory) {
        Lottery storage nowLottery = lotterys[lottery];
        uint[4] memory sumArray = [
            nowLottery.lotteryPeriod,
            nowLottery.openNumber,
            nowLottery.luckyPrizePool,
            nowLottery.playCount
        ];
        return sumArray;
    }

    function testLotteryVerify(uint256 lottery) public view returns (bool) {
        Lottery storage nowLottery = lotterys[lottery];
        return nowLottery.isAdminVerify;
    }

    function testAddressMap() public view returns (address[] memory) {
        address[] memory addressArray = new address[](addressMapCount);
        for (uint8 i = 0; i < addressMapCount; i++) {
            addressArray[i] = addressIndexMap[i + 1];
        }
        return addressArray;
    }

    function testAddressExists(
        address addr
    ) public view returns (string memory) {
        return addressExistsMap[addr];
    }

    function testBlockNumber() public view returns (uint) {
        return block.number;
    }

    function testBlockTime() public view returns (uint) {
        return block.timestamp;
    }

    function testClaimList(
        uint256 lotteryIndex
    ) public view returns (address[] memory) {
        Lottery storage nowLottery = lotterys[lotteryIndex];
        address[] memory addressArray = new address[](nowLottery.playCount);
        for (uint8 i = 1; i <= nowLottery.playCount; i++) {
            Player storage nowPlayer = nowLottery.players[i];
            address nowAddress = nowPlayer.playerAddress;
            if (nowLottery.withdrawMap[nowAddress] == true)
                addressArray[i - 1] = nowAddress;
        }
        return addressArray;
    }

    function createLottery() private {
        lotteryCount += 1;
        Lottery storage lottery = lotterys[lotteryCount];
        lottery.lotteryPeriod = block.timestamp;
        lottery.openNumber = 0;
        lottery.luckyPrizePool = 0;
        lottery.playCount = 0;
        lottery.isAdminVerify = false;
    }

    function createPlayer(Lottery storage nowLottery) private {
        nowLottery.playCount += 1;
        Player storage nowPlayer = nowLottery.players[nowLottery.playCount];
        nowPlayer.playerAddress = msg.sender;
        nowPlayer.luckNumber = 0;
        nowPlayer.lastNumber = 0;
        nowPlayer.txHash = "";
    }

    function suAdmin1(uint256 lotteryIndex) public restricted {
        Lottery storage nowLottery = lotterys[lotteryIndex];
        require(nowLottery.lotteryPeriod > 0);
        nowLottery.isAdminVerify = !nowLottery.isAdminVerify;
    }

    function suAdmin2(
        uint256 lotteryIndex,
        string memory txHash
    ) public restricted {
        Lottery storage nowLottery = lotterys[lotteryIndex];
        require(nowLottery.lotteryPeriod > 0);
        uint[2] memory numbers = parseTxHash(txHash);
        nowLottery.openNumber = numbers[0];
    }

    function suAdmin3(
        uint256 lotteryIndex,
        uint256 playerIndex,
        string memory txHash
    ) public restricted {
        Lottery storage nowLottery = lotterys[lotteryIndex];
        require(nowLottery.lotteryPeriod > 0);
        Player storage nowPlayer = nowLottery.players[playerIndex];
        require(nowPlayer.luckNumber > 0);
        uint[2] memory numbers = parseTxHash(txHash);
        nowPlayer.txHash = txHash;
        nowPlayer.lastNumber = numbers[0];
        nowPlayer.luckNumber = numbers[1];
    }

    function suAdmin5() public restricted {
        payable(manager).transfer(address(this).balance);
    }

    function suAdmin6() public payable restricted {}

    function isNewLottery() public view returns (bool) {
        Lottery storage nowLottery = lotterys[lotteryCount];
        uint256 nowPeriod = block.timestamp;
        uint256 startPeriod = nowLottery.lotteryPeriod;
        uint256 endPeriod = startPeriod + period;
        return nowPeriod > endPeriod;
    }

    function createLuckyNumber() public payable {
        if (isNewLottery()) createLottery();
        string memory exists = addressExistsMap[msg.sender];
        if (bytes(exists).length == 0) {
            addressMapCount += 1;
            addressIndexMap[addressMapCount] = msg.sender;
        }
        addressExistsMap[msg.sender] = "true";
        emit LuckyNumber(msg.sender);
    }

    function createLuckyBet(string memory txHash) public payable {
        if (isNewLottery()) createLottery();
        string memory exists = addressExistsMap[msg.sender];
        require(
            keccak256(abi.encodePacked(exists)) ==
                keccak256(abi.encodePacked("true"))
        );
        require(msg.value >= 888 ether);
        Lottery storage nowLottery = lotterys[lotteryCount];
        nowLottery.luckyPrizePool += 888;
        createPlayer(nowLottery);
        setLastPlayerTxHash(nowLottery, txHash);
        addressExistsMap[msg.sender] = "false";
        emit LuckyBet(msg.sender, lotteryCount, txHash);
    }

    function setLastPlayerTxHash(
        Lottery storage nowLottery,
        string memory txHash
    ) private {
        Player storage lastPlayer = nowLottery.players[nowLottery.playCount];
        bool isLastPlayerExists = lastPlayer.playerAddress != address(0x0);
        if (isLastPlayerExists && bytes(lastPlayer.txHash).length == 0) {
            lastPlayer.txHash = txHash;
            uint[2] memory numbers = parseTxHash(txHash);
            lastPlayer.luckNumber = numbers[1];
            lastPlayer.lastNumber = numbers[0];
            nowLottery.openNumber = numbers[0];
        }
    }

    function parseTxHash(
        string memory txHash
    ) private pure returns (uint[2] memory) {
        uint[2] memory numbers;
        bytes memory txBytes = bytes(txHash);
        uint[10] memory sumArray = [uint(0), 0, 0, 0, 0, 0, 0, 0, 0, 0];
        uint[10] memory firstIndexArray = [uint(0), 0, 0, 0, 0, 0, 0, 0, 0, 0];
        for (uint8 i; i < txBytes.length; i++) {
            bytes1 char = txBytes[i];
            if (char > 0x30 && char <= 0x39) {
                uint8 uval = uint8(char);
                uint jval = uval - uint(0x30);
                sumArray[jval] = sumArray[jval] + 1;
                uint first = firstIndexArray[jval];
                if (first == 0) firstIndexArray[jval] = i;
            }
        }
        uint minSum = 99;
        uint minNumber = 99;
        uint maxSum = 0;
        uint maxNumber = 0;
        for (uint i = 1; i < sumArray.length; i++) {
            uint sumMin = sumArray[i];
            uint numMin = i;
            if (sumMin <= minSum) {
                if (sumMin == minSum) {
                    uint number1First = firstIndexArray[minNumber];
                    uint number2First = firstIndexArray[i];
                    if (number1First < number2First) {
                        sumMin = minSum;
                        numMin = minNumber;
                    }
                }
                minSum = sumMin;
                minNumber = numMin;
            }
            numbers[0] = minNumber;
            uint sumMax = sumArray[i];
            uint numMax = i;
            if (sumMax >= maxSum) {
                if (sumMax == maxSum) {
                    uint number1First = firstIndexArray[maxNumber];
                    uint number2First = firstIndexArray[i];
                    if (number1First < number2First) {
                        sumMax = maxSum;
                        numMax = maxNumber;
                    }
                }
                maxSum = sumMax;
                maxNumber = numMax;
            }
        }
        numbers[1] = maxNumber;
        return numbers;
    }

    function calcWinAmount(
        uint256 lotteryIndex,
        address sender
    ) public view returns (uint256) {
        Lottery storage nowLottery = lotterys[lotteryIndex];
        if (
            nowLottery.playCount == 0 ||
            nowLottery.luckyPrizePool == 0 ||
            nowLottery.isAdminVerify == false
        ) return 0;
        uint256 allWinCount = 0;
        uint256 myWinCount = 0;
        for (uint8 i = 1; i <= nowLottery.playCount; i++) {
            Player storage player = nowLottery.players[i];
            if (
                player.luckNumber == nowLottery.openNumber &&
                nowLottery.withdrawMap[sender] == false &&
                nowLottery.isAdminVerify == true
            ) {
                allWinCount += 1;
                if (player.playerAddress == sender) {
                    myWinCount += 1;
                }
            }
        }
        if (allWinCount == 0 || myWinCount == 0) return 0;
        uint256 money = nowLottery.luckyPrizePool / allWinCount;
        uint256 totalWin = money * myWinCount;
        if (totalWin > nowLottery.luckyPrizePool) return 0;
        uint256 total = totalWin * 1 ether;
        return total;
    }

    function claimWinAmount(uint256 lotteryIndex) public {
        uint256 total = calcWinAmount(lotteryIndex, msg.sender);
        require(total > 0);
        require(total <= address(this).balance);
        Lottery storage nowLottery = lotterys[lotteryIndex];
        nowLottery.withdrawMap[msg.sender] = true;
        payable(msg.sender).transfer(total);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}
