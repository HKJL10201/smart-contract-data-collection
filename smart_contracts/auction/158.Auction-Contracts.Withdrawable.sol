pragma solidity 0.5.11;

contract Withdrawable {
    mapping(address => uint) internal pendingWithdrawls;
    
    function withdraw() public returns(bool) {
        uint amount = pendingWithdrawls[msg.sender];
        if(amount > 0) {
            pendingWithdrawls[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
        return true;
    }
}
