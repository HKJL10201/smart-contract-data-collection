pragma solidity >=0.5.0 <0.7.0;

contract EthBondManager {
  event DepositMade(address indexed account, uint256 indexed amount);
  event WithdrawalMade(address indexed account, uint256 indexed amount, address indexed destination);
  event AllowProposal(address indexed account, address indexed proposal);
  event BondProcessed(address indexed account, address indexed proposal);

  struct Account {
    uint256 balance; // an account's total withdrawable balance (sum of deposits since last withdrawal)
    uint256 unlockBlock; // block number after which the balance can be withdrawn
  }

  mapping(address => Account) public accounts;
  mapping(bytes32 => bool) public approvals; // used to check if an account has approved its participation in a proposal

  function getAddressAddressKey(address addr1, address addr2) public pure returns (bytes32) {
    return sha256(abi.encodePacked(addr1, addr2));
  }

  function() external payable { // payable fallback redirects to deposit function (good for UX)
    deposit();
  }

  function deposit() public payable {
    accounts[msg.sender].balance += msg.value; // no need for safe math as the sum of all possible "value" on chain is less than MAX(uint256)
    emit DepositMade(msg.sender, msg.value);
  }

  function withdraw(address payable destination, uint256 amount) public {
    Account storage account = accounts[msg.sender];
    assert(block.number > account.unlockBlock); // account's amount must not be banded to any proposals

    assert(amount <= account.balance); // prevent underflow
    account.balance -= amount; // all or nothing ETH withdrawal (in wei), before transfer to prevent reentrancy
    account.unlockBlock = uint256(0); // this is moot, but at least frees up some state and reclaims some gas

    destination.transfer(amount);
    emit WithdrawalMade(msg.sender, amount, destination);
  }

  function allow(address proposal) public {
    approvals[getAddressAddressKey(msg.sender, proposal)] = true; // calling account allows proposal to affect their account
    emit AllowProposal(msg.sender, proposal);
  }

  function processBond(address accountAddress, uint256 unlockBlock, address) public {
    assert(approvals[getAddressAddressKey(accountAddress, msg.sender)]); // calling proposal can only deal with participating accounts

    Account storage account = accounts[accountAddress]; // keep a copy to save on SLOAD as it will be reused later on

    if (account.unlockBlock < unlockBlock) {
      account.unlockBlock = unlockBlock; // bond the account's balance until voting for this proposal ends
    }

    emit BondProcessed(accountAddress, msg.sender);
  }
}
