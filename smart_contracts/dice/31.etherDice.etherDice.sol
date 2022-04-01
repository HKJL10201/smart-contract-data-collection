pragma solidity >=0.4.22 <0.6.0;

// THIS CONTRACT CONTAINS A BUG - DO NOT USE

contract EtherDice {
    
    event LOG_RESULT(uint _number, uint _dice, address _winner);
    
    constructor() public payable {
        require(msg.value > 0.1 ether);
    }
    
    function roll() public view returns(uint) {
        return (block.timestamp % 6);
    }
    
    function bet(uint _number) public payable returns(bool) {
        require(_number >=0 && _number <=5, "_number is between 0 to 5");
        uint _dice = roll();
        
        if (_number == _dice) {
            msg.sender.transfer(msg.value*2);
            emit LOG_RESULT(_number, _dice, msg.sender);
            return true;
        }
        emit LOG_RESULT(_number, _dice, address(0x0));
        return false;
    }
    
    function getPool() public view returns(uint) {
        return address(this).balance;
    }
}
