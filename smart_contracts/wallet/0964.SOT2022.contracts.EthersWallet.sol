// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract EthersWallet is Ownable {
  //owner[*]
  //constructor[*]
  //receive[*]
  //withdraw[*]
  //balance[*]
  //Verificación del ownership mediante librería de open zeppelin[*]
  //Truffle[*]
  constructor() {
    transferOwnership(msg.sender);
  }
  event LogWithdrawAll(address owner, uint256 balance);
  event LogWithdrawTo(address wallet, uint256 amount);
  event LogwithdrawBalance(address owner, uint256 amount);
  
  function withdrawAll() external onlyOwner{
    require(address(this).balance > 0, "No tienes nada para retirar");
    uint256 balanceContract = address(this).balance;
    payable(owner()).transfer(balanceContract);
    emit LogWithdrawAll(owner(),balanceContract);
  }
  function withdrawBalance(uint256 _amount) external onlyOwner{
    require(_amount > 0, "Debes especificar un valor mayor a 0 para retirar");
    require(address(this).balance >= _amount, "No tienes esa cantidad para retirar");
    payable(owner()).transfer(_amount);
    emit LogWithdrawAll(owner(),_amount);
  }
  function withdrawTo(address _wallet,uint256 _amount) external onlyOwner{
    require(_amount > 0, "Debes especificar un valor mayor a 0 para enviar");
    require(address(this).balance >= _amount, "No tienes esa cantidad de ethers para enviar");
    payable(_wallet).transfer(_amount);
    emit LogWithdrawTo(_wallet,_amount);
  }
  receive() external payable {

  }
  function getBalance() external view returns(uint256){
    return address(this).balance;
  }
  function getOwner() external view returns(address){
    return owner();
  }
}
