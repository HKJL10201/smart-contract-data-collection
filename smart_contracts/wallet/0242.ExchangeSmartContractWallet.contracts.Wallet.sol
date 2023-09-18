// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;

import './IMasterWallet.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';

contract Wallet is Initializable {
    address public _master;

    event codeSize(uint256 ramainGas);

    function initialize(address master) public initializer {
        _master = master;
    }

    function transfer(address ERC20) public {
        if(ERC20 == address(0)) {
            payable(IMasterWallet(_master).getHotWallet()).transfer(address(this).balance);
        } else {
            SafeERC20.safeTransfer(IERC20(ERC20), IMasterWallet(_master).getHotWallet(), IERC20(ERC20).balanceOf(address(this)));
        }
    }

    function isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    fallback() external payable {
        // uint256 left = gasleft();
        // emit codeSize(left);
        // if(!isContract(msg.sender)) {
        if(msg.sender == tx.origin) {
            payable(IMasterWallet(_master).getHotWallet()).transfer(address(this).balance);
        }
    }

    // receive() external payable {
    //     emit codeSize(gasleft());
    //     if(gasleft() > 2000 && !isContract(msg.sender)) {
    //         payable(IMasterWallet(_master).getHotWallet()).transfer(address(this).balance);
    //     }
    // }
}