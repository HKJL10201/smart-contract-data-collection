// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

contract BrakeWallet {
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed from, uint256 amount);

    mapping(address => uint256) balances;
    // updated lazily
    mapping(address => uint256) withdrawalForPeriod;
    uint256 immutable withdrawalLimit;
    uint256 immutable periodDuration;
    uint256 periodEnd;

    constructor(uint256 _withdrawalLimit, uint256 _periodDuration) {
        withdrawalLimit = _withdrawalLimit > 0 ? _withdrawalLimit : type(uint256).max;
        periodDuration = _periodDuration > 0 ? _periodDuration : 0;
        periodEnd = block.timestamp + periodDuration;
    }

    function updatePeriod(address from) internal {
        if (block.timestamp >= periodEnd) {
            periodEnd = block.timestamp + periodDuration;
            withdrawalForPeriod[from] = 0;
        }
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        updatePeriod(msg.sender);

        uint256 balance = balances[msg.sender];
        require(balance >= amount, "balance too low");
        require(
            withdrawalLimit - withdrawalForPeriod[msg.sender] >= amount && amount <= withdrawalLimit, "rate limited"
        );

        withdrawalForPeriod[msg.sender] += amount;
        balances[msg.sender] -= amount;

        emit Withdrawal(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    function balanceOf(address from) external view returns (uint256) {
        return balances[from];
    }
}
