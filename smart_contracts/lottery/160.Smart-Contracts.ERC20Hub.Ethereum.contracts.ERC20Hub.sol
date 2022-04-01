//SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9;
import './ERC20.sol';

contract ERC20Hub{

    address[] public ERC20Tokens;

    function createERC20Token(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public returns(bool){
        ERC20 token = new ERC20(_name, _symbol, _decimals, _totalSupply, msg.sender);
        ERC20Tokens.push(address(token));
        return true;
    }

    function viewERC20Tokens() public view returns(address[] memory){
        return ERC20Tokens;
    }
}