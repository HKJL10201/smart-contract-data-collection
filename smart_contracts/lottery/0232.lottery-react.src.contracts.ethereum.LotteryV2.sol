pragma solidity 0.8.7;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// 
// Players must submit a minimum ammount of 0.02 ETH to enter into the lottery pool.
// After all players have entered, the manger address(account that deployed contract) 
// can call the pickWinner() function. The winning will be picked using a Chainlink random number
// generator and the winning address with receive all ETH in the lottery pool. After the lottery winner is 
// selected the smart contacts state will reset and a new lottery round can start.
// Enjoy.
//
// ---------------------------------------------------------------------------- 
// ----------------------------------------------------------------------------
// Updated     : To support Solidity version 0.8.7
// Programmer  : Idris Bowman (www.idrisbowman.com)
// Link        : https://idrisbowman.com
// ----------------------------------------------------------------------------
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract LotteryV2 is VRFConsumerBase {
    using SafeMath for uint;

    address public manager;
    address[] public players;
    address public lastWinner;
    uint256 public currentRound;

    // keep track player entered history for each round
    mapping(address => mapping(uint256 => bool)) public playerLotteryHistory;
    
    // random number vars
    address public linkToken;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    bytes32 public reqId;

    // Events
    event PlayerEntered(
        uint256 round,
        uint256 amount,
        address playersEntered,
        address[] players
    );
    event WinnerPicked(uint256 round, address winningPlayer, uint256 winningNumber);
    event RandomLanded(bytes32 indexed requestId, uint256 indexed result);

    /**
     * @notice Constructor inherits VRFConsumerBase
     * 
     * @dev network: Kovan
     * @dev  Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * @dev  LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * @dev  Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     * @dev   Fee:        0.1 LINK (100000000000000000)
     * 
     * @param _vrfCoordinator address of the VRF Coordinator
     * @param _linkToken address of the LINK token
     * @param _keyHash bytes32 representing the hash of the VRF job
     * @param _fee uint256 fee to pay the VRF oracle
     */
    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee)
     VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _linkToken  // LINK Token
        )
    {
        manager = msg.sender;
        currentRound = 1;
        keyHash = _keyHash;
        fee = _fee;
        linkToken = _linkToken; 
    }
    
    function enter() external payable {
        require(playerLotteryHistory[msg.sender][currentRound] != true, "Only allowed to enter once per round");
        require(msg.sender != manager,  "Manager not allowed into enter lottery");
        require(msg.value > .01 ether, "Not enough ETH - you need minumum of 0.02ETH to enter");
        players.push(msg.sender);
        playerLotteryHistory[msg.sender][currentRound] = true;
        emit PlayerEntered(currentRound, msg.value, msg.sender, players);
    }
    
    function pickWinner() external restricted  {
        uint256 _winningIndex;
        getRandomNumber();
        _winningIndex =  randomResult.mod(players.length).add(1);
        
        payable(players[_winningIndex]).transfer(address(this).balance);
        lastWinner = players[_winningIndex];
        currentRound ++;
        players = new address[](0);
        emit WinnerPicked(currentRound,lastWinner, _winningIndex);
    }
    
    modifier restricted() {
        require(msg.sender == manager, "Not the manager of this contract");
        _;
    }
    
    function getPlayers() external view returns (address[] memory) {
        return players;
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 _requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

     /**
     * @notice Callback function used by VRF Coordinator to return the random number
     * to this contract.
     * @param requestId bytes32
     * @param randomness The random result returned by the oracle
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        reqId = requestId;
        emit RandomLanded(requestId, randomResult);
    }
    
    function withdrawLink() external restricted {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Not enough LINK");
    }
}