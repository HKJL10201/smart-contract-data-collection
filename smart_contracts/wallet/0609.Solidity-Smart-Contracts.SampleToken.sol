// SPDX-License-Identifier: MIT

// https://chat.openai.com/share/73f646cb-ae7d-427f-8662-60ba614edd1b , learn about virtual and override keywords.
// https://chat.openai.com/share/73f646cb-ae7d-427f-8662-60ba614edd1b, what is ERC20 Token?

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CoffeeToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // MINTER_ROLE, is declared as a bytes32 value. This variable will be used to represent the role required to mint new tokens.

    event CoffeePurchased(address indexed receiver, address indexed buyer);

    constructor() ERC20("CoffeeToken","CFE") { // constructor is executed once during the deployment of the contract. Inside the constructor, the ERC20 constructor is invoked with the parameters "CoffeeToken" as the token name and "CFE" as the token symbol.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Two roles are granted within the constructor using the _grantRole function. The DEFAULT_ADMIN_ROLE is granted to the msg.sender (the deployer of the contract) and the MINTER_ROLE is also granted to the msg.sender. This means that the deployer will have both the admin role and the minter role.
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE){ // mint function is defined as a public function that takes two parameters: to (the address to which the tokens will be minted) and amount (the number of tokens to be minted). This function has a modifier onlyRole(MINTER_ROLE) which ensures that only addresses with the MINTER_ROLE can call this function. Inside the function, the _mint function from the inherited ERC20 contract is called to mint the specified amount of tokens and assign them to the specified address.
        _mint(to, amount * 10 ** decimals());
    }

    function buyOneCoffee() public { // buyOneCoffee(): This function allows the caller (the person invoking the function) to purchase one coffee by burning (destroying) one CoffeeToken. Inside the function, _burn(_msgSender(), 1) is called to burn one token from the caller's address. _msgSender() is a function that returns the address of the caller. Then, an emit statement emits the CoffeePurchased event, providing the address of the caller as both the receiver and the buyer.
        _burn(_msgSender(), 1 * 10 ** decimals()); // Here 1 specifies the number of coffee to be minted and msgSender() is kind of similar to msg.sender.
        emit CoffeePurchased(_msgSender(), _msgSender());
    }

    function buyOneCoffeeFrom(address account) public { // buyOneCoffeeFrom(address account): This function allows the owner (the person who deployed the contract and has the admin role) to send one coffee token to a specific account. The account parameter represents the address of the recipient. Inside the function, _spendAllowance(account, _msgSender(), 1) is called to spend one token from account to _msgSender() (the caller). This requires that account has previously approved _msgSender() to spend tokens on their behalf. Then, _burn(account, 1) burns one token from the account address. Finally, the CoffeePurchased event is emitted with the address of the caller as the buyer and account as the receiver.
        _spendAllowance(account, _msgSender(), 1 * 10 ** decimals()); 
        _burn(account, 1 * 10 ** decimals());
        emit CoffeePurchased(_msgSender(), account);
    }
}