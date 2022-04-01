pragma solidity >=0.8.7;

contract Mapping {
    mapping(address => uint) public balances;
    uint[3] public balanceArray;

    function updateBalance(uint _newBalance) public {
        balances[msg.sender] = _newBalance;
        balanceArray[0] = _newBalance;
        
    }
}
