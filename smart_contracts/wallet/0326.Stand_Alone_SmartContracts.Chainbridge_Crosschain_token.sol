CHAINBRIDGE FOR CROSS CHAIN TOKEN

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// This Bridge Contract will interact with ChainBridge
// It should be able to lock, release, and transfer tokens across the networks

contract Bridge is Ownable {
    using SafeMath for uint256;

    // Lock event
    event Lock(address indexed token, address indexed sender, uint256 amount, uint256 chainId, bytes32 depositNonce);

    // Release event
    event Release(address indexed token, address indexed receiver, uint256 amount);

    // Token address
    address public token;

    // ChainBridge relayer address
    address public relayer;

    // Mapping of nonces to keep track of locked tokens
    mapping(bytes32 => bool) public lockedNonces;

    // Modifier to check if the caller is the relayer
    modifier onlyRelayer() {
        require(msg.sender == relayer, "Caller is not the relayer");
        _;
    }

    // Constructor to set the token address and relayer address
    constructor(address _token, address _relayer) {
        token = _token;
        relayer = _relayer;
    }

    // Function to lock tokens
    function lockTokens(uint256 _amount, uint256 _chainId, bytes32 _depositNonce) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(!lockedNonces[_depositNonce], "Deposit nonce already used");

        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        lockedNonces[_depositNonce] = true;
        emit Lock(token, msg.sender, _amount, _chainId, _depositNonce);
    }

    // Function to release tokens
    function releaseTokens(address _receiver, uint256 _amount, bytes32 _depositNonce) external onlyRelayer {
        require(lockedNonces[_depositNonce], "Invalid deposit nonce");

        IERC20(token).transfer(_receiver, _amount);
        lockedNonces[_depositNonce] = false;
        emit Release(token, _receiver, _amount);
    }

    // Function to change the relayer address
    function changeRelayer(address _newRelayer) external onlyOwner {
        relayer = _newRelayer;
    }
}
/*

This Bridge contract is designed to interact with ChainBridge and allows locking, releasing, and transferring tokens across networks. The contract imports the necessary OpenZeppelin contracts such as IERC20, Ownable, and SafeMath.

The contract emits two events, `Lock` and `Release`, which are used to track the locking and releasing of tokens. It also maintains a mapping of `lockedNonces` to keep track of locked tokens.

The `onlyRelayer` modifier is used to ensure that only the designated relayer can call certain functions, such as releasing tokens.

The constructor sets the token address and relayer address upon deployment.

The `lockTokens` function is used to lock tokens, transferring them from the sender to the contract and updating the `lockedNonces` mapping. The `releaseTokens` function is used to release locked tokens, transferring them to the specified receiver and updating the `lockedNonces` mapping.

The contract also includes a function to change the relayer address, which can only be called by the contract owner.
*/
