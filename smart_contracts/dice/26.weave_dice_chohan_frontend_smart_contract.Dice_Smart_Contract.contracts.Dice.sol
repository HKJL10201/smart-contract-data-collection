// contracts/Dice.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dice is Ownable {

    IERC20 betToken = IERC20(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);  // BUSD test token
    struct BetInfo {
        address user;
        uint8 currentNumber1;
        uint8 currentNumber2;
        bool isEven;
        uint256 amount;
        BettingStatus status;
    }
    enum BettingStatus {Initial, Hide, Shown}
    BetInfo[] betInfo;
    mapping(address=>BetInfo) userInfo;
    mapping(address=>uint256) claimInfo;
    event ShowResult(address user, uint8 currentNumber1, uint8 currentNumber2, bool isEven, uint256 amount);

    constructor()
    {
    }

    function roll(uint256 amount, bool isEven) external {
        require(userInfo[msg.sender].status == BettingStatus.Initial, "R");
        uint8 A = uint8(random(0));
        uint8 B = uint8(random(A));
        userInfo[msg.sender] = BetInfo(msg.sender, A, B, isEven, amount, BettingStatus.Shown);
        betInfo.push(userInfo[msg.sender]);
        betToken.transferFrom(msg.sender, address(this), amount);
        emit ShowResult(msg.sender, userInfo[msg.sender].currentNumber1, userInfo[msg.sender].currentNumber2, userInfo[msg.sender].isEven, userInfo[msg.sender].amount);
    }

    function claim() external {
        uint8 res = userInfo[msg.sender].isEven ? 0 : 1;
        if(res == (userInfo[msg.sender].currentNumber1 + userInfo[msg.sender].currentNumber2) % 2) {
            betToken.transfer(msg.sender, userInfo[msg.sender].amount * 2);
        }
        userInfo[msg.sender].status = BettingStatus.Initial;
    }

    function getLast10Result() external view returns(BetInfo[10] memory result) {
        uint256 i = betInfo.length;
        uint256 j = 0;
        while(i > 0) {
            result[j++] = betInfo[--i];
            if(j == 10) break;
        }
    }

    function withDrawToken(uint256 amount) external onlyOwner {
        betToken.transfer(msg.sender, amount);
    }
    function random(uint256 factor) private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender, factor))) % 6 + 1;
    }

}