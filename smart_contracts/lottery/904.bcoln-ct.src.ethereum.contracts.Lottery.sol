pragma solidity ^0.4.17;

///////////////////////////////////////////////////////////////////////
// The LotteryFactory is the contract that manages all the Lotteries
// it manages the funds and acts as a
// proxy between the players and the lotteries
///////////////////////////////////////////////////////////////////////
contract LotteryFactory {

    address manager;
    uint ticketPrice;
    uint maxGuessNumber;
    address[] allLotteries;
    Lottery currentLottery = Lottery(address(0x0));
    RandomNumberOracle randomNumberGenerator = RandomNumberOracle(address(0x0));

    constructor(uint _ticketPrice, uint _maxGuessNumber) public {
        manager = msg.sender;
        ticketPrice = _ticketPrice;
        maxGuessNumber = _maxGuessNumber;
        createRandomNumberGenerator();
        // create a new lottery immediately after the factory is created
        currentLottery = new Lottery(_ticketPrice, address(this), address(randomNumberGenerator), maxGuessNumber);
        allLotteries.push(address(currentLottery));
    }

    function play(uint8 guess) public payable {
        require(currentLottery != Lottery(address(0x0)), "There is no lottery running.");
        require(msg.value >= currentLottery.getTicketPrice(), "You have to send enough money.");
        currentLottery.play(guess, msg.sender);
    }

    function pickWinner() public {
        require(msg.sender == manager, "You are not authorized.");
        address[] memory winners = currentLottery.pickWinner(address(this));
        if (winners.length != 0) {
            uint prize = address(this).balance / winners.length;
            for (uint i = 0; i < winners.length; i++) {
                winners[i].transfer(prize);
            }
        }
        // creating a new round immediately after the winner is selected
        currentLottery = new Lottery(ticketPrice, address(this), address(randomNumberGenerator), maxGuessNumber);
        allLotteries.push(address(currentLottery));
    }


    function createRandomNumberGenerator() private {
        randomNumberGenerator = new RandomNumberOracle();
    }

    function describeFactory() public view returns (
        address, uint, uint, address, address[], address
    ) {
        return (
        manager,
        ticketPrice,
        maxGuessNumber,
        currentLottery,
        allLotteries,
        randomNumberGenerator
        );
    }

}


///////////////////////////////////////////////////////////////////////
// The Lottery is created and managed by the factory
// it keeps the basic data such as players by numbers,
// total players cound, the methods play and pick winner
// can just be called from its factory and only if it is not closed;
// once the winner is picked, its variable closed is set to true and
// a new lottery will be created by the factory. It is done like that
// so we keep the history of all the lotteries ever deployed.
///////////////////////////////////////////////////////////////////////
contract Lottery {

    address factory;
    uint ticketPrice;
    bool closed = false;
    uint playerCount = 0;
    uint maxNum;
    uint winNumber;

    RandomNumberOracle public randomNumberGenerator = RandomNumberOracle(address(0x0));

    mapping(uint => address[]) playersByNumber;

    constructor(uint _priceToPlay, address _factory, address _randomNumberGenerator, uint _maxNum) public {
        factory = _factory;
        ticketPrice = _priceToPlay;
        maxNum = _maxNum;
        randomNumberGenerator = RandomNumberOracle(_randomNumberGenerator);
    }

    function play(uint8 guess, address player) public {
        require(closed == false, "The lottery is closed.");
        require(guess <= maxNum, "Guess guess number not valid.");
        playersByNumber[guess].push(player);
        playerCount++;
    }

    function pickWinner(address caller) public returns (address[]) {
        require(caller == factory, "You are not authorized to call this method.");
        require(closed == false, "The lottery is closed.");
        winNumber = randomNumberGenerator.getRandom(maxNum);
        closed = true;
        return (playersByNumber[winNumber]);
    }

    function getTicketPrice() public view returns (uint) {
        return (ticketPrice);
    }

    function getPlayersByGuessNum(uint num) public view returns (address[]) {
        return playersByNumber[num];
    }

    function describeLottery() public view returns (
        bool, uint, uint, address, uint, address[]
    ) {
        return (
        closed,
        playerCount,
        ticketPrice,
        factory,
        winNumber,
        playersByNumber[winNumber]
        );
    }

}

contract RandomNumberOracle {
    function getRandom(uint range) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (range + 1);
    }
}