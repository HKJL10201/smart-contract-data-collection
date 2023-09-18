pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    address public owner;

    constructor() public { //배포가 될때 실행됨
        owner = msg.sender;
    }

    function getSomeValue() public pure returns (uint256 value) {
        return 5;
    }
}