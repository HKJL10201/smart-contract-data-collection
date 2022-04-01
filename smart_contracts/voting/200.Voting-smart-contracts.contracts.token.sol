pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
//import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract token is ERC20, ERC20Detailed{
   // using SafeERC20 for ITRC20;
   // using SafeERC20 for ERC20;
  //  IERC20 public _token;


    address admin;
    constructor() ERC20Detailed("SST tokens","sst",18)   public {
         admin = msg.sender;
         _mint(admin, 1000);
         
        //  _token = token;

       
    } 



    

   // function transfer_to_admin(uint cli, uint tn) public {
     //   balanceOf(cli) =   balanceOf(cli) - tn;
       // balanceOf(msg.sender) =   balanceOf(msg.sender) + tn;

    //}
}