/** 
 * Copyright (c) 2019 Samvid Dharanikota
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
 * associated documentation files (the "Software"), to deal in the Software without restriction, 
 * including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial 
 * portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
 * LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
 * NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

pragma solidity ^0.5.0;
import "./Oraclize.sol";
import "./strings.sol";

contract Lottery is usingOraclize {

  using strings for *;

  uint number_participants;
  address payable[] participants;
  address payable creator;
  uint random;
  uint bets;
  uint win_percentage;

  bytes32 qID;
  uint256 witness;
  uint256 seed;
  uint256 iter_exp;
  uint256 prime;

  // Set minimum betting amount = 1 ether
  modifier minAmount() {
    require(msg.value >= 1 ether);
    _;
  }

  // Ensure only the lottery owner can call certain methods
  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }

  // Ensure that contract has a non-zero balance before performing a draw
  modifier nonZeroBalance(){
    require(address(this).balance > 0);
    _;
  }

  // Ensure that bets have not been placed yet
  modifier noBets(){
    require(bets == 0);
    _;
  }

  event drew(
    address indexed winner,
    uint amount
  );

  event LogNewOraclizeQuery(string description);

  constructor() public {
    creator = msg.sender;
    // Uncomment the following line and replace the value with the address obtained from Ethereum-Bridge (when testing on a private network)
    // OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
  }

  // Method called by participants to participate in the lottery
  function bet() public payable minAmount {
    participants.push(msg.sender);
    number_participants++;
    bets = bets + msg.value;
  }

  // Getter method for the number of participants
  function get_number_participants() public view returns (uint) {
    return  number_participants;
  }

  // Method to allow owner to change their address
  function set_owner_address(address payable _ownerAddress) public payable onlyCreator {
    creator = _ownerAddress;
  }

  // Method to allow owner to change the percentage of the bets that goes to the winner
  function set_winningAmountPercentage(uint _winPercent) public payable onlyCreator noBets {
    win_percentage = _winPercent;
  }

  // Method to fetch the random value from the beacon
  function fetch_random_value() public payable onlyCreator {
    if (oraclize_getPrice("URL") > address(this).balance)
    {
      emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
    }
    else
    {
      emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");

      // Querying the beacon for the random value
      oraclize_query("URL", "");
    }
  }

  // Method called by the owner to pick and pay the winner
  function draw() public payable onlyCreator nonZeroBalance {
    // Determining the winner and paying the winner a percentage of the current bets (rest are the contract owner's earnings)
    address payable winner = participants[random % number_participants];
    uint amount = bets * win_percentage / 100;
    uint ownerAmount = bets - amount;
    winner.transfer(amount);
    creator.transfer(ownerAmount);
    emit drew(winner, amount);

    // Resetting variables after draw is completed
    number_participants = 0;
    bets = 0;
    delete participants;
  }

  // Method to fetch the proof from the beacon
  function fetch_proof() public payable {
    if (oraclize_getPrice("URL") > address(this).balance)
    {
      emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
    }
    else
    {
      // Endpoint to obtain proof
      qID = oraclize_query("URL", "");

      emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
    }
  }

  // Method to verify the proof fetched from the beacon
  function verify() public payable returns (bool) {
    uint256 result;
    uint w = witness;
    uint ie = iter_exp;
    uint pr = prime;

    // Invoking the bigModExp precompile
    assembly {

      // The precompile needs the parameters as a contiguous byte array
      let p := mload(0x40)
      mstore(p, 0x20)
      mstore(add(p, 0x20), 0x20)
      mstore(add(p, 0x40), 0x20)
      mstore(add(p, 0x60), w)
      mstore(add(p, 0x80), ie)
      mstore(add(p, 0xa0), pr)

      // The bigModExp precompile resides at address 0x05. Invoking it with the given parameters.
      let success := call(sub(gas, 2000), 0x05, 0, p, 0xc0, p, 0x20)
      switch success case 0 {
        revert(0, 0)
      }

      result := mload(p)
    }

    // The witness after repeated modular squaring should be equal to the 'seed' value sent by the beacon for valid verification of proof
    if(result == seed)
      return true;

    return false;
  }

  // Oraclize callback method
  function __callback(bytes32 myid, string memory res) public {
    require(msg.sender == oraclize_cbAddress());
    if(myid == qID)
    {
      strings.slice memory s = res.toSlice();
      strings.slice memory delim = "-".toSlice();
      witness = parseInt(s.split(delim).toString());
      seed = parseInt(s.split(delim).toString());
      iter_exp = parseInt(s.split(delim).toString());
      prime = parseInt(s.split(delim).toString());
    }
    else
    {
      random = parseInt(res);
    }
  }
}
