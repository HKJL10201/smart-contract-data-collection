// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract EnergyToken is  ERC20Capped, ERC20Burnable {
address payable public owner;
uint256 public blockreward;
uint256 public energyTokenPerKWh;
uint256 public tokenPrice;

event TransferSuccessful(bytes32 indexed txHash);

constructor (uint256 initialSupply, uint256 cap, uint256 reward, uint256 _energyTokenPerKWh, uint256 price) ERC20 ("EnergyToken", "EGT") ERC20Capped(cap * (10 ** decimals()))
{
    owner= payable(msg.sender);
    _mint(owner,initialSupply * (10 ** decimals()));

    blockreward =reward * (10 ** decimals());
    energyTokenPerKWh =_energyTokenPerKWh;
    tokenPrice = price;

}
function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

function setBlockReward( uint256 reward ) public OnlyOwner
{
    blockreward=reward * (10 ** decimals());

}
function destroy () public OnlyOwner
{
    selfdestruct(payable(owner));
    
    
}
modifier OnlyOwner
{
    require(msg.sender==owner, "only the owner can call this function");
    _;
}

function convertToTokens(uint256 energyAmountInKWh) public view returns (uint256) {
        return energyAmountInKWh * energyTokenPerKWh;
    }
function convertToEther(uint256 tokenAmount) public view returns (uint256) {
        return (tokenAmount * tokenPrice);
    }

/*function transferTokens(address _from, address _to, uint256 _amount) public {
    // Retrieve the token contract instance
    IERC20 token = IERC20(0x9e5c4D8912574d616E956c689FECEc4149DEf3AD);

    // Approve the contract to spend tokens on behalf of the sender
    token.approve(address(this), _amount);

    // Transfer tokens from _from to _to
    token.transferFrom(_from, _to, _amount);
}*/}
