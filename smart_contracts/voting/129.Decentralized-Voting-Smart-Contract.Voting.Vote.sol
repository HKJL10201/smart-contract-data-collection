// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
	function balanceOf(address _owner) external view returns(uint256);
	function decimals() external view returns(uint8);
}

// 1) Each proposal needs a single voting contract
// 2) Every goverance token is equal to a single voting power, for instanse: 1000 Token = 1000 VP
// 3) Each voter can vote once
contract Voting {

	IERC20 public immutable goveranceToken;
	
	uint32 public immutable endAt;

	mapping (address => bool) public voted;
	mapping (address => uint8) public votedTo;
	mapping (address => uint256) public userVotdedPower;
	
	uint256 public yesPower; // 1
	uint256 public noPower; // 0
	
	event Vote(string indexed _to, address indexed _voter, uint256 _vp, uint256 indexed _time);

	constructor(IERC20 _goveranceToken, uint32 _period) {
		require(address(_goveranceToken) != address(0) && _period > 0, "Invalid voting data");
		
		goveranceToken = _goveranceToken;
		endAt = uint32(block.timestamp) + _period;
	}
	
	function _getUserVP(address _user) internal view returns(uint256) {
		return (goveranceToken.balanceOf(_user) / (10**goveranceToken.decimals()));
	}
	
	function yes() external {
		require(block.timestamp < endAt, "Voting ended");
		require(voted[msg.sender] == false, "You already voted!");
		uint256 vp = _getUserVP(msg.sender);
		require(vp > 0, "You don't have any goverance token to vote");
		
		voted[msg.sender] = true;
		votedTo[msg.sender] = 1;
		userVotdedPower[msg.sender] = vp;
		
		yesPower += vp;
		
		emit Vote({
			_to: "Yes",
			_voter: msg.sender,
			_vp: vp,
			_time: block.timestamp
		});
	}
	
	function no() external {
		require(block.timestamp < endAt, "Voting ended");
		require(voted[msg.sender] == false, "You already voted!");
		uint256 vp = _getUserVP(msg.sender);
		require(vp > 0, "You don't have any goverance token to vote");
		
		voted[msg.sender] = true;
		votedTo[msg.sender] = 0;
		userVotdedPower[msg.sender] = vp;
		
		noPower += vp;
		
		emit Vote({
			_to: "No",
			_voter: msg.sender,
			_vp: vp,
			_time: block.timestamp
		});
	}
	
	function userVotingStatus(address _user) external view returns(bool, uint8, uint256) {
		return (voted[_user], votedTo[_user], userVotdedPower[_user]);
	}
	
	function voteCounts() external view returns(uint256, uint256) {
		return (yesPower, noPower);
	}
	
	function result() external view returns(string memory res) {
		require(block.timestamp >= endAt, "Voting not ended");
		
		if (yesPower == noPower) {
			res = "Equal";
		} else if (yesPower > noPower) {
			res = "Yes";
		} else {
			res = "No";
		}
	}
	
}
