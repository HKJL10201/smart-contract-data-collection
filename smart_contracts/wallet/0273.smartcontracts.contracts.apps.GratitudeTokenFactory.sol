// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import "./GratitudeToken.sol";

/**
 * A sample factory contract for GratitudeToken
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createGratitudeToken, in this sample factory).
 * The factory's createGratitudeToken returns the target app address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the app is created.
 */
contract GratitudeTokenFactory {
    GratitudeToken public immutable gratitudeImplementation;

    event GratitudeTokenCreated(address indexed owner);

    constructor(IEntryPoint _entryPoint) {
        gratitudeImplementation = new GratitudeToken(_entryPoint);
    }

    /**
     * create an app, and return its address.
     * returns the address even if the app is already deployed.
     * Note that during UserOperation execution, this method is called only if the app is not deployed.
     * This method returns an existing app address so that entryPoint.getSenderAddress() would work even after app creation
     */
    function createGratitudeToken(
        address owner,
        uint256 salt
    ) public returns (GratitudeToken ret) {
        address addr = getGratitudeTokenAddress(owner, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return GratitudeToken(payable(addr));
        }

        emit GratitudeTokenCreated(owner);
        ret = GratitudeToken(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(gratitudeImplementation),
                    abi.encodeCall(GratitudeToken.initialize, (owner))
                )
            )
        );
    }

    /**
     * calculate the counterfactual address of this app as it would be returned by createGratitudeToken()
     */
    function getGratitudeTokenAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(
                            address(gratitudeImplementation),
                            abi.encodeCall(GratitudeToken.initialize, (owner))
                        )
                    )
                )
            );
    }
}
