pragma solidity 0.4.19;

import "./ERC20.sol";

/**
 * @title Time Locked Wallet
 */
contract TimeLockedWallet {
  // Define public variables (and getter methods)
  address public creator;
  address public owner;
  uint public unlockDate;
  uint public createdAt;
  
  // Restrict usage 
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  /**
   * @dev Constructor function 
   * @param _creator address - address creating the wallet.
   * @param _owner address - address that owns the wallet.
   * @param _unlockDate uint256 - UNIX date after which wallet is unlocked.
   */
  function TimeLockedWallet(
    address _creator,
    address _owner,
    uint256 _unlockDate
  ) public {
    // Set creator, owner, unlockDate and createdAt
    creator = _creator;
    owner = _owner;
    unlockDate = _unlockDate;
    // now is block timestamp - is not current
    createdAt = now;
  }
  
  /**
   * @dev Fallback function to keep all ether sent to this address
   */  
  function () payable public {
    // Call event 
    Received(msg.sender, msg.value);
  }
  
  /**
   * @dev Function to transfer ether after unlock date.  
   * @dev Only callable by owner of wallet. 
   */
  function withdraw() onlyOwner public {
    require(now >= unlockDate);
    // Send balance 
    msg.sender.transfer(this.balance);
    // Call event
    Withdrew(msg.sender, this.balance);
  }
  
  /**
   * @dev Function to transfer tokens after unlock date. 
   * @dev Only callable by owner of wallet. 
   * @param _tokenContract address - address of ERC20 token contract 
   */
  function withdrawTokens(address _tokenContract) onlyOwner public {
    require(now >= unlockDate);
    ERC20 token = ERC20(_tokenContract);
    // Send token balance 
    uint256 tokenBalance = token.balanceOf(this);
    token.transfer(owner, tokenBalance);
    WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
  }
  
  /**
   * @dev Function to return wallet information 
   * @return creator address
   * @return owner address 
   * @return unlockDate uint256  
   * @return createdAt uint256  
   * @return this.balance - balance of wallet 
   */
  function info() public view returns (address, address, uint256, uint256, uint256) {
    return (creator, owner, unlockDate, createdAt, this.balance);
  }
  
  /**
   * @dev Events to create log entries
   */
  event Received(address from, uint256 amount);
  event Withdrew(address to, uint256 amount);
  event WithdrewTokens(address tokenContract, address to, uint256 amount);  
}
