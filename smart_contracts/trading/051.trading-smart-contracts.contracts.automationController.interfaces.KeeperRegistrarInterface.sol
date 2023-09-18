// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface KeeperRegistrarInterface {
    /**
     * @notice Represents the registration parameters required for creating an upkeep.
     * @param name The name associated with the upkeep.
     * @param encryptedEmail The encrypted email associated with the upkeep.
     * @param upkeepContract The address of the upkeep contract.
     * @param gasLimit The gas limit for the upkeep.
     * @param adminAddress The address of the admin associated with the upkeep.
     * @param checkData Additional data used for checking the upkeep.
     * @param offchainConfig Off-chain configuration data associated with the upkeep.
     * @param amount The amount associated with the upkeep.
     * @dev This struct encapsulates the upkeep parameters required for creating an upkeep.
     */
    struct RegistrationParams {
        string name;
        bytes encryptedEmail;
        address upkeepContract;
        uint32 gasLimit;
        address adminAddress;
        bytes checkData;
        bytes offchainConfig;
        uint96 amount;
    }

    /**
     * @notice Registers an upkeep using the provided registration parameters.
     * @param requestParams The registration parameters for creating the upkeep.
     * @return The unique identifier (ID) assigned to the newly registered upkeep.
     * @dev This function allows users to register an upkeep by providing the necessary registration parameters.
     * The registration parameters include information such as the name, encrypted email, upkeep contract address,
     * gas limit, admin address, additional check data, off-chain configuration, and amount.
     * Upon successful registration, a unique identifier (ID) is assigned to the upkeep, which can be used for future reference.
     * @dev Emits an {UpkeepCreated} event.
     */
    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}
