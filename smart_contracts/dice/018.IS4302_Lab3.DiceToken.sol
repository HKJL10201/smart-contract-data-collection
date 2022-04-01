pragma solidity ^0.5.0;

import "./ERC20.sol";

/*
E.g. 
deploy DiceToken contract
input 10 Finney into value
exceute getCredit
execute checkCredit have 1 DT

conversion:
1 ETH = 1 * 10^18 wei
0.01 ETH = 1 DT
1 ETH = 1 * 10^2  DT
Hence,
1 DT = 1 * 10^16 wei

1 ETH = 1 * 10^3 finney
0.01 ETH = 1 DT
1 ETH = 1 * 10^2  DT
Hence,
1 DT = 10^1 finney
*/

contract DiceToken {
    // DiceToken contract variable is ERC20 object named erc20contract
    ERC20 erc20Contract;
    uint256 supplyLimit;
    uint256 currentSupply;
    address owner;

    constructor() public {
        // e is instantiated as ERC20 class instance
        // this is different from using an account to deploy ERC20 to an address, then passing the address as constructor arg
        // in this case, every deployment of DiceToken will create its own ERC20 instance, no separate deploy of ERC20 
        ERC20 e = new ERC20();
        // DiceToken required variable of ERC20 object is e. As ERC20 object, DiceToken based on ERC20 contract methods.
        erc20Contract = e;
        // owner is set as the caller / msg.sender of the DiceToken contract
        owner = msg.sender;
        // max supplyLimit of DT is 10000 tokens
        supplyLimit = 10000;
    }

    // buyer user account calls getCredit to allow wei to be converted to DT
    function getCredit() public payable {
        // In Remix, caller will send wei unit even if specify other unit like ether
        // which could be some kind of large amount in wei, to convert to DT (where 1 DT = 1 * 10^16 wei, is not sent in ETH)
        // hence need to divide by 1 * 10^16 to convert wei unit to DT unit
        uint256 amt = msg.value / 10000000000000000;

        // totalSupply is the current total number of DT 
        // supplyLimit is the maximum supply of DT
        // current totalSupply + new supply / amt cannot exceed max supplyLimit
        // cannot mint or add more DT anymore if exceed supplyLimit
        require(erc20Contract.totalSupply() + amt < supplyLimit, "DT supply is not enough");

        // mint method is the amount to add DT to the current totalSupply of DT 
        // this will mint DT with ETH, reduce ETH and add DT into the caller account balance
        erc20Contract.mint(msg.sender, amt);
    }

    // in future may not make this function public
    // function diceTokenMarketGetCredit(uint value) public payable {
    //     uint256 amt = value / 10000000000000000; // Get DTs eligible (in wei) where (1 DT = 0.01 ETH) OR (1 DT = 10 Finney ) 
    //     require(erc20Contract.totalSupply() + amt < supplyLimit, "DT supply is not enough");
    //     erc20Contract.mint(msg.sender, amt);
    // }

    // checkCredit to check the balance amount of (DT or ETH)??? the caller / msg.sender has
    function checkCredit() public view returns(uint256) {
        return erc20Contract.balanceOf(msg.sender);
    }

    // in future may not make this function public, in tutorial leave here for debugging reasons
    function diceTokenMarketCheckCredit(address buyerAddress) public view returns(uint256) {
        return erc20Contract.balanceOf(buyerAddress);
    }

    // function transferFrom(address _from, address _to, uint256 _value) public {
    //     erc20Contract.transferFrom(_from, _to, _value);
    // }

    function diceTokenTransferFrom(address _from, address _spender, address _to, uint256 _value) public {
        erc20Contract.diceTokenTransferFrom(_from, _spender, _to, _value);
    }

    function transfer(address _to, uint256 _value) public {
        erc20Contract.transfer(_to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        erc20Contract.approve(_spender, _value);
    }

    function diceTokenApprove(address _owner, address _spender, uint256 _value) public returns (bool) {
        erc20Contract.diceTokenApprove(_owner ,_spender, _value);
    }

    function checkAllowance(address _owner, address _spender) public view returns (uint256) {
        erc20Contract.allowance(_owner, _spender);
    }

}
