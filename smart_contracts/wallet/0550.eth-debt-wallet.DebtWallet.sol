pragma solidity ^0.4.18;

import "./Ownable.sol";

contract DebtWallet is Ownable {
    struct Expense {
        address creditor;
        uint amount;
        bool approved;
        bool settled;
        string description;
        string whois;
    }

    event NewExpense(uint expenseId, address creditor, uint amount, string nickname);
    event NewCreditor(address creditor, string whois);
    event ApprovalChanged(uint expenseId, bool approved);
    event DebtPaid(uint expenseId);

    Expense[] public expenses;

    mapping (uint => address) expenseToCreditor;
    mapping (address => uint) creditorExpenseCount;
    mapping (address => string) creditorNicknames;

    function addExpense(uint _amount, string _description, string _whois) external {
        bytes creditorNicknameBytes = bytes(creditorNicknames[msg.sender]);
        require(creditorNicknameBytes.length > 0 || bytes(_whois).length > 0);

        uint _id = expenses.push(Expense(msg.sender, _amount, false, false, _description, _whois)) - 1;
        expenseToCreditor[_id] = msg.sender;
        creditorExpenseCount[msg.sender]++;
        if (creditorNicknameBytes.length == 0) {
            NewCreditor(msg.sender, _whois);
        }
        NewExpense(_id, msg.sender, _amount, creditorNicknames[msg.sender]);
    }

    function changeApproval(uint _id, bool _approved) external onlyOwner {
        require(expenses[_id].approved != _approved);
        expenses[_id].approved = _approved;
        ApprovalChanged(_id, _approved);
    }

    function identifyCreditor(address _creditor, string _nickname) external onlyOwner {
        creditorNicknames[_creditor] = _nickname;
    }

    function getExpenses(address _creditor) external view returns(uint[]) {
        require(msg.sender == _creditor || msg.sender == owner);
        uint records = creditorExpenseCount[_creditor];

        uint[] memory result = new uint[](records);
        uint counter = 0;
        for (uint i = 0; i <= expenses.length; i++) {
            if (expenseToCreditor[i] == _creditor) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getExpense(uint _id) external view returns (address creditor, string creditorNickname, uint amount, string description, string whois, bool approved, bool settled) {
        Expense storage _myExpense = expenses[_id];
        require(msg.sender == _myExpense.creditor || msg.sender == owner);

        creditor = _myExpense.creditor;
        creditorNickname = creditorNicknames[_myExpense.creditor];
        amount = _myExpense.amount;
        description = _myExpense.description;
        whois = _myExpense.whois;
        approved = _myExpense.approved;
        settled = _myExpense.settled;
    }

    function payDebt(uint _id) external payable onlyOwner {
        Expense storage expenseToPay = expenses[_id];
        require(expenseToPay.approved == true);
        expenseToPay.creditor.transfer(expenseToPay.amount);
        expenseToPay.settled = true;
        DebtPaid(_id);
    }
}
