pragma solidity ^0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeERC20.sol";

contract MelonUSD is SafeERC20 {
    // The address of the contract owner
    address public owner;

    // The total supply of MelonUSD
    uint256 public totalSupply;

    // The balance of MelonUSD for each address
    mapping(address => uint256) public balances;

    // The exchange rate of MelonUSD to US dollars
    uint256 public exchangeRate;

    // Event to be emitted when MelonUSD is transferred
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    constructor(uint256 initialExchangeRate) public {
        owner = msg.sender;
        totalSupply = 0;
        exchangeRate = initialExchangeRate;
    }

    // Function to mint new MelonUSD
    function mint(uint256 value) public onlyOwner {
        require(value > 0, "Must mint a positive amount of MelonUSD.");

        totalSupply = unsafeAdd(totalSupply, value);
        balances[owner] = unsafeAdd(balances[owner], value);
        emit Transfer(address(0), owner, value);
    }

    // Function to burn existing MelonUSD
    function burn(uint256 value) public onlyOwner {
        require(value > 0, "Must burn a positive amount of MelonUSD.");
        require(value <= balances[owner], "Insufficient balance.");

        totalSupply = unsafeSub(totalSupply, value);
        balances[owner] = unsafeSub(balances[owner], value);
        emit Transfer(owner, address(0), value);
    }

    // Function to transfer MelonUSD from one address to another
    function transfer(address to, uint256 value) public {
        require(value > 0, "Must transfer a positive amount of MelonUSD.");
        require(to != address(0), "Cannot transfer to the zero address.");
        require(value <= balances[msg.sender], "Insufficient balance.");

        balances[msg.sender] = unsafeSub(balances[msg.sender], value);
        balances[to] = unsafeAdd(balances[to], value);
        emit Transfer(msg.sender, to, value);
    }

    // Function to retrieve the balance of an address
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    // Function to retrieve the exchange rate of MelonUSD
    function getExchangeRate() public view returns (uint256) {
        return exchangeRate;
    }

    // Function to update the exchange rate of MelonUSD
    function updateExchangeRate(uint256 newExchangeRate) public onlyOwner {
        require(newExchangeRate > 0, "Exchange rate must be a positive value.");

        exchangeRate = newExchangeRate;
    }

    // Modifier to restrict access to the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }
}
