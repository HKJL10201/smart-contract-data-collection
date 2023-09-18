// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/**
 * @title Ownable
 *
 * @notice Set and transfer contract ownership.
 */
contract Ownable {

    /* Modifiers */

    modifier onlyOwner() {
        if(owner == msg.sender)
            _;
    }


    /* Special Member Functions */

    constructor() public {
        owner = msg.sender;
    }


    /* Storage */

    /** @dev Owner address */
    address payable owner;


    /* Public Functions */

    /**
     * @notice Transfers ownership of contract.
     *
     * @param _address - payable address to transfer ownership.
     */
    function transferOwnership(address payable _address)
        public
        onlyOwner
    {
        require(
            _address != address(0),
            "Address cannot be empty."
        );

        owner = _address;
    }
}
