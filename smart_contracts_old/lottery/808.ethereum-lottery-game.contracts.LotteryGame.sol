// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract LotteryGame is VRFConsumerBase {
    
    // Rinkeby test network access //
    address constant internal vrfCordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
    address constant internal linkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 constant internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    uint256 constant internal fee =  0.1 * 10 ** 18;
    // ### //

    bytes32 internal reqId;

    uint256 public soldTickets = 0;
    address public lotteryOwner;
    uint256 public resultNumber;
    bool public isNumberDrawn = false;
    
    address[] internal playerAddresses;
    uint256[] internal playerBets;

    constructor() VRFConsumerBase(vrfCordinator, linkToken) public {
        lotteryOwner = msg.sender;
    }
    
    function purchaseTicket(uint256 amountInWei, uint8 lotteryNumber) public payable {
        require(msg.value == amountInWei);
        require(lotteryNumber >= 0 && lotteryNumber < 10);
        
        playerAddresses.push(msg.sender);
        playerBets.push(lotteryNumber);
        soldTickets++;
    }

    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to get a random number - fill contract with faucet");
        require(msg.sender == lotteryOwner, "Only the owner can draw the lottery.");
        require(soldTickets > 0, "No tickets sold yet.");
        
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }
    
    function endDraw() public {
        require(msg.sender == lotteryOwner, "Only the owner can end the lottery.");
        require(isNumberDrawn == true, "No number has been drawn.");
        
        address payable winner = getWinnerAddress(resultNumber);
        
        if (winner != address(0)) {
            payWinner(winner);
        }
        
        resetLottery();
    }

    function payWinner(address payable winner) internal {
        winner.transfer(address(this).balance);
    }
    
    function getWinnerAddress(uint256 drawnNumber) internal view returns (address payable) {
        uint256 playersCount = playerAddresses.length;
        
        for (uint256 i = 0; i < playersCount; i++) {
            uint256 userDrawnNumber = playerBets[i];
            
            if (userDrawnNumber == drawnNumber) {
                return payable(playerAddresses[i]);
            }
        }
        
        return address(0);
    }
    
    function getBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        resultNumber = randomness % 10;
        reqId = requestId;
        
        isNumberDrawn = true;
    }
    
    function resetLottery() internal {
        soldTickets = 0;
        resultNumber = 0;
        isNumberDrawn = false;
        delete playerAddresses;
        delete playerBets;
    }
}