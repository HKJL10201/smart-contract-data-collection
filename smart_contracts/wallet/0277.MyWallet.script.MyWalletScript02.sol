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
 * 1. create a userOperation (MyWallet submit transaction : send someone 1 wei)
 * 2. call entryPoint handleOps
 */

contract MyWalletScript02 is Script {
    using ECDSA for bytes32;
    EntryPoint constant entryPoint = EntryPoint(payable(0x0576a174D229E3cFA37253523E645A78A0C91B57));
    TestToken constant testToken = TestToken(0xE0b763a183c57c4eFD0Bc528FA982198CbAf231d);
    MyPaymaster constant payMaster = MyPaymaster(0xA43c3338a5653b58FE95d49968F39735B538b952);
    MyWallet constant wallet = MyWallet(0xaf6f8edA02C6D8cd4D7C3d27f918618b8bb3cDa1);
    uint256 constant amount = 1000 ether;
    address constant owner = 0x5CB9B3c05e161a0e08f2E711215043Ba8e89125C;
    address constant someone = 0xa08F892dF32a6c56531cB60e828feaDc4b42D5bb;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        vm.label(address(wallet), "MyWallet");
        vm.label(address(testToken), "testToken");
        vm.label(address(entryPoint), "entryPoint");
        vm.label(address(payMaster), "payMaster");
        vm.label(owner, "owner");

        // create userOperation
        bytes memory callData = abi.encodeCall(
            MyWallet.submitTransaction, 
            (
                someone, 
                1,
                ""
            ));
        
        // Paymaster address and token address
        UserOperation memory userOp = createUserOperation(
            address(wallet), // sender
            0, // nonce
            "", // init code
            callData,
            abi.encodePacked(address(payMaster), address(testToken)) //paymasterAndData
        );
        // sign 
        userOp.signature = signUserOp(userOp, deployerPrivateKey);

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        entryPoint.handleOps{gas: 1_000_000}(ops, payable(someone));

        vm.stopBroadcast();

        // check effects
        (,address to,uint256 value,,uint256 confirmNum,) = wallet.getTransactionInfo(1);
        require(to == someone, "to is not correct");
        require(value == 1, "value is not correct");
        require(confirmNum == 0, "confirmNum is not correct");
        // using test token to pay fee
        require(testToken.balanceOf(address(wallet)) < amount, "testToken balance is not correct");
    }

    // create a user operation with paymaster (not signed yet)
    function createUserOperation(
        address _sender,
        uint256 _nonce,
        bytes memory _initCode,
        bytes memory _callData,
        bytes memory _paymasterAndData
    ) 
        internal 
        pure
        returns(UserOperation memory _userOp)
    {
        _userOp.sender = _sender;
        _userOp.nonce = _nonce;
        _userOp.initCode = _initCode;
        _userOp.callData = _callData;
        _userOp.callGasLimit = 300000;
        _userOp.verificationGasLimit = 250000;
        _userOp.preVerificationGas = 67440;
        _userOp.maxFeePerGas = 2187600000;
        _userOp.maxPriorityFeePerGas = 1823000000;
        _userOp.paymasterAndData = _paymasterAndData;
    }

    // sign user operation with private key
    function signUserOp(
        UserOperation memory _userOp,
        uint256 _privatekey
    )
        internal
        view
        returns(bytes memory _signature)
    {
        bytes32 userOpHash = entryPoint.getUserOpHash(_userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privatekey, digest);
        _signature = abi.encodePacked(r, s, v); // note the order here is different from line above.
    }
}
