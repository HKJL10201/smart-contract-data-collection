// Migrations.sol 파일은 Smart-Contract의 버전관리를 해주는 역할

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

// 몇번 째 deployment script 까지 사용했는지 확인가능
// unit completed가 migrations의 1_, 2_, 3_이랑 매핑
  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}
