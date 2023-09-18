pragma solidity >= 0.4.0 < 0.8.0;

contract P2PC {
    struct Prosumer {
        address id;
        int status;
        int balance;
    }

    mapping (address => Prosumer) private prosumers;
    address[] private buyers;
    address[] private sellers;

    //removes a specified id from the queue
    //returns true if id is present and removed from queue
    //otherwise queue remains unchanged and returns false
    function removeFromQueue(address id, address[] storage queue) private returns(bool) {
        bool found = false;
        for (uint i = 0; i < queue.length; i++) {
            if (queue[i] == id) {
                found = true;
                for (uint j = i; j < queue.length - 1; j++) {
                    queue[j] = queue[j+1];
                }
                break;
            }
        }

        if (found) {
            queue.pop();
        }

        return found;
    }

    function makeTrade(address buy_id, address sell_id) private {
        int amount = 0 - prosumers[buy_id].status;

        prosumers[buy_id].status = 0;
        prosumers[buy_id].balance -= amount;
        prosumers[sell_id].status -= amount;
        prosumers[sell_id].balance += amount;

        removeFromQueue(buy_id, buyers);
        if (prosumers[sell_id].status == 0) {
            removeFromQueue(sell_id, sellers);
        }
    }

    function sellEnergy(address sell_id) private {
        uint i = 0;
        //while loop needed as the content of buyers queue can change during the loop
        while ((i < buyers.length) && (prosumers[sell_id].status != 0)) {
            address buy_id = buyers[i];
            if (prosumers[sell_id].status + prosumers[buy_id].status >= 0) {
                makeTrade(buy_id, sell_id);
            } else {
                //Only increment i if no trade is made, otherwise buy_id has been removed from the queue
                i++;        
            }
        }

        if (prosumers[sell_id].status > 0) {
            sellers.push(sell_id);
        }
    }

    function buyEnergy(address buy_id) private {
        for (uint i = 0; i < sellers.length; i++) {
            address sell_id = sellers[i];
            if (prosumers[sell_id].status + prosumers[buy_id].status >= 0) {
                makeTrade(buy_id, sell_id);
                break;
            }
        }

        if (prosumers[buy_id].status < 0) {
            buyers.push(buy_id);
        }
    }

    function processRequest(address id) private {
        removeFromQueue(id, buyers);
        removeFromQueue(id, sellers);

        if (prosumers[id].status > 0) {
            sellEnergy(id);
        } else if (prosumers[id].status < 0) {
            buyEnergy(id);
        }
    }

    function addProsumer(address id) public {
        prosumers[id].id = id;
    }

    function updateStatus(address id, int amount) public {
        prosumers[id].status = amount;
        
        processRequest(id);
    }

    function updateBalance(address id, int amount) public {
        prosumers[id].balance += amount;
    }

    function getStatus(address id) public view returns(int) {
        return prosumers[id].status;
    }

    function getBalance(address id) public view returns(int) {
        return prosumers[id].balance;
    }

    function isRegistered(address id) public view returns(bool) {
        return prosumers[id].id == id;
    }
}


contract MainC {
    P2PC p2p;

    constructor (P2PC _p2p) public {
        p2p = _p2p;
    }
    
    modifier checkRegistered() {
        require(p2p.isRegistered(msg.sender) == true, "Not registered");
        _;
    }

    modifier checkNotRegistered() {
        require(p2p.isRegistered(msg.sender) == false, "Already registered");
        _;
    }

    modifier checkSufficientFunds(int amount) {
        require(p2p.getBalance(msg.sender) + amount >= 0, "Not enough funds");
        _;
    }

    modifier checkPositiveStatus() {
        require(p2p.getStatus(msg.sender) >= 0, "Withdrawal requires status >= 0");
        _;
    }

    function register() public checkNotRegistered {
        p2p.addProsumer(msg.sender);
    }

    function deposit() public payable checkRegistered {
        p2p.updateBalance(msg.sender, int(msg.value / 1 ether));
    }

    function withdraw() public checkRegistered checkPositiveStatus {
        int balance = p2p.getBalance(msg.sender);
        msg.sender.transfer(uint(balance * 1 ether));
        p2p.updateBalance(msg.sender, 0 - balance);
    }

    function requestEnergy(int amount) public checkRegistered checkSufficientFunds(amount) {
        p2p.updateStatus(msg.sender, amount);
    }

    function getStatus() public view checkRegistered returns(int) {
        return p2p.getStatus(msg.sender);
    }

    function getBalance() public view checkRegistered returns(int) {
        return p2p.getBalance(msg.sender);
    }
}