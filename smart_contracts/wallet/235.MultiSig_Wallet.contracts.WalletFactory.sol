pragma solidity 0.8.9;

contract WalletFactory {

    uint256 id = 0;

    struct Wallet{
        uint256 id; //wallet id
        address walletAdd;
        uint256 createdAt; //block.timestamp
        address walletCreator; 
    }

    Wallet [] wallets;

            
    mapping(address => mapping(uint256 => uint256)) walletBalance;


    function removeOwner(address walletAdd, address user) external {
        
    }

    function addOwner(address walletAdd, address user) external {
        //wallets[] storage newWallet = wallets[user];
        //newWallet.push(wallets(walletAdd, id));
    }

}