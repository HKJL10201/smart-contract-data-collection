pragma solidity ^0.8.9;

contract Lottery {
    struct LotteryTicketByNumber {
        address buyer;
        uint256 amount;
    }

    struct LotteryTicketByAddress {
        uint256 number;
        uint256 amount;
    }

    enum State {
        Ongoing,
        Completed
    }

    event LotteryWinning(address addr, uint256 totalWinning);

    // drawResult consists of which lottery number in which ranking
    // starting from 1st, 2nd, 3rd, 10 special numbers and 10 consolation numbers
    // so in total of 23 numbers
    uint256[] public drawResults;

    // winningRatio is array of winning ratio
    // starting from 1st, 2nd, 3rd, 10 special numbers and 10 consolation numbers
    uint256[] public winningRatios;

    // mapping of what kind of numbers that which buyer address is buying for a certain amount
    mapping(uint256 => LotteryTicketByNumber[]) public lotteryTicketsByNumber;

    // mapping of which buyer address that what kind of number is being bought for a certain amount
    mapping(address => LotteryTicketByAddress[]) public lotteryTicketsByAddress;

    // records list of lottery numbers that are bought for "lotteryTicketsByNumber" for reset purpose
    uint256[] public boughtNumbers;

    // records list of buyer addresses that are bought for "lotteryTicketsByAddress" for reset purpose
    address[] public boughtBuyerAddresses;

    // totalFund reserved for contract to distribute prize to buyer and
    // also collecting ticket fee from buyer
    uint256 public totalFund;

    // drawResultDeadline can be set by contract in order for testing
    uint256 public drawResultDeadline;

    // current state of smart contract
    State public state;

    // beneficiary is the person who can withdraw money from funding
    address payable public beneficiary;

    modifier inState(State expectedState) {
        require(state == expectedState, "Invalid State");
        _;
    }

    constructor(address payable _beneficiary, uint256[] memory _winningRatios) {
        beneficiary = _beneficiary;
        state = State.Ongoing;
        winningRatios = _winningRatios;
    }

    function beforeDeadline() public view returns (bool) {
        return block.timestamp < drawResultDeadline;
    }

    function finishResultDrawing(uint256[] memory results)
        public
        inState(State.Ongoing)
    {
        require(
            !beforeDeadline(),
            "Cannot finish result drawing before a deadline"
        );
        require(
            results.length == 23,
            "Invalid length of drawing results array"
        );

        state = State.Completed;
        drawResults = results;

        for (uint256 i = 0; i < results.length; i++) {
            require(
                results[i] > 0 && results[i] < 10000,
                "Number must be between 0 and 9999"
            );

            LotteryTicketByNumber[] storage tickets = lotteryTicketsByNumber[
                results[i]
            ];
            if (tickets.length > 0) {
                for (uint256 j = 0; j < tickets.length; j++) {
                    distributePrize(
                        winningRatios[i],
                        tickets[j].amount,
                        tickets[j].buyer
                    );
                }
            }
        }
    }

    function distributePrize(
        uint256 winningRatio,
        uint256 amount,
        address buyerAddress
    ) public inState(State.Completed) {
        uint256 finalAmount = winningRatio * amount * 1 wei;
        require(
            totalFund >= finalAmount,
            "Sorry, system is having insufficient fund. Please contact admin"
        );

        payable(buyerAddress).transfer(finalAmount);
        totalFund -= finalAmount;

        emit LotteryWinning(buyerAddress, finalAmount);
    }

    function buyLotteryTicket(uint256 bettingNumber)
        public
        payable
        inState(State.Ongoing)
    {
        require(
            bettingNumber >= 0 && bettingNumber < 10000,
            "Invalid lottery number is provided"
        );
        require(msg.value > 0, "Invalid buying value");

        LotteryTicketByNumber[]
            storage currentTicketByNumber = lotteryTicketsByNumber[
                bettingNumber
            ];

        currentTicketByNumber.push(
            LotteryTicketByNumber(msg.sender, msg.value)
        );
        boughtNumbers.push(bettingNumber);

        LotteryTicketByAddress[]
            storage currentTicketByAddress = lotteryTicketsByAddress[
                msg.sender
            ];

        currentTicketByAddress.push(
            LotteryTicketByAddress(bettingNumber, msg.value)
        );
        boughtBuyerAddresses.push(msg.sender);

        totalFund += msg.value;
    }

    function putFunding() public payable {
        totalFund += msg.value;
    }

    function withdrawFromFunding(uint256 amount)
        public
        inState(State.Completed)
    {
        require(totalFund >= amount, "Insufficient fund to be withdrawed");
        beneficiary.transfer(amount);
    }

    function setCompletedState() public {
        state = State.Completed;
    }

    function setDrawResultDeadline(uint256 _drawResultDeadline) public {
        drawResultDeadline = _drawResultDeadline;
    }

    function getLotteryTicketsForBettingNumber(uint256 bettingNumber)
        external
        view
        returns (LotteryTicketByNumber[] memory)
    {
        return lotteryTicketsByNumber[bettingNumber];
    }

    function getLotteryTicketsForAddress(address buyerAddress)
        external
        view
        returns (LotteryTicketByAddress[] memory)
    {
        return lotteryTicketsByAddress[buyerAddress];
    }

    function getDrawResults() external view returns (uint256[] memory) {
        return drawResults;
    }

    function getWinningRatios() external view returns (uint256[] memory) {
        return winningRatios;
    }

    function reset() public {
        delete drawResults;
        for (uint256 i = 0; i < boughtNumbers.length; i++) {
            delete lotteryTicketsByNumber[boughtNumbers[i]];
        }
        for (uint256 i = 0; i < boughtBuyerAddresses.length; i++) {
            delete lotteryTicketsByAddress[boughtBuyerAddresses[i]];
        }
        state = State.Ongoing;
    }
}
