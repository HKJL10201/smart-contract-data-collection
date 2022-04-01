pragma solidity ^0.5.0;

import "./zeppelin/ownership/Ownable.sol";

import "./interfaces/PhoenixInterface.sol";
import "./interfaces/PhoenixIdentityInterface.sol";
import "./interfaces/PhoenixIdentityResolverInterface.sol";

contract PhoenixIdentityResolver is Ownable {
    string public phoenixIdentityName;
    string public phoenixIdentityDescription;

    address public phoenixIdentityAddress;

    bool public callOnAddition;
    bool public callOnRemoval;

    constructor(
        string memory _phoenixIdentityName, string memory _phoenixIdentityDescription,
        address _phoenixIdentityAddress,
        bool _callOnAddition, bool _callOnRemoval
    )
        public
    {
        phoenixIdentityName = _phoenixIdentityName;
        phoenixIdentityDescription = _phoenixIdentityDescription;

        setPhoenixIdentityAddress(_phoenixIdentityAddress);

        callOnAddition = _callOnAddition;
        callOnRemoval = _callOnRemoval;
    }

    modifier senderIsPhoenixIdentity() {
        require(msg.sender == phoenixIdentityAddress, "Did not originate from PhoenixIdentity.");
        _;
    }

    // this can be overriden to initialize other variables, such as e.g. an ERC20 object to wrap the PHNX token
    function setPhoenixIdentityAddress(address _phoenixIdentityAddress) public onlyOwner {
        phoenixIdentityAddress = _phoenixIdentityAddress;
    }

    // if callOnAddition is true, onAddition is called every time a user adds the contract as a resolver
    // this implementation **must** use the senderIsPhoenixIdentity modifier
    // returning false will disallow users from adding the contract as a resolver
    function onAddition(uint ein, uint allowance, bytes memory extraData) public returns (bool);

    // if callOnRemoval is true, onRemoval is called every time a user removes the contract as a resolver
    // this function **must** use the senderIsPhoenixIdentity modifier
    // returning false soft prevents users from removing the contract as a resolver
    // however, note that they can force remove the resolver, bypassing onRemoval
    function onRemoval(uint ein, bytes memory extraData) public returns (bool);

    function transferPhoenixBalanceTo(uint einTo, uint amount) internal {
        PhoenixInterface phoenix = PhoenixInterface(PhoenixIdentityInterface(phoenixIdentityAddress).phoenixTokenAddress());
        require(phoenix.approveAndCall(phoenixIdentityAddress, amount, abi.encode(einTo)), "Unsuccessful approveAndCall.");
    }

    function withdrawPhoenixBalanceTo(address to, uint amount) internal {
        PhoenixInterface phoenix = PhoenixInterface(PhoenixIdentityInterface(phoenixIdentityAddress).phoenixTokenAddress());
        require(phoenix.transfer(to, amount), "Unsuccessful transfer.");
    }

    function transferPhoenixBalanceToVia(address via, uint einTo, uint amount, bytes memory phoenixIdentityCallBytes) internal {
        PhoenixInterface phoenix = PhoenixInterface(PhoenixIdentityInterface(phoenixIdentityAddress).phoenixTokenAddress());
        require(
            phoenix.approveAndCall(
                phoenixIdentityAddress, amount, abi.encode(true, address(this), via, einTo, phoenixIdentityCallBytes)
            ),
            "Unsuccessful approveAndCall."
        );
    }

    function withdrawPhoenixBalanceToVia(address via, address to, uint amount, bytes memory phoenixIdentityCallBytes) internal {
        PhoenixInterface phoenix = PhoenixInterface(PhoenixIdentityInterface(phoenixIdentityAddress).phoenixTokenAddress());
        require(
            phoenix.approveAndCall(
                phoenixIdentityAddress, amount, abi.encode(false, address(this), via, to, phoenixIdentityCallBytes)
            ),
            "Unsuccessful approveAndCall."
        );
    }
}