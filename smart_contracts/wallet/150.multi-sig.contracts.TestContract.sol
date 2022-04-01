pragma solidity 0.8.4;

contract TestContract {
    uint256 public i;

    constructor(){}

    function callMe(uint256 j) public {
        i += j;
    }

    function getData(uint256 j) public pure returns (bytes memory){
        // return callMe(123);
        return abi.encodeWithSignature("callMe(uint256)", j);
    }
}