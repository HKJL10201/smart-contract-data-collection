pragma solidity ^0.6.0;

contract wallet {
    address public owner;
    bool public pause;
    constructor() public {
        owner = msg.sender;
    }
    
    struct Payment {
        uint amount;
        uint timestamp;
    }
    
    struct Balance {
        uint totalBalance;
        uint numpay;
        mapping(uint => Payment) payments;
    }
    
    mapping(address => Balance) public balanceRecord;
    
    event sentMoney(address indexed address1, uint amount1);
    event recieveMoney(address indexed address1, uint amount1);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier notPause() {
        require(pause == false, "Contract is Paused");
        _;
    }
    
    function changePause(bool _pause) public onlyOwner {
        pause = _pause;
    }

    function sendMoney() public payable notPause {
        balanceRecord[msg.sender].totalBalance += msg.value;
        balanceRecord[msg.sender].numpay += 1;
        Payment memory pay = Payment(msg.value, now);
        balanceRecord[msg.sender].payments[balanceRecord[msg.sender].numpay] = pay;
        emit sentMoney(msg.sender, msg.value);
    }
    
    function getBalance() public view notPause returns (uint) {
        return balanceRecord[msg.sender].totalBalance;
    }
    
    function convertToEth(uint _amountInWei) public pure  returns (uint) {
        return _amountInWei/1 ether;
    }
    
    function withdraw(uint _amount) public notPause {
        require(balanceRecord[msg.sender].totalBalance >= _amount, "Not Enough Funds");
        balanceRecord[msg.sender].totalBalance -= _amount;
        msg.sender.transfer(_amount);
        emit recieveMoney(msg.sender, _amount);
    }
    
    function destroy(address payable ender) public onlyOwner {
        selfdestruct(ender);
    }
}