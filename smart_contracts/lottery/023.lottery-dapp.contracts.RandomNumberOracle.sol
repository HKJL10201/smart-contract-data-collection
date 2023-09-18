pragma solidity ^0.5.0;

contract RandomNumberOracle{
    // @notice This function can be used to generate a random number based on the specific future blockhash
    // @dev The miner of the defined block number has the possiblity to withhold a mined block in order to manipulate the randomness.
    // @param min The lower boundary of the random range (min is part of the range)
    // @param max The upper boundary of the random range (max is part of the range)
    // @param blockNumber The block number which is used to create the random numbers
    // @return A random integer greater or equal to min and smaller or equal to max
    function getRandomNumber(uint256 min, uint256 max, uint256 blockNumber) public view returns(uint256){
        require(block.number > blockNumber);
        return (uint256(blockhash(blockNumber)) % (max - min + 1)) + min;
    }
}