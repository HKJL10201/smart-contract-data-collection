// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./TicketNFT.sol";

/**@title Store manages the logic of the lottery*/
/**@dev ticket data will be saved in an ERC721 ticketNFT contract and player
 *will receive a token of that contract
 *organizer(owner of this contract) will receive 1% ticket price
 *prize will be divided equally among the winners
 *if there is no winners in a time, prize will be added to the next time
 */
contract Store is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event onPrizeChange(uint256 _prize);
    event onNewTicketBought(address player, uint32 ticket);
    event onBalanceUpdate(uint256 _balance, address _wallet);

    //ticket max number
    uint8 internal ticketSize;
    //price per ticket
    uint256 public ticketPrice;
    //prize for current lottery
    uint256 public todaysPrize;
    //order of lottery
    uint256 public lotteryTimes;

    //current ticket NFT
    TicketNFT public ticketNFT;
    //balance of an address
    mapping(address => uint256) public balances;
    //ticket NFT corresponding to lottery time
    mapping(uint256 => address) public timesToNFTAddress;

    /**@dev one address can only by one ticket per lottery time */
    modifier hasNotPlayed(address _address) {
        require(!ticketNFT.hasPlayed(msg.sender));
        _;
    }

    constructor() Ownable() {
        ticketSize = 5;
        ticketPrice = 0.001 ether;
        todaysPrize = 0;
        lotteryTimes = 0;
    }

    /**@dev Function to buy ticket. one address can only by one ticket per lottery time
     *player have to send ether equal to the ticket price
     *mint token to player and
     */
    function buyTicket(uint8 _ticket)
        external
        payable
        hasNotPlayed(msg.sender)
        nonReentrant
    {
        require(_ticket < ticketSize);
        require(msg.value == ticketPrice);

        ticketNFT.mint(msg.sender, _ticket);

        todaysPrize = todaysPrize.add((ticketPrice.mul(99)).div(100));
        address _owner = owner();
        addToBalance(_owner, ticketPrice.div(100));
        emit onPrizeChange(todaysPrize);
        emit onNewTicketBought(msg.sender, _ticket);
    }

    /**@dev change blance of an address */
    function addToBalance(address _wallet, uint256 _amount) internal {
        balances[_wallet] = balances[_wallet].add(_amount);
        emit onBalanceUpdate(balances[_wallet], _wallet);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**@return return ticket number of an address
     *return ticket size if that address haven't bought a ticket this time
     */
    function getTicketByAddress(address _address)
        external
        view
        returns (uint8)
    {
        return ticketNFT.getTicketByAddress(_address);
    }

    /**@dev pseudo-random function to return the result using
     *block.timestamp and block.difficulty
     */
    function getRandomNumber(uint8 _number) public view returns (uint8) {
        return
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, block.difficulty)
                    )
                ) % _number
            );
    }

    /**@dev Set result for current lottery time */
    function setResult() external onlyOwner {
        uint8 _result = getRandomNumber(ticketSize);
        uint256 _winnersCount = ticketNFT.setResult(_result);
        addPrizeToWallet(_winnersCount);
        setUpNewTime();
    }

    /**@dev add balance to winner address */
    function addPrizeToWallet(uint256 _winnersCount) private {
        if (_winnersCount > 0) {
            uint256 _prizeValue = todaysPrize.div(_winnersCount);
            ticketNFT.setPrize(_prizeValue);
            for (uint256 i = 1; i <= _winnersCount; i = i.add(1)) {
                address _winnerAddress = ticketNFT.getWinnerAddressByIndex(i);
                addToBalance(_winnerAddress, _prizeValue);
            }
            todaysPrize = 0;
        }
    }

    /**@dev Set up for new lottery time */
    function setUpNewTime() private {
        lotteryTimes = lotteryTimes.add(1);
        ticketNFT = new TicketNFT(lotteryTimes);
        timesToNFTAddress[lotteryTimes] = address(ticketNFT);
    }

    /**@dev Set up for first lottery time 
    *WARNING: have to run this function right after constructor
    */
    function firstTimeSetUp() external onlyOwner {
        require(address(ticketNFT) == address(0));
        setUpNewTime();
    }

    function withdraw(uint256 _amount) public nonReentrant returns (bool) {
        require(balances[msg.sender] >= _amount);
        bool sent = payable(msg.sender).send(_amount);
        if (sent) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            emit onBalanceUpdate(balances[msg.sender], msg.sender);
        }
        return sent;
    }
    /**@return address of ticket NFT by specific times*/
    function getTicketNFTAddressByTime(uint256 _time)
        external
        view
        returns (address)
    {
        return timesToNFTAddress[_time];
    }

    fallback() external payable {}

    receive() external payable {}
}
