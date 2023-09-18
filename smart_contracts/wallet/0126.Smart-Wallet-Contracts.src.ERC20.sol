// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.17;

contract PayzToken{
     uint256 public immutable supply = 200000;
     mapping(address=>uint256)public balanceOf;
     bytes32 public name = "PayzToken";
     bytes32 public Symbol = "PYZ";
     uint256 totalsupply;


event MoneyTransfer(address indexed from,address indexed to,uint256 amount);
event Minted(address indexed to,uint256 amount);

        modifier SupplyNotExceeded(){
            require(totalsupply + 1 <= supply);
            _;
        }

     function Transfer(uint256 _amount,address _to)public payable{
         balanceOf[msg.sender]-=_amount;
          balanceOf[_to]+=_amount;
          emit MoneyTransfer(msg.sender, _to, _amount);
     }

     function Mint(address _to)public{
         balanceOf[_to] +=1;
         totalsupply += 1;
     }

     function GetPayzBalance(address account)public view returns(uint256){
            return balanceOf[account];
     }
//Contract Address: 0x68deCe5e69a6847101b206B7042611962FCaD950


}
