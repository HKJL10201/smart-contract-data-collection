pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HedgrWallet.sol";

contract HedgrWalletFactory {
   mapping(address => address) userToWallet;
   mapping(address => address) walletToUser;

   uint public constant SNX_STIPEND = 50e18;

   address susdAddress = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
   address snxAddress = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;

   event WalletCreated(
       address indexed user,
       address indexed wallet
   );

    function initiate() public {
        HedgrWallet hedgr = new HedgrWallet(address(this));
        address hedgrAddress = address(hedgr);

        userToWallet[msg.sender] = hedgrAddress;
        walletToUser[hedgrAddress] = msg.sender;

        IERC20(snxAddress).transfer(hedgrAddress, SNX_STIPEND);
        emit WalletCreated(msg.sender, hedgrAddress);
    }

    function getUserWallet(address user) public view returns(address){
        return userToWallet[user];
    }

    function getWalletUser(address wallet) public view returns(address){
        return walletToUser[wallet];
    }
}