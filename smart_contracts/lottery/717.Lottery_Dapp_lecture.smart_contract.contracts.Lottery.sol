// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {

    address public owner;

    // 배포가 될때 가장먼저 실행되는 함수
    // 배포가 될때 보낸사람으로 owner를 지정하겠다.
    constructor() public {
        owner = msg.sender;
    }

    function getSomeValue() public pure returns (uint256 value) {
        return 5;
    }
}