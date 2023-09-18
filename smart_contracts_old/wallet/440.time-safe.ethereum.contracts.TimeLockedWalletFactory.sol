pragma solidity 0.4.19;

import "./TimeLockedWallet.sol";

/**
 * @title TimeLockedWalletFactory
 */
contract TimeLockedWalletFactory {
  // Create mapping of owner address to array of owner's wallets
  mapping(address => address[]) wallets;
  
  /**
   * @dev Function to get user's wallets 
   * @param _user address 
   * @return wallets [] - array of wallet addresses
   */ 
  function getWallets(address _user)
    public
    view
    returns(address[])
  {
    return wallets[_user];
  }

  /**
   * @dev Function to create new wallet 
   * @param _owner address - Address of owner of new wallet  
   * @param _unlockDate uint256 - UNIX date when new wallet is unlocked  
   * @return wallet address - Address of new wallet
   */   
  function newTimeLockedWallet(address _owner, uint256 _unlockDate)
    payable
    public 
    returns(address wallet)
  {
    // Create new wallet 
    wallet = new TimeLockedWallet(msg.sender, _owner, _unlockDate);
    
    // Add wallet to sender's wallets 
    wallets[msg.sender].push(wallet);
    
    // If sender is not owner then add to owner's wallets
    if (msg.sender != _owner) {
      wallets[_owner].push(wallet);
    }
    
    // Send ether from transaction to created contract 
    wallet.transfer(msg.value);
    
    // Emit event 
    Created(wallet, msg.sender, _owner, now, _unlockDate, msg.value);
  }
  
  /**
   * @dev Fallback function to prevent accidental transfer to factory
   */   
  function () public {
    revert();
  }
  
  /**
   * @dev Event to log created wallet 
   */  
  event Created(
    address wallet, 
    address from,
    address to,
    uint256 createdAt,
    uint256 unlockDate,
    uint256 amount
  );
}
