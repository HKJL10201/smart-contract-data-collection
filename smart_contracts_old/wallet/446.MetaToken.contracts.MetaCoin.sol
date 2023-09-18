pragma solidity >=0.4.21 <0.7.0;

contract MetaCoin {
    event Deposit(address indexed _from, uint256 _amount);
    event Withdraw(address indexed _beneficiary, uint _amount);

    mapping (address => uint256) balances;
    mapping (address => uint) counter;

    function depositMoney() public payable {
        require(msg.value >= 100000000000000000, "Minimum 0.1 ether to deposit");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawMoney(address payable _to, uint _amount) public {
        require(_amount <= balances[msg.sender], "You doesn't own enough money");
        require(counter[msg.sender] >= 10, "Counter must be more than 10");
        require(_to == msg.sender, "You can't withdraw from other wallet");
        emit Withdraw(msg.sender, _amount);
        _to.transfer(_amount);
        balances[msg.sender] -= _amount;
        counter[msg.sender] = 0;
    }

    function getBalance() public view returns(uint256) {
        return balances[msg.sender];
    }

    function addCounter() public {
        counter[msg.sender] += 1;
    }

    function getCounter() public view returns(uint) {
        return counter[msg.sender];
    }
}