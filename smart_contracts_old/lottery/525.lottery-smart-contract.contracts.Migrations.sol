// SPDX-License-Identifier: MIT
// Migrations.sol 파일의 역할 = > 이 스마트 컨트랙트의 버전 관리를 해주는 역할
// truffle에서 사용하는 tool or contract 
// 내가 몇번째 deployment script까지 사용했는지 확인할 수 있음
// truffle 구조에서는 프로젝트와 deep 하게 연결되기 때문에 건드리지 않는 것이 좋음
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

  function setCompleted(uint completed) public restricted { // uint completed 이 숫자가 migrations 안에 있는 파일들의 1,2,3... 숫자들과 매핑됨
    last_completed_migration = completed;
  }
}
