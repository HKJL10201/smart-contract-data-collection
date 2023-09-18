pragma solidity >=0.4.0 <0.6.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address payable public owner;
    address payable public admin;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address payable indexed previousOwner,
        address payable indexed newOwner
    );


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address payable _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address payable _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /// ADMIN ///

    event AdminRenounced(address indexed previousAdmin);
    event AdminTransferred(
        address payable indexed previousAdmin,
        address payable indexed newAdmin
    );

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOwnerAndAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    function renounceAdmin() public onlyAdmin {
        emit AdminRenounced(admin);
        admin = address(0);
    }

    function transferAdmin(address payable _newAdmin) public onlyAdmin {
        _transferAdmin(_newAdmin);
    }

    function _transferAdmin(address payable _newAdmin) internal {
        require(_newAdmin != address(0));
        emit AdminTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }
}
