// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { MyWallet } from "../../src/MyWallet.sol";
import { Counter } from "../../src/Counter.sol";
import { MyWalletFactory } from "../../src/MyWalletFactory.sol";

import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { MockERC721 } from "solmate/test/utils/mocks/MockERC721.sol";
import { MockERC1155 } from "solmate/test/utils/mocks/MockERC1155.sol";
import { MyPaymaster } from "aa-sample/src/MyPaymaster.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import { IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import { ECDSA } from "openzeppelin/utils/cryptography/ECDSA.sol";

/** 
* @dev we use 3 owners and at least 2 confirm to pass the multisig requirement
* @dev also 3 guardians and at least 2 of their support to recover 
* @dev only 1 address on whiteList
*/ 

contract TestHelper is Test {
    using ECDSA for bytes32;

    uint256 constant INIT_BALANCE = 100 ether;
    uint256 constant ownerNum = 3;
    uint256 constant confirmThreshold = 2;
    uint256 constant guardianNum = 3;
    uint256 constant recoverThreshold = 2;
    uint256 constant timeLimit = 1 days;
    uint256 constant salt = 1;
    address[] owners;
    address[] guardians;
    address[] whiteList;
    uint256 [] ownerKeys;
    uint256 [] guardianKeys;
    bytes32[] guardianHashes;
    address someone;
    address bundler;
    MyWallet wallet;
    MyWalletFactory factory;
    EntryPoint entryPoint;
    MyPaymaster payMaster;
    Counter counter;
    MockERC20 mockErc20;
    MockERC721 mockErc721;
    MockERC1155 mockErc1155;

    event SubmitTransaction(address indexed sender, uint256 indexed transactionIndex);
    event ConfirmTransaction(address indexed sender, uint256 indexed transactionIndex);
    event TransactionPassed(uint256 indexed transactionIndex);
    event ExecuteTransaction(uint256 indexed transactionIndex);
    event Receive(address indexed sender, uint256 indexed amount, uint256 indexed balance);
    event SubmitRecovery(address indexed replacedOwner, address indexed newOwner, address proposer);
    event ExecuteRecovery(address indexed oldOwner, address indexed newOwner);
    event AddNewWhiteList(address indexed whiteAddr);
    event RemoveWhiteList(address indexed removeAddr);
    event ReplaceGuardian(bytes32 indexed oldGuardianHash, bytes32 indexed newGuardianHash);
    event FreezeWallet();
    event UnfreezeWallet();

    function setUp() public virtual {
        // setting MyWallet
        setOwners(ownerNum);
        setGuardians();
        for(uint256 i = 0; i < guardianNum; i++) {
            guardianHashes.push(keccak256(abi.encodePacked(guardians[i])));
        }
        address whiteAddr = makeAddr("whiteAddr");
        someone = makeAddr("someone");
        bundler = makeAddr("bundler");
        vm.deal(someone, INIT_BALANCE);
        vm.deal(bundler, INIT_BALANCE);
        whiteList.push(whiteAddr);
        
        // Deploy EntryPoint
        entryPoint = new EntryPoint();
        
        // Deploy MyWallet
        factory = new MyWalletFactory(entryPoint);
        wallet = factory.createAccount(owners, confirmThreshold, guardianHashes, recoverThreshold, whiteList, salt);
        assertEq(wallet.leastConfirmThreshold(), confirmThreshold);
        
        // Deploy MyPaymaster
        payMaster = new MyPaymaster(IEntryPoint(address(entryPoint)));

        // setting test contracts
        counter = new Counter();
        mockErc20 = new MockERC20("MockERC20", "MERC20", 18);
        mockErc721 = new MockERC721("MockERC721", "MERC721");
        mockErc1155 = new MockERC1155();

        vm.label(address(wallet), "MyWallet");
        vm.label(address(counter), "counter");
        vm.label(address(mockErc20), "mockErc20");
        vm.label(address(mockErc721), "mockERC721");
        vm.label(address(mockErc1155), "mockERC1155");
        vm.label(address(entryPoint), "entryPoint");
        vm.label(address(factory),"factory");
        vm.label(address(payMaster), "payMaster");
    }

    // utilities ====================================================
    // make _n owners with INIT_BALANCE
    function setOwners(uint256 _n) internal {
        require(_n > 0, "one owner at least");
        for(uint256 i = 0; i < _n; i++){
            string memory name = string.concat("owner", vm.toString(i));
            (address owner, uint256 privateKey) = makeAddrAndKey(name);
            vm.deal(owner, INIT_BALANCE);
            owners.push(owner);
            ownerKeys.push(privateKey);
        }
    }

    function setGuardians() internal {
        for(uint256 i = 0; i < guardianNum; i++){
            string memory name = string.concat("guardian", vm.toString(i));
            (address guardian, uint256 privateKey) = makeAddrAndKey(name);
            vm.deal(guardian, INIT_BALANCE);
            guardians.push(guardian);
            guardianKeys.push(privateKey);
        }
    }

    // submit transaction to call Counter's increment function
    function submitTx() public returns(bytes memory data, uint256 id){
        data = abi.encodeCall(Counter.increment, ());
        id = wallet.submitTransaction(address(counter), 0, data);
    }

    // submit transaction to send whiteList[0] 1 ether
    function submitTxWhiteList(uint256 amount) public 
    returns(
        bytes memory data,
        uint256 id
    ){
        data = "";
        id = wallet.submitTransaction(whiteList[0], amount, data);
    }

    // submit recovery
    function submitRecovery() public returns(address replacedOwner, address newOwner){
        newOwner = makeAddr("newOwner");
        replacedOwner = owners[2];
        vm.prank(guardians[0]);
        vm.expectEmit(true, true, true, true, address(wallet));
        emit SubmitRecovery(replacedOwner, newOwner, guardians[0]);
        wallet.submitRecovery(replacedOwner, newOwner);
    }

    // create a user operation (not signed yet)
    function createUserOperation(
        address _sender,
        uint256 _nonce,
        bytes memory _initCode,
        bytes memory _callData
    ) 
        internal 
        pure
        returns(UserOperation memory _userOp)
    {
        _userOp.sender = _sender;
        _userOp.nonce = _nonce;
        _userOp.initCode = _initCode;
        _userOp.callData = _callData;
        _userOp.callGasLimit = 600000;
        _userOp.verificationGasLimit = 1000000;
        _userOp.preVerificationGas = 10000;
        _userOp.maxFeePerGas = 10000000000;
        _userOp.maxPriorityFeePerGas = 2500000000;
        _userOp.paymasterAndData = "";
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
        _userOp.callGasLimit = 600000;
        _userOp.verificationGasLimit = 1000000;
        _userOp.preVerificationGas = 10000;
        _userOp.maxFeePerGas = 10000000000;
        _userOp.maxPriorityFeePerGas = 2500000000;
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