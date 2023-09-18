pragma solidity >=0.8.0 <0.9.0;

interface IRandomNumberGenerator {
  /**
   * Requests randomness from a user-provided seed
   */
  function expand(uint256 randomValue, uint256 n) external pure returns (uint256[] memory expandedValues);

  function getRandomResult() external view returns (uint256);

  function getRandomNumber(uint256 userProvidedSeed) external returns (bytes32 requestId);
}
