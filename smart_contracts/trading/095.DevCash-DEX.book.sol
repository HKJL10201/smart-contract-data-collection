pragma solidity ^0.5.0;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function decimals() public view returns (uint);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract book {
    //          n/d wei = 1 token
    uint public n = 100456400; //numerator
    uint public d = 787; //denominator
    uint public rT; //token remainder (out of n)
    uint public rW; //wei remainder (out of d)

    address public token = 0x8c8048318590aF2124a2e3c916cCdAC53bdBd74d;

    struct order{
        address payable trader;
        uint amount;
    }

    order[] public orders;
    uint public o; //orderIndex

    //address token, uint price,uint priceDenominator
    constructor() public {
       // token = _token;
       // unitPrice = price;
        //d = 10**priceDenominator;
    }

    function () external payable{
        _buy(msg.sender,msg.value);
    }

    function buy () public payable{
        _buy(msg.sender,msg.value);
    }

    function _buy(address payable buyer, uint amountWei) internal {
        amountWei += rW;
        uint amountTokens = amountWei*d/n;
        rW = amountWei-(amountTokens*n/d);

        uint tokenBalance = tokenBalance();

        if(tokenBalance<d){
            orders.push(order(buyer,amountTokens));
        } else {
            while(o!=orders.length && amountWei>orders[o].amount){
                amountWei-= orders[o].amount;
                orders[o].trader.transfer(orders[o].amount);
                o++;
            }

            if(tokenBalance>amountTokens+d){
                ERC20(token).transfer(buyer,amountTokens);
                orders[o].trader.transfer(amountWei-rW);
                orders[o].amount-=amountWei;
            } else {
                ERC20(token).transfer(buyer,tokenBalance); rT=0;
                uint tokenOrderAmount = amountTokens-tokenBalance;
                delete orders; o=0; orders.push(order(buyer,tokenOrderAmount));
            }
        }
    }

    function sell(uint amountTokens) public {

        address payable seller = msg.sender;
        ERC20(token).transferFrom(msg.sender,address(this),amountTokens);

        amountTokens += rT;
        uint amountWei = amountTokens*n/d;
        rT = amountTokens-(amountWei*d/n);

        uint weiBalance = weiBalance();

        if (weiBalance<n){
            orders.push(order(seller,amountWei));
        } else {
            while(o != orders.length  && amountTokens>orders[o].amount){
                amountTokens-= orders[o].amount;
                ERC20(token).transfer(orders[o].trader,orders[o].amount);
                o++;
            }
            if (weiBalance>=amountWei+n){
                seller.transfer(amountWei);
                ERC20(token).transfer(orders[o].trader,amountTokens-rT);
                orders[o].amount -= amountTokens;

            } else {
                seller.transfer(weiBalance); rW=0;
                uint weiOrderAmount = amountWei - weiBalance;
                delete orders; o=0; orders.push(order(seller,weiOrderAmount));
            }
        }
    }

    function tokenBalance() public view returns (uint){
        return ERC20(token).balanceOf(address(this));
    }

    function weiBalance() public view returns (uint){
        return address(this).balance;
    }
}
