pragma solidity ^0.5.11;
import "./base/Owned.sol";
import "./base/EthPayableFallback.sol";
import "./Executor.sol";

/**
 * @title Identity Proxy contract
 * @notice This is the main contract that implements a Identity Contract like ERC725
 * @notice Basically a multisig wallet with proxy call forwarding capability
 *
 * Contracts inherited:
 * @notice Inherits Owned base contract for all owner related implementations and modifiers
 * @notice Inherits EthPayableFallback base contract to accept Eth payment as a Contract
 * @notice Inherits Executor contract for call forwarding methods
 */
contract Identity is Owned, EthPayableFallback, Executor {

    /// @notice Threshold required for transaction to be valid
    uint256 public threshold;

    // Identity Constructor only calls Owned constructor to record the first owner
    constructor() Owned() public { }
}