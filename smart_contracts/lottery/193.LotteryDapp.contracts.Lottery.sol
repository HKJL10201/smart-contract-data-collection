//SPDX-License-Identifier: MIT

pragma solidity >0.7.0 <=0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {LotteryToken} from "./Token.sol";

contract Lottery is Ownable {
    LotteryToken public paymentToken;
    uint256 public betsClosingTime;
    uint256 public betFee;
    uint256 public betPrice;
    bool public betsOpen; // False by default

    uint256 public prizePool;
    uint256 public ownerPool;

    mapping(address => uint256) public prize;

    address[] _slots;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 fee,
        uint256 _betPrice
    ) {
        paymentToken = new LotteryToken(tokenName, tokenSymbol);
        betFee = fee;
        betPrice = _betPrice;
    }

    modifier whenBetClosed() {
        require(!betsOpen, "Lottery is open");
        _;
    }

    modifier whenBetsOpen() {
        require(
            betsOpen && block.timestamp < betsClosingTime,
            "Lottery is closed"
        );

        _;
    }

    /// @param closingTime Amount of seconds that the bets can be placed after opening
    function openBets(uint256 closingTime) public onlyOwner whenBetClosed {
        require(
            closingTime > block.timestamp,
            "Closing time must be in the future"
        );
        betsClosingTime = closingTime;
        betsOpen = true;
    }

    function purchaseTokens() public payable {
        paymentToken.mint(msg.sender, msg.value);
    }

    function bet() public whenBetsOpen {
        ownerPool += betFee;
        // Maybe we need to do a little math here
        //Update the pools
        prizePool += betPrice;
        // Need to aprove this tho
        paymentToken.transferFrom(msg.sender, address(this), betPrice + betFee);
    }

    function betMany(uint256 times) public {
        require(times > 0);
        while (times > 0) {
            bet();
            times--;
        }
    }

    function closeLottery() public {
        require(block.timestamp >= betsClosingTime, "Too soon to close");
        require(betsOpen, "Already closed");

        if (_slots.length > 0) {
            uint256 winnerIndex = getRandomNumber() % _slots.length;
            address winner = _slots[winnerIndex];
            prize[winner] += prizePool;
            prizePool = 0;
            delete (_slots);
        }

        betsOpen = false;
    }

    function getRandomNumber() public view returns (uint256 randomNumber) {
        randomNumber = block.difficulty;
    }

    function prizeWithdraw(uint256 amount) public {
        require(amount <= prize[msg.sender], "Not enough prize");
        prize[msg.sender] -= amount;
        paymentToken.transfer(msg.sender, amount);
    }

    function ownerWithdraw(uint256 amount) public onlyOwner {
        require(amount <= ownerPool, "Nott enough fees collected");
        ownerPool -= amount;
        paymentToken.transfer(msg.sender, amount); // Maybe we can fix the oner tho
    }

    function returnTokens(uint256 amount) public {
        paymentToken.burnFrom(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}
