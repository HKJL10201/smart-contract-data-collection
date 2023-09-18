// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";


//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Gold is ERC20{

    constructor()public ERC20("Gold","GD"){
        _mint(msg.sender,1000*10**18);
    }

}

contract Silver is ERC20{

    constructor()public ERC20("Silver","SL"){
        _mint(msg.sender,1000*10**18);
    }

}
//1000000000000000000
contract swapToken{

    constructor(){
        
    }

    function swap(address _token1,address _token2,address _address1,address _address2,uint _amount) public{

    IERC20  token1;
    IERC20  token2;
    address  owner;
    address  bank;
    uint  amount;
    uint  rec;
        token1=IERC20(_token1);
        token2=IERC20(_token2);
        owner=_address1;
        bank=_address2;
        amount=_amount;
        rec=2*_amount;
        token1.transferFrom(owner,bank,amount);
        token2.transferFrom(bank,owner,rec);
    }
}

contract PriceData{
    AggregatorV3Interface btcpricefeed;
    AggregatorV3Interface ethpricefeed;
    constructor(){
        btcpricefeed=AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
        ethpricefeed=AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }
    function getEthPrice()public view returns (int){
        (,int price,,,)=ethpricefeed.latestRoundData();
        return price;
    }
    function getBtcPrice()public view returns (int){
        (,int price,,,)=btcpricefeed.latestRoundData();
        return price;
    }
    function convert_rate(int256 ethAmount) public view returns(int256){
        int256 ethprice=getEthPrice();
        int256 btcprice=getBtcPrice();
        require(ethprice > 0 && btcprice > 0, "Invalid price feed");
        int btcamount=(ethAmount*btcprice)/ethprice;
        return btcamount;
    }
}


