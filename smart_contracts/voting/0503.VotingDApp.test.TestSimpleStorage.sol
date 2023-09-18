pragma solidity 0.8.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SimpleStorage.sol";

contract TestSimpleStorage {
    function testItStoresAValue() public {
        SimpleStorage simpleStorage = SimpleStorage(
            DeployedAddresses.SimpleStorage()
        );

        simpleStorage.set(89);

        uint256 expected = 89;

        Assert.equal(
            simpleStorage.get(),
            expected,
            "It should store the value 89."
        );
    }
}
