// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LotteryToken} from "./Token.sol";

contract Lottery is Ownable {
    /// @notice paymentToken if called by outside chain returns the Token's address
    LotteryToken public paymentToken;
    uint256 public closingTime;
    bool public betsOpen;
    uint256 public betPrice;
    uint256 public betFee;

    /// @notice Amount of tokens in the prize pool
    uint256 public prizePool;
    /// @notice Amount of tokens in the owner pool
    uint256 public ownerPool;

    ///@notice Mapping of prize available for withdraw for each account
    mapping(address => uint256) public prize;

    ///@dev List of bet slots
    address[] _slots;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _betPrice,
        uint256 _betFee
    ) {
        paymentToken = new LotteryToken(tokenName, tokenSymbol);
        betPrice = _betPrice;
        betFee = _betFee;
    }

    modifier whenBetsClosed() {
        require(!betsOpen, "Lottery: Bets are not closed");
        _;
    }

    /// @notice Passes when the lottery is at open state and the current block timestap is lower than the lottery's one
    modifier whenBetsOpen() {
        require(
            betsOpen && block.timestamp < closingTime,
            "Lottery: Bets are closed"
        );
        _;
    }

    /// @param _closingTime target time in seconds expressed in epoch time for the bets to close
    function openBets(uint256 _closingTime) public onlyOwner {
        require(
            _closingTime > block.timestamp,
            "Closing time must be greater than current block.timestamp"
        );
        closingTime = _closingTime;
        betsOpen = true;
    }

    /// @notice Give tokens based on the amount of ETH sent
    function purchaseTokens() public payable {
        /// @notice Ether goes deposited to the Smart Contract's address
        /// @notice It is used to split msg.value by tokenPurchaseRatio in a way to give the estabilited amount of tokens per each ether
        paymentToken.mint(msg.sender, msg.value);
    }

    /// @notice Charge the bet price and create a new bet slot with the sender address
    function bet() public whenBetsOpen {
        ownerPool += betFee;
        prizePool += betPrice;
        _slots.push(msg.sender);
        /// @notice With address(this) is meant actually this contract's address
        paymentToken.transferFrom(msg.sender, address(this), betPrice + betFee); /// @notice Transfers LotteryToken from the better to the Smart Contract's address
    }

    /// @notice Call the bet function more times
    function betMany(uint256 times) public {
        require(times > 0);
        while (times > 0) {
            bet();
            times--;
        }
    }

    /// @notice Close the lottery and calculates the prize, if any
    /// @dev Anyone can call this fuction if the owner fails to do so
    function closeLottery() public {
        _slots.push(msg.sender);
        require(block.timestamp >= closingTime, "Lorrery: Too soon to close");
        require(betsOpen, "Lottery: Already closed");
        if (_slots.length > 0) {
            uint256 winnerIndex = getRandomNumber() % _slots.length;
            address winner = _slots[winnerIndex];
            prize[winner] += prizePool;
            prizePool = 0;
            delete (_slots);
        }
        betsOpen = false;
    }

    /// @notice Get a random number calculated from the previous block randao
    /// @dev This only works after The Merge
    function getRandomNumber() public view returns (uint256 randomNumber) {
        randomNumber = block.difficulty;
    }

    /// @notice Withdraw `amount` from that accounts prize pool
    function prizeWithdraw(uint256 amount) public {
        require(amount <= prize[msg.sender], "Lottery: Not enough prize");
        prize[msg.sender] -= amount;
        paymentToken.transfer(msg.sender, amount);
    }

    /// @notice Withdraw `amount` from the owner pool
    function ownerWithdraw(uint256 amount) public onlyOwner {
        require(amount <= ownerPool, "Lottery: Not enough fees collected");
        ownerPool -= amount;
        paymentToken.transfer(msg.sender, amount);
    }

    /// @notice Burn `amount` tokens and give the equivalent ETH back to user
    function returnTokens(uint256 amount) public {
        paymentToken.burnFrom(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}
