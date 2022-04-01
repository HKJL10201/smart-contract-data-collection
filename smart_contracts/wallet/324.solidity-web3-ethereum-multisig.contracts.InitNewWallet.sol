pragma solidity ^0.5.8;

import "./MultiSig.sol";

contract InitNewWallet {
    address public newWalletAddress = 0x0000000000000000000000000000000000000000;

    function initNewWallet(address _owner1, address _owner2) public {
        newWalletAddress = address(new MultiSig(_owner1, _owner2));
    }

    function get() public view returns (address) {
        return newWalletAddress;
    }

}
