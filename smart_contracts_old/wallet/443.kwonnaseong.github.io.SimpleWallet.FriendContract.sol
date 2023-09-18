pragma solidity ^0.4.24;

contract FriendContract{
    mapping(address=>address[]) friends_list;
    
    function addFriend(address friend) public {
        friends_list[msg.sender].push(friend);
    }
    
    function getFriendsList() public view returns (address[]) {
        return (friends_list[msg.sender]);
    }
}