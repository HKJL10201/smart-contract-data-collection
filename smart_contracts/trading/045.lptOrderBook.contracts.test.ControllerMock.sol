pragma solidity ^0.5.7;

contract ControllerMock {

    address private livepeerToken;
    address private bondingManager;
    address private roundsManager;

    constructor(address _livepeerToken, address _bondingManager, address _roundsManager) public {
        livepeerToken = _livepeerToken;
        bondingManager = _bondingManager;
        roundsManager = _roundsManager;
    }

    function getContract(bytes32 _id) public view returns (address) {

        bytes32 livepeerTokenId = 0x3443e257065fe41dd0e4d1f5a1b73a22a62e300962b57f30cddf41d0f8273ba7;
        bytes32 bondingManagerId = 0x2517d59a36a86548e38734e8ab416f42afff4bca78706a66ad65750dae7f9e37;
        bytes32 roundsManagerId = 0xe8438ea868df48e3fc21f2f087b993c9b1837dc0f6135064161ce7d7a1701fe8;

        if (_id == livepeerTokenId) {
            return livepeerToken;
        } else if (_id == bondingManagerId) {
            return bondingManager;
        } else if (_id == roundsManagerId) {
            return roundsManager;
        }
    }
}
