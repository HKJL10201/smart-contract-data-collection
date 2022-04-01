// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRandomNumberGenerator.sol";

contract Lottery is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    ///@notice Event emitted when new lottery is started
    event newLotteryStarted(uint _endTime);

    /// @notice Event emitted when lottery status are modified
    event changeLotteryStatus(bool _lotteryStatus);

    /// @notice Event emitted when Tickets are bought
    event buyTicketSuccessed(
        address _buyer,
        lotteryTicket[] _lotterylist,
        uint _totalcostTickets
    );

    /// @notice Event emitted when cost per ticket are modified
    event changeCostPerTicket(uint _amount);

    /// @notice Event emitted when lotter is ended
    event results(
        uint _jackpotWinnersNum,
        uint _runnerUpWinnersNum,
        uint _jacpotPrice,
        uint _runnerUpPrice
    );

    /// @notice Event emitted when fee wallet is modified
    event changeDevWallet(address _devWallet);

    /// @notice Event emitted when the NLIFE token is modified
    event tokenChanged(address newTokenAddr);

    /// @notice Event emitted when the RNG is modified
    event RNGChanged(address _RNGAddr);

    /// @notice Event emitted when the erc20 token is withdrawn.
    event ERC20TokenWithdrew(address token, uint256 amount);

    modifier onlyRNG() {
        require(
            msg.sender == address(RNG),
            "Lottery: Caller is not the RandomNumberGenerator"
        );
        _;
    }

    struct lotteryTicket {
        uint firNum;
        uint secNum;
        uint thdNum;
    }
    lotteryTicket public winnerConditionNum;
    
    address[] public jackpotWinners;
    address[] public runnerUpWinners;
    address[] public players;

    address devWallet;
    IERC20 NLIFE;
    uint public costPerTicket;
    uint public endTime;
    bool public lotteryStatus = false;
    IRandomNumberGenerator RNG;

    mapping(address => lotteryTicket[]) public lotteryMap;
    mapping(address => bool) public isUser;
    
    /**
     * @dev Constructor function
     * @param _NLIFE Interface of NLIFE
     * @param _costPerTicket Ticket price
     * @param _devWallet Fee Wallet Address
     */
    constructor(IERC20 _NLIFE, address _devWallet, uint _costPerTicket, IRandomNumberGenerator _RNG)
    {
        NLIFE = _NLIFE;
        devWallet = _devWallet;
        costPerTicket = _costPerTicket;
        RNG = _RNG;
    }
    
    /**
     * @dev public function to start new lottery
     */
    function startNewLottery() private {
        require(lotteryStatus == true, "Lottery: Lottery is not opened");
        endTime = block.timestamp + 30 seconds;

        emit newLotteryStarted(endTime);
    }

    /**
     * @dev external function to change lotterystatue
     */
    function toggleLottery() external onlyOwner  {
        lotteryStatus = !lotteryStatus;
        if(lotteryStatus == true) {
            startNewLottery();
        }
        emit changeLotteryStatus(lotteryStatus);
    }

    /**
     * @dev external function to but tickets
     * @param _tickets List of tickets the player wants to buy
     */
    function buyTickets(lotteryTicket[] memory _tickets) external nonReentrant {
        require(lotteryStatus == true, "Lottery: Lottery is not opened");
        require(_tickets.length > 0, "Lottery: Ticket list is 0");

        uint totalcostTickets = costPerTicket * _tickets.length;
        uint256 fee = totalcostTickets * 76923 / 1000000;

        for(uint i = 0; i < _tickets.length; i++) {
            require(
                _tickets[i].firNum <= 25 &&
                _tickets[i].secNum <= 25 &&
                _tickets[i].thdNum <= 25,
                "Lottery: Lottery number must be less than 25"
            );
            lotteryMap[msg.sender].push(_tickets[i]);        
        }
        if(!isUser[msg.sender]) {
            players.push(msg.sender);
            isUser[msg.sender] == true;
        }

        NLIFE.safeTransferFrom(msg.sender, devWallet, fee);
        NLIFE.safeTransferFrom(msg.sender, address(this), totalcostTickets - fee);
        
        emit buyTicketSuccessed(msg.sender, _tickets, totalcostTickets);
    }

    /**
     * @dev private function to allow anyone draw lottery  from chainlink VRF if timestamp is correct
     */
    function drawLottery() external nonReentrant {
        require(
            block.timestamp >= endTime,
            "Lottery: Not ready to close to lottery yet"
        );
        RNG.getRandomNumber();
        RNG.getRandomNumber();
        RNG.getRandomNumber();
    }

    /**
     * @dev judgement function to be packpotwinner or runnerUpWinner
     * @param _result lottery number for winner
     * @param _player lottery number for player
     * @return 1 when packPotWinner, 2 when runnerUpWinner, 3 when nothing
     */
    function judgement(lotteryTicket memory _result, lotteryTicket memory _player) private pure returns(uint) {
        if (_result.firNum == _player.firNum && _result.secNum == _player.secNum && _result.thdNum == _player.thdNum) {
            return 1;
        } else if((_result.firNum == _player.firNum && _result.secNum == _player.secNum) || (_result.secNum == _player.secNum && _result.thdNum == _player.thdNum) || (_result.firNum == _player.firNum && _result.thdNum == _player.thdNum)) {
            return 2;
        } else {
            return 3;
        }
    }

    /**
     * @dev private function to send reward to winners
     */
    function playerReward() private {
        uint balance = NLIFE.balanceOf(address(this));
        uint jackPotPrice = 0;
        uint runnerUpPrice = 0;
        if(jackpotWinners.length != 0) {
            if(runnerUpWinners.length != 0) {
                //jackpotWinners earn 80%
                //runnerUpWinners earn 20%
                jackPotPrice = (balance * 8 / 10) / jackpotWinners.length;
                runnerUpPrice = (balance - jackPotPrice) / runnerUpWinners.length;
                for(uint index = 0; index < jackpotWinners.length; index++) {
                    NLIFE.safeTransfer(jackpotWinners[index], jackPotPrice);
                }
                for(uint index = 0; index < runnerUpWinners.length; index++) {
                    NLIFE.safeTransfer(runnerUpWinners[index], runnerUpPrice);
                }
            } else {
                //jackpotWinners earn 100%
                jackPotPrice = balance;
                for(uint index = 0; index < jackpotWinners.length; index++) {
                    NLIFE.safeTransfer(jackpotWinners[index], jackPotPrice);
                }
            }
        } else {
            if(runnerUpWinners.length != 0) {
                //runnerUpWinners earn 20%
                runnerUpPrice = (balance * 2 / 10) / runnerUpWinners.length;
                for(uint index = 0; index < runnerUpWinners.length; index++) {
                    NLIFE.safeTransfer(runnerUpWinners[index], runnerUpPrice);
                }
            }
        }
        emit results(
            jackpotWinners.length,
            runnerUpWinners.length,
            jackPotPrice,
            runnerUpPrice
        );

        jackpotWinners = new address[](0);
        runnerUpWinners =  new address[](0);
        players = new address[](0);
    }

    /**
     * @dev private function to declare winner in this lottery
     */
    function declareWinner(uint256[] memory _randomness) external onlyRNG {

        require(block.timestamp >= endTime);
        winnerConditionNum.firNum = _randomness[0] % 26;
        winnerConditionNum.secNum = _randomness[1] % 26;
        winnerConditionNum.thdNum = _randomness[2] % 26;

        for(uint i = 0; i < players.length; i++) {
            for(uint j = 0; j < lotteryMap[players[i]].length; j++) {
                uint result = judgement(winnerConditionNum, lotteryMap[players[i]][j]);
                if(result == 1) {
                    jackpotWinners.push(players[i]);
                } else if(result == 2) {
                    runnerUpWinners.push(players[i]);
                }
            }
        }
        playerReward();
        startNewLottery();
    }

    /**
     * @dev function to change cost per ticket
     * @param _amount Cost per ticket to change
     */
    function setcostPerTicket(uint _amount) external onlyOwner {
        costPerTicket = _amount;
        emit changeCostPerTicket(_amount);
    }

    /**
     * @dev external function to change fee wallet address
     */
    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
        emit changeDevWallet(devWallet);
    }

    /**
     * @dev external function to change Token
     */
    function changeToken(address _NLIFEAddr) external onlyOwner {
        NLIFE = IERC20(_NLIFEAddr);

        emit tokenChanged(_NLIFEAddr);
    }

    /**
     * @dev external function to change RNG
     */
    function changeRNG(address _RNGAddr) external onlyOwner {
        RNG = IRandomNumberGenerator(_RNGAddr);

        emit RNGChanged(_RNGAddr);
    }

    /**
     * @dev External function to withdraw any erc20 tokens. This function can be called by only owner.
     * @param _tokenAddr ERC20 token address
     */
    function withdrawERC20Token(address _tokenAddr) external onlyOwner {
        IERC20 token = IERC20(_tokenAddr);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));

        emit ERC20TokenWithdrew(_tokenAddr, token.balanceOf(address(this)));
    }

}