// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/AutomatedAdmin.sol";

contract BusyBee {
	address public owner;
	uint public honeyAmount;

	constructor(address _owner) {
		owner = _owner;
	}

	function buzz() external pure returns (bool) {
		return true;
	}

	function fly() external view returns (bool) {
		return msg.sender == owner;
	}

	function pollinate(uint x) external view returns (bool) {
		return (msg.sender == owner) && (x == 50);
	}

	function makeHoney(uint8 x) external returns (uint) {
		honeyAmount += x;
		return honeyAmount;
	}

	function eatHoney(uint8 x) external returns (uint) {
		honeyAmount -= x;
		return honeyAmount;
	}
}

contract ContractTest is Test {
	bytes constant FLY = hex"2c2e3abf";
	bytes constant POLLINATE =
		hex"30c448ef0000000000000000000000000000000000000000000000000000000000000032";
	bytes4 constant FLY_SIG = hex"2c2e3abf";
	bytes4 constant POLLINATE_SIG = hex"30c448ef";
	bytes4 constant MAKE_HONEY_SIG = hex"c4512f96";
	bytes4 constant EAT_HONEY_SIG = hex"aac7ef6f";

	AutomatedAdmin admin;
	BusyBee bee;

	function setUp() public {
		admin = new AutomatedAdmin();
		bee = new BusyBee(address(admin));
	}

	function test_actAsOwner() public {
		if (bee.buzz() == false || bee.fly() == true)
			revert();
		bytes memory data =
			admin.contractCall(address(bee), POLLINATE);
		bool success = abi.decode(data, (bool));
		if (!success)
			revert();
	}

	function test_permissions(address a) public {
		vm.assume(a != address(this));
		admin.contractCall(address(bee), FLY);
		admin.contractCall(address(bee), POLLINATE);
		vm.startPrank(a,a);
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.contractCall(address(bee), FLY);
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.contractCall(address(bee), POLLINATE);
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.roleAdd(a, AutomatedAdmin.Roles.Admin);
		vm.stopPrank();
		admin.roleAdd(a, AutomatedAdmin.Roles.Admin);
		vm.startPrank(a,a);
		admin.contractCall(address(bee), FLY);
		admin.contractCall(address(bee), POLLINATE);
		admin.roleAdd(a, AutomatedAdmin.Roles.Admin);
		admin.roleRemove(a, AutomatedAdmin.Roles.Admin);
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.contractCall(address(bee), FLY);
		vm.stopPrank();
		admin.roleCreate(AutomatedAdmin.Roles.Unnamed01, "Bee Lovers");
		admin.roleCreate(AutomatedAdmin.Roles.Unnamed02, "Bee Enthusiasts");
		admin.roleAdd(a, AutomatedAdmin.Roles.Unnamed01);
		vm.prank(a,a);
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.contractCall(address(bee), FLY);
		AutomatedAdmin.Roles[] memory roles01 = new AutomatedAdmin.Roles[](2);
		AutomatedAdmin.Roles[] memory roles02 = new AutomatedAdmin.Roles[](1);
		roles01[0] = AutomatedAdmin.Roles.Unnamed01;
		roles01[1] = AutomatedAdmin.Roles.Unnamed02;
		roles02[0] = AutomatedAdmin.Roles.Unnamed02;
		admin.setPermissions(
			address(bee),
			FLY_SIG,
			roles01
		);
		admin.setPermissions(
			address(bee),
			POLLINATE_SIG,
			roles02
		);
		vm.startPrank(a,a);
		admin.contractCall(address(bee), FLY);
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.contractCall(address(bee), POLLINATE);
		vm.stopPrank();
		admin.roleAdd(a, AutomatedAdmin.Roles.Unnamed02);
		vm.prank(a,a);
		admin.contractCall(address(bee), POLLINATE);
		admin.roleDestroy(AutomatedAdmin.Roles.Unnamed02);
		vm.startPrank(a,a);
		admin.contractCall(address(bee), FLY);
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.contractCall(address(bee), POLLINATE);
		vm.stopPrank();
		admin.lock();
		vm.prank(a,a);
		vm.expectRevert(getSelector("Locked()"));
		admin.contractCall(address(bee), FLY);
	}

	function test_roleModification(address a) public {
		vm.assume(a != address(this));
		admin.roleCreate(AutomatedAdmin.Roles.Unnamed05, "Bee Enthusiasts");
		vm.expectRevert(getSelector("NoChange()"));
		admin.roleCreate(AutomatedAdmin.Roles.Unnamed05, "Bee Watchers");
		vm.expectRevert(getSelector("PermanentRole()"));
		admin.roleDestroy(AutomatedAdmin.Roles.Admin);
		vm.expectRevert(getSelector("PermanentRole()"));
		admin.roleDestroy(AutomatedAdmin.Roles.Safety);
		vm.expectRevert(getSelector("PermanentRole()"));
		admin.roleDestroy(AutomatedAdmin.Roles.Automation);
		vm.expectRevert(getSelector("PermanentRole()"));
		admin.roleRename(AutomatedAdmin.Roles.Admin, "Testing");
		vm.expectRevert(getSelector("PermanentRole()"));
		admin.roleRename(AutomatedAdmin.Roles.Safety, "Testing");
		vm.expectRevert(getSelector("PermanentRole()"));
		admin.roleRename(AutomatedAdmin.Roles.Automation, "Testing");
		admin.roleRename(AutomatedAdmin.Roles.Unnamed05, "Bee Watchers");
		vm.expectRevert(getSelector("CannotRemoveLastAdmin()"));
		admin.roleRemove(address(this), AutomatedAdmin.Roles.Admin);
		admin.roleAdd(a, AutomatedAdmin.Roles.Admin);
		admin.roleRemove(address(this), AutomatedAdmin.Roles.Admin);
		vm.prank(a,a);
		vm.expectRevert(getSelector("CannotRemoveLastAdmin()"));
		admin.roleRemove(a, AutomatedAdmin.Roles.Admin);
	}

	function test_transactionQueue(address a, address notA, bool b) public {
		vm.assume(a != address(this) && a != address(0));
		vm.assume(notA != address(this) && notA != address(0));
		vm.assume(notA != a);
		admin.roleAdd(a, b ? AutomatedAdmin.Roles.Safety : AutomatedAdmin.Roles.Automation);
		vm.prank(notA,notA);
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.transactionQueue(address(bee), 0, FLY, "");
		vm.startPrank(a,a);
		bytes32 _hash = admin.transactionQueue(address(bee), 0, FLY, "");
		vm.expectRevert(getSelector("NotAuthorized()"));
		admin.transactionSend(_hash);
		vm.stopPrank();
		(bool success, bytes memory returnData) = admin.transactionSend(_hash);
		if (!(success && abi.decode(returnData, (bool))))
			revert();
		bytes32[] memory txs = new bytes32[](5);
		vm.startPrank(a,a);
		txs[0] = admin.transactionQueue(
			address(bee),
			0,
			abi.encodeWithSelector(MAKE_HONEY_SIG, 5),
			""
		);
		txs[1] = admin.transactionQueue(
			address(bee),
			0,
			abi.encodeWithSelector(MAKE_HONEY_SIG, 27),
			""
		);
		txs[2] = admin.transactionQueue(
			address(bee),
			0,
			abi.encodeWithSelector(EAT_HONEY_SIG, 18),
			""
		);
		txs[3] = admin.transactionQueue(
			address(bee),
			0,
			abi.encodeWithSelector(MAKE_HONEY_SIG, 79),
			""
		);
		txs[4] = admin.transactionQueue(
			address(bee),
			0,
			abi.encodeWithSelector(EAT_HONEY_SIG, 54),
			""
		);
		vm.stopPrank();
		bytes[] memory results = admin.transactionSendBatch(txs);
		if (bee.honeyAmount() != 39)
			revert();
		if (!(abi.decode(results[0], (uint)) == 5 || abi.decode(results[4], (uint)) == 39))
			revert();
	}

	function getSelector(string memory _data) private pure returns (bytes4 _selector) {
		_selector = bytes4(keccak256(bytes(_data)));
	}
}
