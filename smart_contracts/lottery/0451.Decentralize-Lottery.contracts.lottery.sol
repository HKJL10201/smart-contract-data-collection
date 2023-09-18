pragma solidity 0.6.2;

contract Lottery {
struct Entry {
address userAddress;
string name;
uint256 amount;
}

Entry[] public entries;
uint256 endTime;

event NewEntry(
address _userAddress,
uint256 _amount,
uint256 _indexInArray
);

event Winner(
uint256 _winningIndex
);

function enterLottery(string memory _name) public payable {
/// check if user sent atleast 0.001 ETH
require(msg.value >= 0.001 ether, 'not sent enough ether');

if(entries.length == 0) {
endTime = now + 10 minutes;
}

/// add into the entries array
entries.push(
Entry({
userAddress: msg.sender,
name: _name,
amount: msg.value
})
);

emit NewEntry(msg.sender, msg.value, entries.length - 1);
}

function generateRandomNumber(uint256 _seed) public view returns(uint256) {
return uint256(keccak256(abi.encodePacked(now, _seed))) % entries.length;
}

function endLottery() public {
// check if endTime is acheived
require(now >= endTime, 'please wait for lottery to end');

uint256 _winningAmount = address(this).balance / 3;

for(uint256 i = 1; i <= 3; i++) {
uint256 _winningIndex = generateRandomNumber(i);
address _winningAddress = entries[_winningIndex].userAddress;
payable(_winningAddress).transfer(_winningAmount);

emit Winner(_winningIndex);
}

delete entries;
}
}