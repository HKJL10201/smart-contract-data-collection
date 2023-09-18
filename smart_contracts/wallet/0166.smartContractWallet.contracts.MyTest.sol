// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract MyTest {
    constructor() payable {
        //slot0 = Slot0(0, 0, 0, 0, 0, 0, true);

    }

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    Slot0 private slot0;

    function findSlot0() external view returns (Slot0 memory s){
        s = slot0;
        //require(false,"haha");
    }


}


contract Main {

    function main() external payable {
        MyTest myTest = new MyTest();
        console.log(myTest.findSlot0().unlocked);
        int8 a = 0x05;
        int b=0x05;
        require(a==b," a!=b");
    }

}
