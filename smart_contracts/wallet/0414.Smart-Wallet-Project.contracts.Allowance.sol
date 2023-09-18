//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// Adding Ownable openzapplin library for Owner controls
import "@openzeppelin/contracts/access/Ownable.sol";


// Adding Safemath library to prevent uint wrapping
// import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";


contract Allowance is Ownable {
    
    // using SafeMath for uint;

    mapping(address => uint) Recipent;
    // created modifier which verifies user is either allowed or the owner
    modifier Owner_or_Allowed(uint _amount) {
        require(msg.sender == owner() || Recipent[msg.sender] >= _amount, "You are not authorised");
        _;
    }
    // event triggers when allowance alloted
    event AllowanceSet(address indexed _beneficiary, uint _amount);
    // event triggers when allowance is reduced 
    event ReducedAllowance(address indexed _whom, address indexed _who, uint _prevAmount, uint _newAmount);
    // Function to set the allowance for recipents
    function SetAllowance(address _to, uint _amount) public onlyOwner(){
        Recipent[_to] = _amount;
        emit AllowanceSet(_to, _amount);
    }
    // functioin to reduce allowance either by spending money or by owner
    function ReduceAllowance(address _who, uint _amount) public Owner_or_Allowed(_amount) {
        Recipent[_who] -= _amount;
        emit ReducedAllowance(msg.sender, _who, Recipent[_who]+(_amount), Recipent[_who]);
    }
}