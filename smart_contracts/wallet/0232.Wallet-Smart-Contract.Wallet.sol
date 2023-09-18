//SPDX-License-Identifier: MIT

pragma solidity >0.8.14;


contract MyWallet {

    address myadd = msg.sender;
    uint256 Mybal;
   

    //to give eth to address
    function ShowBalance () public payable {
        Mybal += msg.value;
    }

    //to get balance
    function GetBalance () public view returns(uint) {
        return address(this).balance;
    }
    

    // withdrat to owner
    function withdraw () public {
        address payable to = payable(msg.sender);
        to.transfer(GetBalance());
    }


    // to withdraw a specific address
    function withdrawToAddress (address payable _Newadd) public { 
        _Newadd.transfer(GetBalance());
    }

}
