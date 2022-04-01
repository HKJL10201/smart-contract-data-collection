pragma solidity >=0.5.0 <0.7.0;

contract ERC20 {
  function transfer(address recipient, uint256 amount) public returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);
}

contract EthBondManager {
  event DepositMade(address indexed account, address indexed token, uint256 indexed amount);
  event WithdrawalMade(address indexed account, address indexed token, uint256 indexed amount, address destination);
  event AllowProposal(address indexed account, address indexed proposal);
  event BondProcessed(address indexed account, address indexed proposal, address indexed token);

  struct Account {
    uint256 balance; // an account's total withdrawable balance (sum of deposits since last withdrawal)
    uint256 unlockBlock; // block number after which the balance can be withdrawn
  }

  mapping(bytes32 => Account) public accounts;
  mapping(bytes32 => bool) public approvals; // used to check if an account has approved its participation in a proposal

  function getAddressAddressKey(address addr1, address addr2) public pure returns (bytes32) {
    return sha256(abi.encodePacked(addr1, addr2));
  }

  function deposit(address token, uint256 amount) public {
    assert(ERC20(token).transferFrom(msg.sender, address(this), amount));
    bytes32 accountKey = getAddressAddressKey(msg.sender, token);

    uint256 balance = accounts[accountKey].balance;
    accounts[accountKey].balance += amount;
    assert(accounts[accountKey].balance > balance); // prevent overflow

    emit DepositMade(msg.sender, token, amount);
  }

  function withdraw(address token, address destination, uint256 amount) public {
    bytes32 accountKey = getAddressAddressKey(msg.sender, token);
    Account storage account = accounts[accountKey];
    assert(block.number > account.unlockBlock); // account's amount must not be banded to any proposals

    assert(amount <= account.balance); // prevent underflow
    account.balance -= amount; // all or nothing ETH withdrawal (in wei), before transfer to prevent reentrancy
    account.unlockBlock = uint256(0); // this is moot, but at least frees up some state and reclaims some gas

    assert(ERC20(token).transfer(destination, amount));
    emit WithdrawalMade(msg.sender, token, amount, destination);
  }

  function allow(address proposal) public {
    approvals[getAddressAddressKey(msg.sender, proposal)] = true; // calling account allows proposal to affect their account
    emit AllowProposal(msg.sender, proposal);
  }

  function processBond(address accountAddress, uint256 unlockBlock, address token) public {
    assert(approvals[getAddressAddressKey(accountAddress, msg.sender)]); // calling proposal can only deal with participating accounts

    bytes32 accountKey = getAddressAddressKey(accountAddress, token);
    Account storage account = accounts[accountKey]; // keep a copy to save on SLOAD as it will be reused later on

    if (account.unlockBlock < unlockBlock) {
      account.unlockBlock = unlockBlock; // bond the account's balance until voting for this proposal ends
    }

    emit BondProcessed(accountAddress, msg.sender, token);
  }
}
