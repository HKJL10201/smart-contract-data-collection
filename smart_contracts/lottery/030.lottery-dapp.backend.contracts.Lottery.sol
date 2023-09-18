// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LotteryToken} from "./LotteryToken.sol";

contract Lottery is Ownable {
    /// @notice Addres of the token to be used fas payment for bets
    LotteryToken public paymentToken;
    /// @notice Amount of tokens given per ETH paid
    uint256 public purchaseRatio;
    /// @notice Amount of tokens required to place a bet that goes to the prizepool
    uint256 public betPrice;
    /// @notice amount of tokens required to place abet that goes to the owner pool
    uint256 public betFee;
    /// @notice Amount of tokens in the prize pool
    uint256 public prizePool;
    /// @notice amount of tokens in the Owners pool
    uint256 public ownerPool;
    /// @notice Flag indicating if the lottery is open for bets
    bool public betsOpen;
    /// @notice TimeStamp of the lottery next closing date
    uint256 public betsClosingTime;
    /// @notice Mapping of prize available for withdraw
    mapping (address => uint256) public prize;
    /// @dev List of bet slots
    address[] _slots;

    /// @notice Constructor function
    /// @param tokenName Name of the token used for payment
    /// @param tokenSymbol Symbol of the token used for payment
    /// @param _purchaseRatio Amount of tokens given per ETH paid
    /// @param _betPrice Amount of tokens required for placing a bet that goes for the prize pool
    /// @param _betFee Amount of tokens required for placing a bet that goes for the owner pool
    constructor (string memory tokenName, string memory tokenSymbol, uint256 _purchaseRatio, uint256 _betPrice,
        uint256 _betFee) {
        paymentToken = new LotteryToken(tokenName, tokenSymbol);
        purchaseRatio = _purchaseRatio;
         betPrice = _betPrice;
         betFee = _betFee;

        
    }
     /// @notice passes when the lottery is at closed state
     modifier whenBetsCLosed() {
        require(!betsOpen, "Lottery is still open");
     _;
     }
      /// @notice passes when the lottery is at closed state

        modifier whenBetsOpen() {
        require(betsOpen &&block.timestamp < betsClosingTime, "Lottery is closed");
        _;
     }

    /// @notice Opens the lottery bets
    function openBets(uint256 closingTime) external onlyOwner whenBetsCLosed{
        require(closingTime > block.timestamp, "Closing time must be in the future");
        betsClosingTime = closingTime;
        betsOpen = true;
        
    }
    /// @notice Give tokens based on the amount of ETH
    function purchaseTokens() external payable {
        paymentToken.mint(msg.sender, msg.value * purchaseRatio);
        
    }
 

      /// @notice charges the bet price and creates a new bet slot with the seders address
    function bet() public whenBetsOpen {
        ownerPool += betFee;
        prizePool += betPrice;        
        _slots.push(msg.sender);

        paymentToken.transferFrom(msg.sender, address(this), betPrice + betFee);
        
    }

    ///@notice Call the bt function `times` times
    function betMany(uint256 times) external {
        require(times>0);
        while (times > 0){
            bet();
            times--;
        }
    }

      /// @notice close the lottery and calculates the prize 
      /// @dev anyone can call the function if the oowner fails to do so
    function closeLottery() public {
       require(block.timestamp >= betsClosingTime, "Too soon to close");
       require(betsOpen, "Already  Closed");
       if(_slots.length>0) {
        uint256 winnerIndex = getRandomNumber() % _slots.length;
        address winner = _slots[winnerIndex];
        prize[winner] += prizePool;
        prizePool = 0;
        delete (_slots);
       }
       betsOpen == false;
        
    }
      /// @notice get random number calc from the previous block randao
      ///@dev This only works after the 
    function getRandomNumber() public view returns(uint256 randomNumber) {
        randomNumber = block.prevrandao;
        
    }


      /// @notice Withdraw `amount` from that accounts prize pool
    function prizeWithdraw(uint256 amount) external {
       require(amount <= prize[msg.sender], "Not enough prize");
       prize[msg.sender] -= amount;
        paymentToken.transfer(msg.sender, amount);
        
    }
      /// @notice Withdraws `amount` from the owner's pool
    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(amount <= ownerPool, "Not enough fees collected");
        ownerPool -= amount;
        paymentToken.transfer(msg.sender, amount);
    }


        /// @notice Burn `amount` of tokens and give the equivalent ETH back to user
    function returnTokens(uint256 amount) external {
        paymentToken.burnFrom(msg.sender, amount);
        payable(msg.sender).transfer(amount/purchaseRatio);
        
    }




}