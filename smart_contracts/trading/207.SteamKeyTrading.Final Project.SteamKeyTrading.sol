pragma solidity >= 0.4.22;

contract SteamKeyTrading {
    bool validated1;
    bool validated2;
    address poster;

    string public gameWant;
    string public gameHave;
    mapping(string => string) trades;

    bool trader1In;
    bool trader2In;
    address trader1;
    bytes32 public keyHash1;
    address trader2;
    bytes32 public keyHash2;
    mapping (address => address) specificTrade;

    string public key1;
    string public key2;
    mapping (address => string) personKey;

    constructor() public {
        validated1 = false;
        validated2 = false;
    }

    event opposingKey(string k);

    function helper(string memory s) pure public returns(bytes32) {
        return (sha256(abi.encodePacked(s)));
    }

    function postTrade(string memory want, string memory have) public {
        poster = msg.sender;
        gameWant = want;
        gameHave = have;
        trades[gameWant] = have;
    }

    function preTrade(bytes32 keyHash) public {
        if(!trader1In) {
            trader1In = true;
            trader1 = msg.sender;
            keyHash1 = keyHash;
        }
        else if(!trader2In && trader1 != msg.sender) {
            trader2In = true;
            trader2 = msg.sender;
            keyHash2 = keyHash;
        }
        else
            require(false);

        specificTrade[trader1] = trader2;
        specificTrade[trader2] = trader1;
        require(trader1 == poster || trader2 == poster);
    }
    //scripted validation of the keys and their hashes through email to me
    //Once they receive confirmation that their key and the other person's key has
    //been validated, the code proceeds.

    //The two parties have to validate
    function confirm (bool validation) public {
        if (trader1 == msg.sender)
            validated1 = validation;
        else if (trader2 == msg.sender)
            validated2 = validation;
        else
        require(false);
    }

    //alternatively, you could send the keys to each party through the email so
    //they don't get posted in the smart contract to block someone from just peering
    //in and stealing keys. For now, I'm going to assume we don't have malicious users
    //of that variety for this version of the smart contract
    function trade(string memory key) public{
        require(validated1 && validated2);

        if (trader1 == msg.sender) {
            if (sha256(abi.encodePacked(key)) == keyHash1) {
                key1 = key;
            }
        }
        else if (trader2 == msg.sender) {
            if (sha256(abi.encodePacked(key)) == keyHash2) {
                key2 = key;
            }
        }
        else
            require(false);
    }

    function postKey() public {
        emit opposingKey(personKey[specificTrade[msg.sender]]);
    }

}
