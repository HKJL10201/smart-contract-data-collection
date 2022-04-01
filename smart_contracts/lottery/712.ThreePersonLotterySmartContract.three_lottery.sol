pragma solidity ^0.4.21;

contract three_lottery
{
    uint num_participants;
    address[] participants;
    bool complete;
    uint256 buy_in;
    address[] blacklist;
    address[] valid_participants;
    uint total;
    uint num_revealed;
    uint256 deadline;

    mapping(address => bytes32) picks;
    mapping(address => bool) revealed;

    event won(address _winner);

    modifier didnt_reveal_pick()
    {
        require(revealed[msg.sender] == false);
        _;
    }

    modifier paid()
    {
      require(msg.value >= buy_in * 7);
      _;
    }

    modifier not_over()
    {
        require(!complete);
        _;
    }

    modifier open_spots()
    {
      require((num_participants >= 0) && (num_participants < 3));
      _;
    }

    modifier no_open_spots()
    {
      require(num_participants == 3);
      _;
    }

    modifier past_deadline()
    {
      require(now >= deadline || num_revealed == 3);
      _;
    }

    function sha(uint _nonce, uint _pick)
    public
    pure
    returns (bytes32)
    {
        return sha256(_nonce, _pick);
    }

    function ()
    {
      revert();
    }

    function three_lottery()
    public
    {
        num_participants = 0;
        complete = false;
        buy_in = 1;
        total = 0;
        num_revealed = 0;
    }

    function enter_lottery(bytes32 _hash_of_pick)
    public
    payable
    open_spots
    paid
    not_over
    {
      picks[msg.sender] = _hash_of_pick;
      num_participants = num_participants + 1;
      participants.push(msg.sender);

      if (num_participants == 1)
      {
        buy_in = msg.value / 7;
      }
      else if (msg.value > buy_in * 7)
      {
        msg.sender.transfer(msg.value - (buy_in * 7));
      }

      if (num_participants == 3)
      {
          deadline = now + 7 days;
      }
    }

    function reveal_pick(uint _nonce, uint _pick)
    public
    didnt_reveal_pick
    no_open_spots
    {
        bytes32 hash_of_pick = sha256(_nonce, _pick);

        if (hash_of_pick == picks[msg.sender])
        {
            if (_pick < 0 || _pick > 2)
            {
                blacklist.push(msg.sender);
                num_revealed += 1;
            }
            else
            {
              total += _pick;
              revealed[msg.sender] = true;
              valid_participants.push(msg.sender);
              num_revealed += 1;
              msg.sender.transfer(buy_in * 6);
            }
        }
    }

    function end_lottery()
    public
    no_open_spots
    past_deadline
    not_over
    {
        address contract_address = this;
        uint winner_index;

        complete = true;

        if (valid_participants.length == 0)
        {
            participants[0].transfer(buy_in * 7);
            participants[1].transfer(buy_in * 7);
            participants[2].transfer(buy_in * 7);
        }
        else if (valid_participants.length == 1)
        {
            valid_participants[0].transfer(contract_address.balance);

            emit won(valid_participants[0]);
        }
        else if (valid_participants.length == 2)
        {
            winner_index = total % 2;
            valid_participants[0].transfer(buy_in * 3);
            valid_participants[1].transfer(buy_in * 3);
            valid_participants[winner_index].transfer(contract_address.balance);

            emit won(valid_participants[winner_index]);
        }
        else
        {
            winner_index = total % 3;
            valid_participants[winner_index].transfer(contract_address.balance);

            emit won(valid_participants[winner_index]);
        }
    }

}
