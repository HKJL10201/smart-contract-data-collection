//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./TimeLockedWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Factory to create and manage TimeLockedWallet contracts.

contract TimeLockedWalletFactory is Ownable {
    // wallets owned by each user.
    mapping(address => address[]) userWallets;

    uint256 public unlockDate;

    event UnlockDateChanged(uint256 oldValue, uint256 newValue);
    event WalletCreated(address wallet, address owner, uint256 unlockDate);

    function setUnlockDate(uint256 _newUnlockDate) public onlyOwner {
        uint256 oldDate = this.unlockDate();
        unlockDate = _newUnlockDate;
        emit UnlockDateChanged(oldDate, _newUnlockDate);
    }

    function getUserWallets(address user)
        public
        view
        returns (address[] memory)
    {
        return userWallets[user];
    }

    // creates a new TimeLockedWallet for the user, returns the wallet address.
    // msg.sender is the user creating the wallet for someone else
    // owner is the wallet's owner, who'll be able to withdrawal funds after a time-lock delay
    function addWallet(address owner) external returns (address newWallet) {
        newWallet = address(
            new TimeLockedWallet(address(this), owner, unlockDate)
        );
        userWallets[owner].push(newWallet);

        emit WalletCreated(newWallet, owner, unlockDate);
    }
}
