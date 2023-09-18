/*
 * Copyright 2019 Blocktopus Single Member P.C.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http:*www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.1;

/**
 * @title Blocktopus Guard library
 *
 * @dev Guards a function from being called by a non-Blocktopus verified wallet.
 */

contract BlocktopusGuarded {

  /* Using "openzeppelin-solidity/contracts/cryptography/ECDSA.sol" from openzeppelin-solidity@2.3.0 */
  using ECDSA for bytes32;

  address private _blocktopusAddress = 0xE7F6151aB2745Ad4bDa9925c06EEe3C3745A4E74;

  /**
   * @dev Guards a function from being called by a non-Blocktopus verified wallet.
   */
  modifier BlocktopusOnly() {
    address recoveredAddress = keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(msg.data);
    require(_blocktopusAddress == recoveredAddress, "Recovered address doesn't match Blocktopus'");
    _;
  }
}
