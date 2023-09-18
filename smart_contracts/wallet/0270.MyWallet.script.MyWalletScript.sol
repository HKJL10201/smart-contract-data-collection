// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import { MyWalletFactory } from "../src/MyWalletFactory.sol";
import { MyWallet } from "../src/MyWallet.sol";
import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { TestToken } from "aa-sample/src/tokens/TestToken.sol";
import { MyPaymaster } from "aa-sample/src/MyPaymaster.sol";
import { IERC20 } from "openzeppelin/interfaces/IERC20.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import { ECDSA } from "openzeppelin/utils/cryptography/ECDSA.sol";
import "forge-std/Script.sol";

/**
 * @dev this script contains 
 * 1. setup a MyWallet by factory
 * 2. mint test token to MyWallet and approve PayMaster
 */

contract MyWalletScript is Script {
    using ECDSA for bytes32;
    EntryPoint constant entryPoint = EntryPoint(payable(0x0576a174D229E3cFA37253523E645A78A0C91B57));
    TestToken constant testToken = TestToken(0xE0b763a183c57c4eFD0Bc528FA982198CbAf231d);
    MyPaymaster constant payMaster = MyPaymaster(0xA43c3338a5653b58FE95d49968F39735B538b952);
    uint256 constant amount = 1000 ether;
    address constant owner = 0x5CB9B3c05e161a0e08f2E711215043Ba8e89125C;
    address constant someone = 0xa08F892dF32a6c56531cB60e828feaDc4b42D5bb;

    function setUp() public {}

    function run() public {

        address[] memory owners = new address[](1);
        owners[0] = owner;
        bytes32[] memory guardianHashes = new bytes32[](1);
        guardianHashes[0] = keccak256(abi.encodePacked(owner));

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // setup MyWallet
        MyWalletFactory factory = new MyWalletFactory(entryPoint);
        MyWallet wallet = factory.createAccount(
            owners, // owners
            1, // confrimThreshold
            guardianHashes, // guardianhash
            1, // recoveryThreshold
            owners, // whiteList
            0 // salt
        );

        vm.label(address(wallet), "MyWallet");
        vm.label(address(testToken), "testToken");
        vm.label(address(entryPoint), "entryPoint");
        vm.label(address(factory),"factory");
        vm.label(address(payMaster), "payMaster");
        vm.label(owner, "owner");

        // wallet approve paymaster 
        {
        testToken.mint(address(wallet), amount);
        bytes memory data = abi.encodeCall(IERC20.approve, (address(payMaster), amount));
        uint256 id = wallet.submitTransaction(address(testToken), 0, data);
        wallet.confirmTransaction(id);
        wallet.executeTransaction(id);
        require(testToken.allowance(address(wallet), address(payMaster)) == amount, "allowance not correct");
        }

    }
}