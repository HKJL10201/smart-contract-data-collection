// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/StringsUpgradeable.sol";
import "forge-std/Test.sol";

// creates payable addresses
// borrower1, borrower2, lender1, lender2, owner
// and a users array with 10 users
// the balance of each payable address is set to 1000 eth
// and vm.label is used to add clarity to stack traces
contract UsersFixtures is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    address payable internal borrower1;
    uint256 internal borrower1_private_key;
    address payable internal borrower2;
    address payable internal lender1;
    uint256 internal lender1_private_key;
    address payable internal lender2;
    address payable internal lender3;
    address payable internal owner;
    address constant SANCTIONED_ADDRESS = address(0x7FF9cFad3877F21d41Da833E2F775dB0569eE3D9);

    address payable[10] internal users;

    // current total supply of ether
    uint256 internal defaultInitialEthBalance = 121520307 ether;

    function setUp() public virtual {
        borrower1 = payable(0x287841894D6FF7b033C810Dc658F5f295cEb356f);
        borrower1_private_key = 0xe03653b0b5b4758d674f62d5cb4f01fda33b2e6c3d5b7d56942ca34d1564c376;
        vm.deal(borrower1, defaultInitialEthBalance);
        vm.label(borrower1, "borrower1");

        borrower2 = getNextUserAddress();
        vm.deal(borrower2, defaultInitialEthBalance);
        vm.label(borrower2, "borrower2");

        lender1 = payable(0x7DE84B1343651f5Fd09A0C953C20b09D3F4E9872);
        lender1_private_key = 0x8294f76232c16ff75384e1e116f072473efebd6bc3b80f4f1039a8013a9435bc;
        vm.deal(lender1, defaultInitialEthBalance);
        vm.label(lender1, "lender1");

        lender2 = getNextUserAddress();
        vm.deal(lender2, defaultInitialEthBalance);
        vm.label(lender2, "lender2");

        lender3 = getNextUserAddress();
        vm.deal(lender3, defaultInitialEthBalance);
        vm.label(lender3, "lender3");

        owner = getNextUserAddress();
        vm.deal(owner, defaultInitialEthBalance);
        vm.label(owner, "owner");

        owner = getNextUserAddress();
        vm.deal(SANCTIONED_ADDRESS, defaultInitialEthBalance);
        vm.label(SANCTIONED_ADDRESS, "SANCTIONED_ADDRESS");

        for (uint256 i = 0; i < 10; i++) {
            address payable user = getNextUserAddress();
            vm.deal(user, defaultInitialEthBalance);
            users[i] = user;
            vm.label(user, string.concat("user", StringsUpgradeable.toString(i)));
        }
    }

    function getNextUserAddress() internal returns (address payable) {
        // bytes32 to address conversion
        // bytes32 (32 bytes) => uint256 (32 bytes) => uint160 (20 bytes) => address (20 bytes)
        // explicit type conversion not allowed from "bytes32" to "uint160"
        // nor from "uint256" to "address"
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }
}
