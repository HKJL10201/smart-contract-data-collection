// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@artman325/community/contracts/interfaces/ICommunity.sol";

contract CommunityMock is ICommunity {
    uint256 count = 5;
    
    // function memberCount(string memory role) public override view returns(uint256) {
    //     return count;
    // }
    function setMemberCount(uint256 _count) public {
        count = _count;
    }
    
    // function getRoles(address member)public override view returns(string[] memory){
    //     string[] memory list = new string[](5);
    //     list[0] = 'owners';
    //     list[1] = 'admins';
    //     list[2] = 'members';
    //     list[3] = 'sub-admins';
    //     list[4] = 'unkwnowns';
    //     return list;
        
    // }
    // function getMember(string memory role) public override view returns(address[] memory){
    //     address[] memory list = new address[](0);
    //     return list;
    // }


    function initialize(
        address implState,
        address implView,
        address hook, 
        address costManager, 
        string memory name, 
        string memory symbol
    ) public {

    }
    
    function addressesCount(uint8 /*roleIndex*/) external view returns(uint256) {
        return count;
    }

    function getRoles(address /*member*/)external pure returns(uint8[] memory) {
        uint8[] memory list = new uint8[](5);
        list[0] = 1;
        list[1] = 2;
        list[2] = 3;
        list[3] = 4;
        list[4] = 5;
        return list;
    }
    function getAddresses(uint8/* rolesIndex*/) external pure returns(address[] memory) {
        // address[] memory list = new address[](0);
        // return list;
        return new address[](0);
    }


    function getRoles(address[] calldata members)public override view returns(uint8[][] memory list){

 uint8[] memory list2 = new uint8[](5);
        list2[0] = 1;
        list2[1] = 2;
        list2[2] = 3;
        list2[3] = 4;
        list2[4] = 5;

        list = new uint8[][](members.length);

        for(uint256 i = 0; i < members.length; i++) {
            list[i] = list2;
        }


        return list;

    }

    function getAddresses(uint8[] memory/* rolesIndex*/) public override pure returns(address[][] memory){
        address[][]memory list = new address[][](0);
        return list;
    }
    
}
