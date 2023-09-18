// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC4337 {
    function balanceOf(address owner, address token) external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract WalletContract {
    struct TokenBalance {
        address tokenAddress;
    }

    address immutable owner;
    event FundsReceived(address indexed owner, uint256 amount);
    mapping(address => uint256) public balances; // Tracks the Ether balance of each address
    mapping(address => mapping(address => TokenBalance)) public tokenBalances; // Tracks the token balance of each address for each token

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner"); // Modifier to restrict access to the owner only
        _;
    }

    constructor(address walletOwner) {
        require(walletOwner != address(0), "Invalid wallet owner address"); // Validate the wallet owner address
        owner = walletOwner; // Set the owner of the contract
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance; // Returns the Ether balance of the contract
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        TokenBalance storage tokenBalance = tokenBalances[msg.sender][tokenAddress];
        if (tokenBalance.tokenAddress == address(0)) {
            return 0; // If token address is 0, it means the token balance is 0
        }
        return _getTokenBalance(tokenAddress); // Otherwise, retrieve the token balance using the internal function
    }

    function transfer(address to, address token, uint256 amount) external {
        if (token == address(0)) {
            require(balances[msg.sender] >= amount, "Insufficient balance"); // Check if the sender has enough Ether balance

            balances[msg.sender] -= amount; // Deduct the transferred amount from the sender's balance
            balances[to] += amount; // Add the transferred amount to the recipient's balance

            payable(to).transfer(amount); // Transfer the Ether to the recipient address
        } else {
            IERC20 tokenContract = IERC20(token);
            require(tokenContract.balanceOf(address(this)) >= amount, "Insufficient balance"); // Check if the contract has enough token balance

            TokenBalance storage tokenBalance = tokenBalances[msg.sender][token];
            if (tokenBalance.tokenAddress == address(0)) {
                tokenBalance.tokenAddress = token; // If the token balance for the sender is not set, set it to the provided token address
            }

            require(tokenContract.transfer(to, amount), "Token transfer failed"); // Transfer the tokens from the contract to the recipient address
        }
    }

    receive() external payable {
        balances[owner] += msg.value; // Add the received Ether to the owner's balance
        emit FundsReceived(owner, msg.value); // Emit an event to notify the funds received
    }

    function _getTokenBalance(address tokenAddress) private view returns (uint256) {
        IERC4337 tokenContract = IERC4337(tokenAddress);
        require(tokenContract.supportsInterface(type(IERC4337).interfaceId), "Token does not support EIP-4337"); // Check if the token supports the EIP-4337 interface
        return tokenContract.balanceOf(msg.sender, tokenAddress); // Retrieve the token balance of the sender
    }
}



