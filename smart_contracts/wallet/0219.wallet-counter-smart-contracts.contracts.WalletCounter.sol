// SPDX-License-Identifier: NONE
pragma solidity 0.8.12;


/**
 *
 * @author Bhupesh Dubey
*/
contract WalletCounter {

    // mapping to check wallet address is new or old
    mapping(address => bool) private doesWalletExists;

    // totalNoOfWallets holds all unique wallet count
    uint private totalNoOfWallets; 
  
    // totalValue holds sum of all numbers entered by the user
    int private totalValue;

    // event to be emitted when new number is entered by the user
    event NumberEntered(address walletAddress, int numberEntered);

    /**
     *
     * @notice this method gives total value & total wallets who entered the value
       @return returns int and uint
    */
    function getTotalValueAndWalletCounts() public view returns(
        int, 
        uint
    ) {
        return (totalValue, totalNoOfWallets);
    }

    /**
     *
     * @notice this method gives true/false based on valid wallet address
       @return returns boolean value
       @param _walletAddress address of the wallet who enters new number to add
    */
    function isWalletAddressValid(
        address _walletAddress
    ) public view returns(
        bool
    ) {
        uint codeSize;
        assembly { codeSize := extcodesize(_walletAddress) }
        return codeSize == 0;
    }

    /**
     *
     * @notice this method stores the number entered as a sum if wallet address is valid and emits event NumberEntered
       @param _numberEntered number entered by the user to add
    */
    function enterNumber(
        int _numberEntered
    ) external {
        require(isWalletAddressValid(msg.sender), "Caller is not a valid wallet address");
        require(_numberEntered != 0, "Entered number must be non-zero");
        if(!doesWalletExists[msg.sender]){
            doesWalletExists[msg.sender] = true;
            ++totalNoOfWallets;
        }
        totalValue += _numberEntered; 
        emit NumberEntered(msg.sender, _numberEntered);
    }

}