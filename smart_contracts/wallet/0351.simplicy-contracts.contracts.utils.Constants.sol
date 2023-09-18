//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// semaphore
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
uint8 constant MAX_DEPTH = 32;

// semaphoreGroupsBase
bytes32 constant GET_GROUP_ADMIN_TYPEHASH = keccak256(
  "getGroupAdmin(uint256 groupId)"
);

bytes32 constant UPDATE_GROUP_ADMIN_TYPEHASH = keccak256(
  "createGroup(uint256 groupId,uint8 depth,uint256 zeroValue,address admin)"
);

bytes32 constant CREATE_GROUP_TYPEHASH = keccak256(
  "createGroup(uint256 groupId,uint8 depth,uint256 zeroValue,address admin)"
);

bytes32 constant ADD_MEMBER_TYPEHASH = keccak256(
  "addMember(uint256 groupId,uint256 identityCommitment)"
);

bytes32 constant REMOVE_MEMBER_TYPEHASH = keccak256(
  "removeMember(uint256 groupId,uint256 identityCommitment,uint256[] calldata proofSiblings,uint8[] calldata proofPathIndices)"
);

bytes32 constant ADD_MEMBERS_TYPEHASH = keccak256(
  "addMember(uint256 groupId,uint256[] memory identityCommitments)"
);

bytes32 constant REMOVE_MEMBERS_TYPEHASH = keccak256(
  "removeMembers(uint256 groupId,RemoveMembersDTO[] calldata members)"
);

// guardians
uint constant MIN_GUARDIANS = 3;
uint constant MAX_GUARDIANS = 10;
uint constant GUARDIAN_PENDING_PERIODS = 3 days;

bytes32 constant GET_GUARDIANS_TYPEHASH = keccak256(
  "getGuardians(uint256 groupId)"
);

bytes32 constant NUM_GUARDIANS_TYPEHASH = keccak256(
  "numGuardians(uint256 groupId)"
);

bytes32 constant SET_INITIAL_GUARDIANS_TYPEHASH = keccak256(
  "setInitialGuardians(uint256 groupId,AddGuardianDTO[] calldata guardians)"
);

bytes32 constant ADD_GUARDIAN_TYPEHASH = keccak256(
  "addGuardian(uint256 groupId,uint256 hashId,uint256 identityCommitment,uint256 validUntil)"
);

bytes32 constant REMOVE_GUARDIAN_TYPEHASH = keccak256(
  "removeGuardian(uint256 groupId,uint256 hashId,uint256 validUntil)"
);

bytes32 constant REMOVE_GUARDIANS_TYPEHASH = keccak256(
  "removeGuardians(uint256 groupId,RemoveGuardianDTO[] calldata guardians)"
);