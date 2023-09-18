pragma solidity ^0.4.10;

contract Lottery {
  struct Player {
    uint    number;
    string  name;
    address playerAddress;
    uint    entryTime;
  }

  struct Withdrawal {
    uint    lotteryId;
    uint    number;
    address playerAddress;
    uint    amount;
  }

  uint public                          lotteryId = 1;
  uint public                          entryFee = (1 ether) / 100;
  uint public                          rake = (1 ether) / 1000;
  uint public                          maxNumPlayers = 3;
  uint public                          numPlayers = 0;
	Player[3] public                     players;
	address private                      owner;
  mapping (uint => Withdrawal) private pendingWithdrawals; // key is lotteryId

  event NewLottery(uint lotteryId, uint maxNumPlayers, uint entryFee, uint timestamp);
  event EndLottery(uint lotteryId, uint number, address playerAddress, string name, uint winnings, uint timestamp);
	event NewPlayer(uint lotteryId, uint number, address playerAddress, string name, uint entryFee, uint timestamp);
  event NewWithdrawal(uint lotteryId, uint number, address playerAddress, uint amount, uint timestamp);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

	function Lottery() {
		owner = msg.sender;
	}

  // Public: fallback function returns ether.
  function() { throw; }

  // Public: Records the senders address if they sent the entry fee.
  function enter(string name) payable {
    if (msg.value != entryFee) { throw; }

    if (bytes(name).length > 20) { throw; }

    players[numPlayers] = Player(numPlayers + 1, name, msg.sender, now);
    NewPlayer(lotteryId, numPlayers + 1, msg.sender, name, entryFee, now);

    numPlayers += 1;

    if (numPlayers == maxNumPlayers) {
      // select a winner
      uint randomNumber = uint(addmod(0, now, maxNumPlayers - 1));
      Player winner = players[randomNumber];

      uint winnings = maxNumPlayers * entryFee - rake;

			// add a withdrawal for the winner
      pendingWithdrawals[lotteryId] = Withdrawal(lotteryId, winner.number, winner.playerAddress, winnings);

      EndLottery(lotteryId, winner.number, winner.playerAddress, winner.name, winnings, now);

      // reset lottery data
      //delete players;
      numPlayers = 0;
      lotteryId += 1;

      NewLottery(lotteryId, maxNumPlayers, entryFee, now);
    }
  }

  function getWithdrawal(uint _lotteryId) constant returns (uint, uint, address, uint) {
    Withdrawal withdrawal = pendingWithdrawals[_lotteryId];
    return (withdrawal.lotteryId, withdrawal.number, withdrawal.playerAddress, withdrawal.amount);
  }

  function withdraw(uint _lotteryId) returns (bool) {
    Withdrawal withdrawal = pendingWithdrawals[_lotteryId];
    uint amount = withdrawal.amount;

    if (amount > 0 && withdrawal.playerAddress == msg.sender) {
      // Remember to zero the pending refund before
      // sending to prevent re-entrancy attacks
      withdrawal.amount = 0;
      if (msg.sender.send(amount)) {
        NewWithdrawal(withdrawal.lotteryId, withdrawal.number, withdrawal.playerAddress, amount, now);
        return true;
      } else {
        withdrawal.amount = amount;
        return false;
      }
    }
  }

  function accessFunding(uint _amount) onlyOwner {
    owner.send(_amount);
  }

  function destroy() onlyOwner {
    selfdestruct(owner);
  }
}
