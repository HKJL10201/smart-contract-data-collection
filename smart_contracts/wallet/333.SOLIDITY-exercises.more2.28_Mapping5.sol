pragma solidity >=0.8.7;

contract LedgerBalance {
    mapping(address => uint) public ledgerBalances;

    function addValue(uint newBalance) public {
        ledgerBalances[msg.sender] = newBalance;
    }

    mapping(uint => string) public clients;

    function addValue2(uint order, string memory clientName) public {
        clients[order] = clientName;
    }
}

