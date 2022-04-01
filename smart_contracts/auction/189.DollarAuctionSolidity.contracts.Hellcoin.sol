pragma solidity ^0.4.17;

contract Hellhole {
    uint constant minimum_click_amount = 1 finney;
    uint constant last_n_payouts = 100;
    uint constant click_time_extension = 24 hours;

    struct Click {
        address sender;
        uint amount;
        bool paid;
    }

    Click[100] public payouts;
    uint public next_payout_pointer = 0;
    uint public end_time;
    uint public pot = 0;


    function Hellhole() public payable {
        end_time = now + click_time_extension;
        //Summon Moloch with a sacrifice of money
        pot += msg.value;
    }

    function click() public payable {
        require(now <= end_time);
        require(msg.value >= minimum_click_amount);

        end_time = now + click_time_extension;
        pot += msg.value;

        payouts[next_payout_pointer] = Click({
            sender: msg.sender,
            amount: msg.value,
            paid: false
        });
        next_payout_pointer = (next_payout_pointer + 1) % last_n_payouts;
    }

    function withdraw() public {
        require(now > end_time);
        uint lastSendersTotal = 0;
        uint senderAmount = 0;
        for(uint8 i = 0; i < last_n_payouts; i++){
            lastSendersTotal += payouts[i].amount;
            if(!payouts[i].paid && payouts[i].sender == msg.sender){
                senderAmount += payouts[i].amount;
                payouts[i].paid = true;
            }
        }
        uint winnings = pot * (senderAmount / lastSendersTotal);
        msg.sender.transfer(winnings);
    }
}
