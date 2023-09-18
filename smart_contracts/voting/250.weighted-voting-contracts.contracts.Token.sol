pragma solidity ^0.4.19;

import './iToken.sol';
import './SafeMath.sol';

contract Token is iToken, SafeMath {
    string public name;                   //group name
    string public symbol;                 //An identifier: eg WGT
    string public version = 'G0.1';       //group 0.1 standard. Just an arbitrary versioning scheme.
    uint8 public decimals;                //How many decimals to show
    uint256 public initialAmount;         //How many tokens each user gets initially
    address[] public addressIndices;      //Added addresses
    uint256 public totalSupply;                  //Total supply of the token
    mapping(address => uint256) balances;                                       //Total balances per address
    mapping(address => address[]) memberAddressIndices;                         //Addresses with token value per member
    mapping (address => mapping (address => uint256)) addressDistribution;      //Distribution per member

    function Token(string _groupName, string _tokenSymbol, uint256 _initialAmount, uint8 _decimalUnits) public {
        initialAmount = _initialAmount;
        balances[msg.sender] = _initialAmount;                              // Give the creator all initial tokens
        addressDistribution[msg.sender][msg.sender] = _initialAmount;       // Creator have all of his initial tokens
        totalSupply = _initialAmount;                                       // Update total supply
        name = _groupName;                                                  // Set the name for display purposes
        decimals = _decimalUnits;                                           // Amount of decimals for display purposes
        symbol = _tokenSymbol;                                              // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // Assumes totalSupply and initialAmount can't be over max (2^256 - 1)
        if (balances[msg.sender] < _value || balances[_to] + _value <= balances[_to]) {
            return false;
        }
        if (addressDistribution[msg.sender][msg.sender] < _value) {
            return false;
        }
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        addressDistribution[msg.sender][msg.sender] = safeSub(addressDistribution[msg.sender][msg.sender], _value);
        addressDistribution[msg.sender][_to] = safeAdd(addressDistribution[msg.sender][_to], _value);

        LogTransfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Assumes totalSupply and initialAmount can't be over max (2^256 - 1)
        if (balances[_from] < _value || balances[_to] + _value <= balances[_to]) {
            return false;
        }
        if (addressDistribution[msg.sender][_from] < _value || addressDistribution[msg.sender][_to] + _value <= addressDistribution[msg.sender][_to]) {
            return false;
        }
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        addressDistribution[msg.sender][_from] = safeSub(addressDistribution[msg.sender][_from], _value);
        addressDistribution[msg.sender][_to] = safeAdd(addressDistribution[msg.sender][_to], _value);

        LogTransfer(_from, _to, _value);
        return true;
    }

    function reset() public returns (bool success) {
        /// TODO: implement. Have to use memberAddressIndices.. https://medium.com/@blockchain101/looping-in-solidity-32c621e05c22
        return true;
    }

    function addMember() public returns (bool success) {
        for (uint i=0; i < addressIndices.length; i++) {
            if (addressIndices[i] == msg.sender) {
                // Address already registered with the token
                return false;
            }
        }
        addressIndices.push(msg.sender);
        balances[msg.sender] = safeAdd(balances[msg.sender], initialAmount);
        addressDistribution[msg.sender][msg.sender] = initialAmount;
        totalSupply = safeAdd(totalSupply, initialAmount);

        LogAddMember(msg.sender);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function distributionOf(address _owner) public view returns (address[] addresses, uint256[] addressBalances) {
        // TODO: implement. Or just do that in mongoDb, otherwise it's not free :)
        // TODO: Return struct
    }

    function getMembers() public view returns (address[] addresses) {
        // TODO: implement. Or just do that in mongoDb, otherwise it's not free :)
        return addressIndices;
    }

    function getTotalSupply() public view returns (uint256 supply) {
        return totalSupply;
    }

    function getName() public view returns (string name) {
        return name;
    }

    function getSymbol() public view returns (string symbol) {
        return symbol;
    }

    function getVersion() public view returns (string version) {
        return version;
    }
}
