pragma solidity ^0.4.6;

/*
    Copyright 2016, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import "./interface/Controlled.sol";
import "./RLP.sol";

contract SingleChoice is Controlled {
    using RLP for RLP.RLPItem;
    using RLP for RLP.Iterator;
    using RLP for bytes;

    string public question;
    string[] public options;
    int[] public result;
    bytes32 uid;

    function SingleChoice(address _controller, bytes _rlpDefinition, uint salt) Controlled() {

        uid = sha3(block.blockhash(block.number-1), salt);
        controller = _controller;

        var itmPoll = _rlpDefinition.toRLPItem(true);

        assert(itmPoll.isList());

        var itrPoll = itmPoll.iterator();

        question = itrPoll.next().toAscii();

        var itmOptions = itrPoll.next();

        assert(itmOptions.isList());

        var itrOptions  = itmOptions.iterator();

        while(itrOptions.hasNext()) {
            options.length++;
            options[options.length-1] = itrOptions.next().toAscii();
        }

        result.length = options.length;
    }

    function pollType() constant returns (bytes32) {
        return bytes32("SINGLE_CHOICE");
    }

    function isValid(bytes32 _ballot) constant returns(bool) {
        uint v = uint(_ballot) / (2**248);
        if (v >= options.length) {
          return false;
        }
        if (getBallot(v) != _ballot) {
          return false;
        }
        return true;
    }

    function deltaVote(int _amount, bytes32 _ballot) onlyController returns (bool _succes) {
        if (!isValid(_ballot)) {
          return false;
        }
        uint v = uint(_ballot) / (2**248);
        result[v] += _amount;
        return true;
    }

    function nOptions() constant returns(uint) {
        return options.length;
    }

    function getBallot(uint _option) constant returns(bytes32) {
        return bytes32((_option * (2**248)) + (uint(sha3(uid, _option)) & (2**248 -1)));
    }
}
