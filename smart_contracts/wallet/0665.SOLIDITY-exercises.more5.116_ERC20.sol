//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

interface IERC20 {
    //1.Total supply of ERC20 token.
    function totalSupply() external view returns(uint);

    //2.The amount of ERC20 token that a contract has.
    function balanceOf(address account) external view returns(uint);

    //3.This allows to transfer ERC20 token to be transferred from one contract to another.
    function transfer(address recipient, uint amount) external returns(bool);

    //5.Holder can set a certain limit for the spender here. Spender will be allowed to 
    //spend only from the allowed amount.
    function allowance(address owner, address spender) external view returns(uint);

    //4.Power of Attorney function: I can authorize another contract to transfer my tokens.
    //In this case, spender will be authorized to transfer my tokens.
    function approve(address spender, uint amount) external returns(bool);

    //6. The spender can call this function, it will send tokens to another
    //recipient. amount is amount of transfer.
    function transferFrom(address sender, address recipient, uint amount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

}

contract ERC20 {
    //Total supply of our token. If we mint, totalSupply will increase. If we burn, it will decrease.
    uint public totalSupply;

    //here we create a table to see how much of a token any account has.
    //address is holder and uint is amount.
    mapping(address => uint) public balanceOf; 

    //The first address is the holder. The second address is the spender. uint is the allowed amount
    mapping(address =>mapping(address => uint)) public allowance;

    //Here are some metadata about our ERC20 token. Name and decimal. 
    //Decimal means how many 
    //Most ERC20 tokens have a decimal of 18.
    string public name = "Test";
    string public symbol = "TEST";
    uint8 public decimals = 18; // Here it means 10**18 is equal to one of the tokens above. 
    //For example, US Dollar has two decimals, 100 cents equals to 1 dollar. So in other words,
    //it means 18 zeros.

    //Here we are transferring tokens from Holder to any recipient. That's why we are updating
    //recipient and holder balance.
    function transfer(address recipient, uint amount) external returns(bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    //We do not need the allowance function. Because we can set that by using the second mapping.
    //Here Holder will set the allowance of the spender.
    function approve(address spender, uint amount) external returns(bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //The spender can call this function, it will send tokens to another
    //recipient. amount is amount of transfer.
    function transferFrom(address sender, address recipient, uint amount) external returns(bool){
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    //Minting function: This function is generally restricted. For this exercise,
    //we will let the msg.sender to mint as much as he/she wants.
    //Then in event section, we set sender to address(0).
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    //As we have created mint  function (create new toke), we should also create
    // burn function (remove tokens from circulation).
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}