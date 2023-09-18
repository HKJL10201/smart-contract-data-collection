// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";

contract Account {

    /**
    * @dev Owner address
    */
    address public owner;

    /**
    * @dev 'DAOVote' contract address
    */
    address public dao;

    /**
    * @dev Temporary status of re-entrancy
    */
    uint64 private constant _NOT_ENTERED = 1;
    
    /**
    * @dev Temporary status of re-entrancy
    */
    uint64 private constant _ENTERED = 2;

    /**
    * @dev Status used for re-entrancy checking
    */
    uint64 private _status;

    /**
    * @dev Checks whether caller is 'DAOVote' contract
    */
    modifier onlyDAO() {
        require(msg.sender == dao, "Account: only DAOVote contract allowed to call this function");
        _;
    }

    /**
    * @dev Checks for re-entrancy
    */
    modifier nonReentrant() {
        require(_status != _ENTERED, "Account: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /**
    * @dev Set owner address and 'DAOVote' contract address
    *      Set initial status of re-entrancy
    */
    constructor (address _owner, address _dao) {
        owner = _owner;
        dao = _dao;
        _status = _NOT_ENTERED;
    }

    /**
    * @dev This function allow withdrawal of used token for casting a vote or proposal creation
    *      Only 'DAOVote' contract allowed to call this function
    *      Only transfer one token for each function call
    *      Uses 'nonReentrant' modifier to prevent re-entrancy attack
    * @param _assetContract ERC1155 external contract 
    * @param _tokenId Token ID of '_assetContract'
    */
    function withdraw(address _assetContract, uint256 _tokenId) external onlyDAO nonReentrant {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            IERC1155(_assetContract).safeTransferFrom(address(this), owner, _tokenId, 1, "");
        }
    }

    /**
    * @notice Function to receive Ether
    */
    receive() external payable {}

    /**
    * @notice Fallback function is called when msg.data is not empty
    */
    fallback() external payable {}

    /**
    * @dev ERC 1155 Receiver functions.
    **/

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
    * @dev ERC 1155 Batch Receiver functions.
    **/
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}