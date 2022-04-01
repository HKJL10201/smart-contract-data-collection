// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
import "@openzeppelin/contracts/access/Ownable.sol";
contract Lottery is VRFConsumerBase, Ownable {
    
      address payable public recentWinner;
    uint256 public fee;
    bytes32 public keyHash;
    uint256 public randomness;
    uint256 public usdFee;
    uint256 public randomResult;
    uint public costToEnter;
    address payable[] public players;
    uint nonce;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE{
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    constructor(address _priceFeedAddress,
    address _vrfCoordinator,
    address _link,
    uint256 _fee,
    bytes32 _keyHash) VRFConsumerBase(
        _vrfCoordinator, // VRF Coordinator
        _link  // LINK Token
        )Ownable(){
        keyHash =_keyHash ;
        fee = _fee;
        keyHash = _keyHash;
        usdFee=0.1 * 10 ** 18;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    lottery_state = LOTTERY_STATE.CLOSED;
    }
    function enter()public payable{
        require(lottery_state == LOTTERY_STATE.OPEN,'lottery is going ON WAIT!');
        require(msg.value>= getEntryFee(),'Amount is less then Fee!!!1');
        players.push(payable(msg.sender));
    }
    function getEntryFee()public returns(uint){
        (, int price,,,) = ethUsdPriceFeed.latestRoundData();
    uint256 Adjustprice= uint256(price) * 10**10;
    costToEnter = (fee *10**18) / Adjustprice;
    return costToEnter;
    }
    function startLottery()public onlyOwner{
        require(lottery_state == LOTTERY_STATE.CLOSED,'cant start a new lottery yet!!!');
        lottery_state = LOTTERY_STATE.OPEN;
    }
    function endLottery()public onlyOwner{
//uint(keccak256(abi.encodePacked(nonce,msg.sender,block.difficulty,block.timestamp))) %players.length;
    lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
    bytes32 requestId = requestRandomness(keyHash, fee);
    }
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)internal override{
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER,'you are not there yet');
    require(_randomness>0,"random-not-found");
    uint256 indexWinner = _randomness % players.length;
    recentWinner = players[indexWinner];
    recentWinner.transfer(address(this).balance);
    players = new address payable[](0);
    lottery_state = LOTTERY_STATE.CLOSED;
    randomness = _randomness;
    }
}