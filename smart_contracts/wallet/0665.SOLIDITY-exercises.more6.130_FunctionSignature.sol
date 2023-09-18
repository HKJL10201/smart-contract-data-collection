//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract FunctionSelector {
    event LogTransfer(bytes data);

    function transfer(address _to, uint _amount) external {
        emit LogTransfer(msg.data);
    }
    /*
    The msg.data of above function when we call it with some parameters(an address and number 10):
    0xa9059cbb000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2000000000000000000000000000000000000000000000000000000000000000a
    
    BREAKDOWN OF ABOVE BYTES STRING:
    1) function signature: "transfer(address,uint256)"
    2) the first 4 bytes is encoded function signature:
    bytes4(keccak256(bytes("transfer(address,uint256)"))) = 0xa9059cbb
    3) encoded first parameter(an address that I randomly chose):
    000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2
    4) encoded second parameter(number 10)
    000000000000000000000000000000000000000000000000000000000000000a
    */ 

   
}

contract Test {
    // I can see above msg.data with event log. Or I can even see it with a return function.
    function getFunction() external pure returns(bytes4){
        return bytes4(keccak256(bytes("transfer(address,uint256)")));
    }

    function getFunction2(string calldata x) external pure returns(bytes4){
        return bytes4(keccak256(bytes(x)));
    }
}