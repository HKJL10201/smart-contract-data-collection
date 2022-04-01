pragma solidity ^0.8.0;

contract ExpenseTracker {
    struct expenseInstance {
        address user;
        string message;
        uint256 amount;
        bool isEarning;
    }
    
    mapping (address => uint256) userBalance;
    mapping (address => expenseInstance[]) userExpenses;
    
    function addExpense(string memory message, uint256 amount, bool isEarning) external {
        require(isEarning || userBalance[msg.sender] >= amount, "The user does not have sufficient balance.");
        expenseInstance memory ei = expenseInstance(msg.sender, message, amount, isEarning);
        userExpenses[msg.sender].push(ei);
        isEarning ? userBalance[msg.sender] += amount : userBalance[msg.sender] -= amount;
    }
    
    function getMyExpenses() external view returns(expenseInstance[] memory) {
        return(userExpenses[msg.sender]);
    }
    
    function getUserBalance() external view returns(uint256) {
        return userBalance[msg.sender];
    }
}