pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract RandomNumberGenerator is VRFConsumerBase, ConfirmedOwner(msg.sender) {
  bytes32 internal keyHash;
  uint256 internal fee;
  address public lottery;
  uint256 public randomResult;

  /**
   * Constructor inherits VRFConsumerBase
   *
   * Network: Kovan
   * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
   * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
   * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
   */
  modifier onlyLottery() {
    require(msg.sender == lottery, 'Only Lottery can call function');
    _;
  }

  constructor(
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint256 _fee,
    address _lottery
  ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
    keyHash = _keyHash;
    fee = _fee;
    lottery = _lottery;
  }

  /**
   * Requests randomness
   */

  function getRandomNumber(uint256 userProvidedSeed) external onlyLottery returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, 'Not enough LINK - fill contract with faucet');
    return requestRandomness(keyHash, fee);
  }

  // It's possible to get multiple numbers from a single VRF response:
  function expand(uint256 randomValue, uint256 n) external pure returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
      expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
    }
    return expandedValues;
  }

  function getRandomResult() external view returns (uint256) {
    return randomResult;
  }

  /**
   * Callback function used by VRF Coordinator
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    randomResult = randomness;
  }

  function withdrawLINK(address to, uint256 value) public onlyOwner {
    require(LINK.transfer(to, value), 'Not enough LINK');
  }

  /**
   * @notice Set the oracle fee for requesting randomness
   *
   * @param _fee uint256
   */
  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
  }

  /**
   * @notice Set the key hash for the oracle
   *
   * @param _keyHash bytes32
   */
  function setKeyHash(bytes32 _keyHash) public onlyOwner {
    keyHash = _keyHash;
  }

  /**
   * @notice Get the current key hash
   *
   * @return bytes32
   */
  function viewKeyHash() public view returns (bytes32) {
    return keyHash;
  }

  /**
   * @notice Get the current fee
   *
   * @return uint256
   */
  function viewFee() public view returns (uint256) {
    return fee;
  }
}
