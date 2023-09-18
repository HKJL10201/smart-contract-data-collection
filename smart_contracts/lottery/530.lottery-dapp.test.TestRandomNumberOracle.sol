pragma solidity ^0.5.0;

import "truffle/DeployedAddresses.sol";
import "../contracts/RandomNumberOracle.sol";

contract TestRandomNumberOracle {
    // The address of the RandomNumberOracle contract to be tested
    RandomNumberOracle oracle = RandomNumberOracle(DeployedAddresses.RandomNumberOracle());
    
    // The block number which is responisble for the random number generation
    uint blockNumber = block.number - 1;

    // Testing the getRandomNumber() function 
    // !!! MUST NOT BE SET TO view !!!
    function testRandomNumberGeneration() public {
        uint randomNumber = oracle.getRandomNumber(blockNumber);
        require( randomNumber < 43 && randomNumber > 0, "Random number is not within the correct range.");
    }

    function testSixRandomNumberGeneration() public{
        uint[] memory randomNumbers = new uint[](6);
        randomNumbers = oracle.getSixRandomNumbers(blockNumber);

        for(uint i = 0; i < 6; i++){
            require( randomNumbers[i] < 43 && randomNumbers[i] > 0, "Random number is not within the correct range.");
        }
    }
}