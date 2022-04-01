// SPDX-License-Identifier: LICENSED
pragma solidity >=0.5.0 <0.9.0;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./UnitedWorldToken.sol";

contract LotterySimpleRandom {
    
    
    using SafeMath for uint256;
    
    IERC20 public token;

    address public admin;
    uint256 public lotteryId = 1;

    struct Lottery {
        uint256 totalTickets;
        uint256 minTickets;
        uint256 maxTickets;
        uint256 openingTime;
        uint256 closingTime;
        uint256 ticketPrice;
        bool lotteryStatus;
        address payable[] participatingPlayers;
        mapping(address => uint256) contributions;
        address payable winner;
    }

    //mapping to get the data of specific lottery through struct value
    mapping(uint256 => Lottery) public lotteries;

    //array to get the created lottery IDs
    uint256[] public LotteryIds;

    event Winner(
        uint256 lotteryId,
        uint256 _randomness,
        uint256 _index,
        uint256 _amount,
        address winner
    );

    // event LotteryStarted(string message);
    event LotteryCreated(string message, uint256 lotteryId);
    event TicketBought(uint256 lotteryId, uint256 ticketAmount, address buyer);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized Person");
        _;
    }

    constructor(IERC20 _token) public payable {
        admin = msg.sender;
        token = _token;
    }

    function createLottery(
        uint256 _ticketPrice,
        uint256 _totalTickets,
        uint256 _openingTime,
        uint256 _closingTime
    ) public returns (bool) {
        address payable[] memory _participatingPlayers;
        address payable _winner;
        uint256 _minTickets = 1;

        Lottery storage lottery = lotteries[lotteryId];

        require(msg.sender == admin, "only admin can create lottery");

        require(
            _openingTime >= block.timestamp,
            "TimedLottery: opening time is before current time"
        );
        require(
            _closingTime > _openingTime,
            "TimedLottery: opening time is not before closing time"
        );

        lotteries[lotteryId] = Lottery(
            _totalTickets,
            _minTickets,
            lottery.maxTickets,
            _openingTime,
            _closingTime,
            _ticketPrice,
            true,
            _participatingPlayers,
            _winner
        );

        lottery.minTickets = _minTickets;
        lottery.maxTickets = (_totalTickets * 25) / 100;
        lottery.totalTickets = _totalTickets;
        lottery.openingTime = _openingTime;
        lottery.closingTime = _closingTime;

        lottery.ticketPrice = _ticketPrice;

        LotteryIds.push(lotteryId);

        lotteryId = lotteryId.add(1);

        emit LotteryCreated("lottery has been created", lotteryId);

        return true;
    }

    function isOpen(uint256 _lotteryId) public view returns (bool) {
        Lottery storage lottery = lotteries[_lotteryId];
        return
            block.timestamp >= lottery.openingTime &&
            block.timestamp <= lottery.closingTime;
    }

    function hasClosed(uint256 _lotteryId) public view returns (bool) {
        Lottery storage lottery = lotteries[_lotteryId];
        return block.timestamp > lottery.closingTime;
    }


    function buyTicket(uint256 _lotteryId, uint256 _ticketAmount)
        public
        payable
    {
        require(
            isOpen(_lotteryId) == true,
            "this lottery has not yet started or been ended"
        );

        Lottery storage lottery = lotteries[_lotteryId];

        require(msg.sender != admin, "only users can call function");
        require(_lotteryId >= 1, "this lottery is not available");
        require(_ticketAmount == lottery.ticketPrice, "Error on Ticket Price");
        require(lottery.lotteryStatus == true, "Error on Lottery status");

        uint256 _existingContribution = lottery.contributions[msg.sender];
        uint256 _newContribution = _existingContribution.add(1);

        require(
            _newContribution >= lottery.minTickets,
            "LotterySimpleRandom: new contribution is less than min tickets player will buy"
        );
        require(
            _newContribution <= lottery.maxTickets,
            "LotterySimpleRandom: new contribution is higher than maximum ticket for one player"
        );

        require(
            lottery.participatingPlayers.length < lottery.totalTickets,
            "LotterySimpleRandom: Participating player length should be less than or equal to totalTickets"
        );

        token.transferFrom(msg.sender, address(this), _ticketAmount);
        lottery.contributions[msg.sender] = _newContribution;
        lottery.participatingPlayers.push(msg.sender);

        emit TicketBought(_lotteryId, _ticketAmount, msg.sender);
    }

    function getrandom(uint256 _lotteryId) public view returns (uint256) {
        Lottery storage lottery = lotteries[_lotteryId];
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        lottery.participatingPlayers.length
                    )
                )
            );
    }

    function pickWinnerandresetLottery(uint256 _lotteryId) public payable {
        require(
            hasClosed(_lotteryId) == true,
            "this lottery has not yet ended"
        );

        Lottery storage lottery = lotteries[_lotteryId];

        require(msg.sender == admin, "admin can call");
        require(lottery.lotteryStatus == true, "Error on Lottery status");
        uint256 randNumber = getrandom(_lotteryId);
        require(randNumber > 0, "random-not-found");

        require(
            lottery.participatingPlayers.length == lottery.totalTickets,
            "error here: players length should be equal to total tickets"
        );

        uint256 index = randNumber % lottery.participatingPlayers.length;
        lottery.winner = lottery.participatingPlayers[index];

        //fee method
        uint256 adminFee = (token.balanceOf(address(this)) * 10) / 100;
        uint256 winnerPrize = (token.balanceOf(address(this)) * 90) / 100;

        token.transfer(lottery.winner, winnerPrize);
        token.transfer(admin, adminFee);

        emit Winner(_lotteryId, randNumber, index, winnerPrize, lottery.winner);

        lottery.participatingPlayers = new address payable[](0);

        resetLottery(lottery);
    }

    function resetLottery(Lottery storage lottery) internal {
        lottery.participatingPlayers = new address payable[](0);
        lottery.lotteryStatus = false;
    }

    function getLotteries() public view returns (uint256[] memory) {
        return LotteryIds;
    }


    function getPlayers(uint256 _lotteryId)
        public
        view
        returns (address payable[] memory)
    {
        return lotteries[_lotteryId].participatingPlayers;
    }


    function getWinner(uint256 _lotteryId) public view returns (address) {
        return lotteries[_lotteryId].winner;
    }


    function openingTime(uint256 _lotteryId) external view returns (uint256) {
        return lotteries[_lotteryId].openingTime;
    }


    function closingTime(uint256 _lotteryId) public view returns (uint256) {
        return lotteries[_lotteryId].closingTime;
    }


    function getLotteryStatus(uint256 _lotteryId) public view returns (bool) {
        return lotteries[_lotteryId].lotteryStatus;
    }


    function getLotteryTicketPrice(uint256 _lotteryId)
        public
        view
        returns (uint256)
    {
        return lotteries[_lotteryId].ticketPrice;
    }
}
