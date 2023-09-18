pragma solidity ^0.4.21;

import "./Destructible.sol";
import "./SafeMath.sol";

contract Lottery is Destructible {

    using SafeMath for uint256;

    //----------Parameters-----------
    //permile of the ticket price that reverts to contract owner in finney. 10 == 1.0%
    uint256 public ownerFee;

    // Duration the lottery will be active for
    uint256 public lotteryDuration;

    // Price for one ticket in finney
    uint256 public ticketPrice;

    // Price to change name in finney
    uint256 public nameChangePrice;

    //----------Variables------------
    //set a name for an address
    mapping (address => string) public addressToName;

    //maps the egem each winner/contract owner has available for withdraw
    mapping (address => uint256) public approvedBalance;

    //Nonce used to secure random 
    uint256 private nonce = 0;

    // Array of ticket holders to draw winner from
    address[] public holders;

    // Total number of tickets issued
    uint256 public ticketsIssued;

    // When the lottery started
    uint256 public lotteryStart;

    //total prize available for winner
    uint256 public poolPrize;

    // Total amount of prizes issued by the contract
    uint256 public totalPrizeAwarded;

    //----------Events---------------
    // Event for when tickets are bought
    event TicketsBought(address indexed _from, uint256 _quantity);

    // Event for declaring the winner
    event AwardWinnings(address indexed _to, uint256 _winnings);

    // Event for lottery reset
    event NewLottery();

    //---------Modifiers---------------

    // Checks if still in lottery contribution period
    modifier lotteryOngoing() {
        require(now < (lotteryStart.add(lotteryDuration)));
        _;
    }

    // Checks if lottery has finished
    modifier lotteryFinished() {
        require(now > (lotteryStart.add(lotteryDuration)));
        _;
    }

    //---------Functions----------------

    //Create the lottery
    constructor() public {
        ticketsIssued = 0;
        poolPrize = 0;
        ownerFee = 15;
        ticketPrice = 100 finney;
        nameChangePrice = 1000 finney;
        lotteryDuration = 24 hours;
        lotteryStart = now;

        emit NewLottery();
    }

    //Add address to the ticket holders array. Adjust holders array size as needed
    function insertHolder (address _holder) private {
        if(ticketsIssued == holders.length) {
            holders.push(_holder);
        }
        else {
            holders[ticketsIssued] = _holder;
        }
        ticketsIssued = ticketsIssued.add(1);
    }

    // Award users tickets
    function buyTickets() public payable lotteryOngoing {
        require(msg.sender != owner);
        require(msg.value >= ticketPrice);

        // Add to the prize pool and pay fees
        uint256 fee = msg.value / 1000 * ownerFee;
        poolPrize = poolPrize.add(msg.value.sub(fee));
        approvedBalance[owner] = approvedBalance[owner].add(fee);

        // Issue the tickets
        uint256 ticketsGenerated = msg.value / ticketPrice;
        for(uint256 i = 0; i < ticketsGenerated; i++) {
            insertHolder(msg.sender);
        }

        emit TicketsBought(msg.sender, ticketsGenerated);
    }

    // Fallback function calls buyTickets
    // Not supported without named constructor
    /*function () public payable {
        buyTickets();
    }*/

    // Donate to the pool prize without issuing tickets. No fees
    function donate() external payable lotteryOngoing {
        poolPrize = poolPrize.add(msg.value);
    }

    // Restart the Lottery active time
    function newLottery() private lotteryFinished {
        ticketsIssued = 0;
        poolPrize = 0;
        lotteryStart = now;
        emit NewLottery();
    }

    // Award the pool prize to the winner. Call newLottery
    function awardWinnings(address _winner) private lotteryFinished {
        approvedBalance[_winner] = approvedBalance[_winner].add(poolPrize);
        emit AwardWinnings(_winner, poolPrize);
        totalPrizeAwarded = totalPrizeAwarded.add(poolPrize);
        newLottery();
    }

    //Generate the winner at pseudo random by using tickets issued as weight. Reward function caller. Call awardWinnings
    function generateWinner() public lotteryFinished {

        // Issue the caller ticket reward
        insertHolder(msg.sender);
        emit TicketsBought(msg.sender, 1);

        nonce++;
        uint256 rand = uint256(keccak256(now, block.number, block.difficulty, nonce)) % ticketsIssued;
        address winner = holders[rand];
        awardWinnings(winner);
    }

    // Change the name associated to an address
    function changeAddressName(string _name) external payable {
        require(msg.value >= nameChangePrice);
        addressToName[msg.sender] = _name;
        approvedBalance[owner] = approvedBalance[owner].add(msg.value);
    }

    //Change lottery duration
    function changeDuration(uint256 _duration) external onlyOwner {
        lotteryDuration = _duration;
    }

    //Change owner fee
    function changeOwnerFee(uint256 _fee) external onlyOwner {
        ownerFee = _fee;
    }

    //Change ticket price
    function changeTicketPrice(uint256 _price) external onlyOwner {
        ticketPrice = _price;
    }

    //Change name change price
    function changeNameChangePrice(uint256 _price) external onlyOwner {
        nameChangePrice = _price;
    }

    // Allow the winner to withdraw prize
    function withdraw() external {
        uint256 payment = approvedBalance[msg.sender];

        require(payment != 0);
        require(address(this).balance >= payment);

        approvedBalance[msg.sender] = 0;

        msg.sender.transfer(payment);
    }

}
