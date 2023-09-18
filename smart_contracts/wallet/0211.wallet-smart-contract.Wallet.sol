// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Wallet {
    struct Account {
        address accountOwner;
        uint etherBalance;
        uint accountId;
    }

    mapping (address => bool) depositors;
    mapping (address => Account) public accounts;
    uint private totalDepositors = 0;
    uint private totalBalance = 0;

    function depositEther() public payable {
        require(msg.value > 0, "Must deposit more than 0.");
        if (depositors[msg.sender] == false) {
            depositors[msg.sender] = true;
            Account memory newDepositor = Account(msg.sender, msg.value, totalDepositors);
            accounts[msg.sender] = newDepositor;
            totalDepositors++;
            totalBalance += msg.value;
        } else {
            Account storage existingDepositor = accounts[msg.sender];
            existingDepositor.etherBalance += msg.value;
        }
    }

    function withdrawEther(uint _withdrawalRequest) public {
        require(depositors[msg.sender] == true, "No account found. Send Ether via the deposit function to establish an account.");

        Account storage withdrawer = accounts[msg.sender];
        require(withdrawer.etherBalance >= _withdrawalRequest, "Withdrawal request must not be larger than the account balance.");
        
        withdrawer.etherBalance -= _withdrawalRequest;
        payable(msg.sender).transfer(_withdrawalRequest);
    }
}