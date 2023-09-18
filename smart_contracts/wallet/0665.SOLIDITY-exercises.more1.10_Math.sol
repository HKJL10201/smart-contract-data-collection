pragma solidity >=0.8.7;

import "./SafeMath.sol";

contract Math {
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    uint256 public myUint256 = 255;
    uint32 public myUint32 = 45;

    function addUint256() public {
        myUint256 = myUint256.add(5);
    }
    function addUint32() public {
        myUint32 = myUint32.add(5);
    }

}