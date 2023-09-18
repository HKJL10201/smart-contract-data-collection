pragma solidity ^0.4.18;


contract RandNum {
  uint randNonce = 0;
  
  // return the random vlaue 0 ~ _randMax - 1
  function _genRand(uint _randMax) internal returns(uint) {
    
    uint random = uint(keccak256(now, msg.sender, randNonce)) % _randMax;
    randNonce++;

    return random;
  }

  function _resetNonce() internal returns (uint) {
    
    if (128 == randNonce) {
      randNonce = 0;
    }
  }

  function getRand(uint _maxNum) external returns (uint) {
    
    return _genRand(_maxNum);
  }
}

