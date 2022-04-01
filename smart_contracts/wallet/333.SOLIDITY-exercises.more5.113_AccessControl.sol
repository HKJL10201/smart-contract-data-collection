//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract AccessControl {
    //This line is only for testing. After deployment, you can enter this in the second input
    //field. For the first input field, make ADMIN as public to get the bytes32. And paster these 
    //two on "allRoles" input area after deployment.
    address private msgsender = msg.sender;


    //Event are not obligatory but we will probably need it to see changes in user roles.
    //We are using indexed keywords, so that we can filter logs easily.
    event GrantRole(bytes32 indexed _role, address indexed _account);
    event RevokeRole(bytes32 indexed _role, address indexed _account);

    //We define roles as bytes32 to save on gas.
    mapping(bytes32 => mapping(address => bool)) public allRoles;

    //Here we are setting two roles. They are in capital letters because we are using constant.
    //And when we are using constant, convention is variable name should be capital.
    //Instead of these two line down, I can say: string private constant ADMIN = "ADMIN" but this
    //will cost more gas. 
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    //0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 private constant USER = keccak256(abi.encodePacked("USER"));
    //0x2db9fd3d099848027c2383d0a083396f6c41510d7acfd92adc99b6cffcf31e96

    //here modifier will check if modifier parameter exists for the msg.sender
    //If it exists, it will continue. For parameter we will use "ADMIN" keyword.
    //Because "ADMIN" keyword will be spared for the contract deployer with the
    //constructor. 
    modifier onlyOwner(bytes32 _role) {
        require(allRoles[_role][msg.sender], "You are not owner");
        _;
    }

    //To define admin role for the deployer, we will use grantRole1 function. We 
    // can use it because it is internal. We need to use this function because that's the only way to
    // add deployer address to the mapping as "ADMIN".
    constructor() {
        grantRole1(ADMIN, msg.sender);
    }

    //This function will only be called by the owner. We are making this function as internal
    // because no need to make external. Because we wont let external calls to this function.
    // Calling this function will be from another function which will be only accessible to the 
    // owner(ADMIN) of the contract. To define admin role for the function we will use 
    // use a modifier. To set admin as contract deployer we will use constructor.
    function grantRole1(bytes32 _role, address _account) internal {
        allRoles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grandRole2(bytes32 _role, address _account) external onlyOwner(ADMIN) {
        grantRole1(_role, _account);
    }

    function revokeRole1(bytes32 _role, address _account) internal {
        allRoles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function revokeRole2(bytes32 _role, address _account) external onlyOwner(ADMIN) {
        revokeRole1(_role, _account);
    }
    
}