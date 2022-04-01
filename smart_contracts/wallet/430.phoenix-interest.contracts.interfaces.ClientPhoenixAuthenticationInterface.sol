pragma solidity ^0.5.0;

interface ClientPhoenixAuthenticationInterface {
    function phoenixStakeUser() external returns (uint);
    function phoenixStakeDelegatedUser() external returns (uint);

    function setPhoenixIdentityAddress(address _phoenixIdentityAddress) external;
    function setStakes(uint _phoenixStakeUser, uint _phoenixStakeDelegatedUser) external;

    function signUp(address _address, string calldata casedPhoenixId) external;

    function phoenixIDAvailable(string calldata uncasedPhoenixID) external view returns (bool available);
    function phoenixIDDestroyed(string calldata uncasedPhoenixID) external view returns (bool destroyed);
    function phoenixIDActive(string calldata uncasedPhoenixID) external view returns (bool active);

    function getDetails(string calldata uncasedPhoenixID) external view
        returns (uint ein, address _address, string memory casedPhoenixID);
    function getDetails(uint ein) external view returns (address _address, string memory casedPhoenixID);
    function getDetails(address _address) external view returns (uint ein, string memory casedPhoenixID);
}
