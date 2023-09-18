pragma solidity 0.5.15;

contract IHedgrWalletFactory {
    function getUserWallet(address user) external view returns(address);
    function getWalletUser(address wallet) external view returns(address);
}