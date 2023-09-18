pragma solidity 0.6.4;

contract Bank {

    int bal;

        constructor() public
        {
                bal = 10;
        }

        function getBalance() view public returns(int)
        {
                return bal;
        }


        function withdraw(int amt) public
        { 
                bal = bal - amt;
        }

        function deposit(int amt) public 
        {
                bal = bal + amt;
        }


}
