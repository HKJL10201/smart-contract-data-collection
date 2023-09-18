pragma solidity ^0.5.11;

/**
 * @title Owned
 * @notice Basic contract for owners.
 */
contract Owned {

    /// @notice Count tracking number of owners
    /// @dev Setting initial to 1, as it will start with 1 owner via the constructor.
    uint256 public ownersCount = 1;
    /// @notice Mapping to store contract owner(s)'s address(es) and check if an address is owner
    /// @dev Addresses were of payable type previously, but errors with Sol in truffle test, thus removed for now
    mapping (address => bool) public isOwner;

    event OwnerUpdate(string indexed update_type, address indexed owner);

    /// @notice Modifier that only allows owner of the contract to continue
    /// @dev Throws if sender is not a owner
    modifier onlyOwners() {
        require(isOwner[msg.sender], "Non-Owner tried to access restricted funciton");
        _;
    }

    // Constructor only used for setting contract owner address
    constructor() public {
        isOwner[msg.sender] = true;
    }

    /// @notice Function implementing a check
    function null_check(address payable new_address) internal pure {
        require(new_address != address(0), "Address cannot be null");  // Null address check
    }
    
    /// @notice Function to add new address to list of owners
    function addOwner(address payable new_owner) public onlyOwners {
        null_check(new_owner); // Do a null check
        require(!isOwner[new_owner], "Address is already an owner!"); // Make sure address sent is not already an owner
        isOwner[new_owner] = true;
        ownersCount += 1; // Increment number of owners after owner has been added
        emit OwnerUpdate("Added", new_owner);
    }

    // How to implement different permissions for different owners?
    /// @notice Function to deleteOwner from the multisig
    function deleteOwner(address payable owner) public onlyOwners {
        require(ownersCount > 1, "Must at least have 1 Owner");
        null_check(owner); // Do a null check
        // ???  Does not make sense why the owner will delete himself.
        require(msg.sender == owner);
        delete isOwner[owner]; // Delete owner from the mapping
        emit OwnerUpdate("Deleted", owner);
    }
}