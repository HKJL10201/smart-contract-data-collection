// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IRegistry {
    /// @notice Given a sum, returns the address of the platforms's wallet and fees due
    /// @dev structured similar to ERC2981
    /// @param _salePrice the uint256 amount being paid
    /// @return the address of the sustem wallet and the uint256 amount of fees to pay
    function feeInfo(uint256 _salePrice)
        external
        view
        returns (address, uint256);

    /// @notice Returns if a contract is recognized by the registry
    /// @dev no validation is done to verify a contract exists at the address
    /// @param toCheck the address of the contract to check
    /// @return bool if the contract is approved by the registry
    function platformContracts(address toCheck) external view returns (bool);

    /// @notice Returns if a token is approved for use on the platform
    /// @dev no validation is done to verify a token contract exists at the address
    /// @dev use address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa) for ETH
    /// @param tokenContract the address of the token to check
    /// @return bool if the token is approved for use on the platform
    function approvedCurrencies(address tokenContract)
        external
        view
        returns (bool);

    /// @notice Sets the address of the platform's wallet (for fees)
    /// @param newWallet the address of the new platform wallet
    function setSystemWallet(address newWallet) external;

    /// @notice Sets the fee and scaling factor
    /// @dev for example, a fee of 500 with a scale of 10,000 would be 5%
    /// @param newFee the adjusted percentage to take as fees
    /// @param newScale the scale the fee is adjusted by
    function setFeeVariables(uint256 newFee, uint256 newScale) external;

    /// @notice Sets the status of a particular contract
    /// @dev deprecated contracts should be set to false
    /// @param toChange the address of the contract to set
    /// @param status the bool status to set the contract to
    function setContractStatus(address toChange, bool status) external;

    /// @notice Sets the status of a particular token
    /// @param tokenContract the address of the token
    /// @param status the bool status to set the token to
    function setCurrencyStatus(address tokenContract, bool status) external;

    /// @notice Allows all token to be used in the platform
    /// @dev this is an irreversible function
    function approveAllCurrencies() external;
}
