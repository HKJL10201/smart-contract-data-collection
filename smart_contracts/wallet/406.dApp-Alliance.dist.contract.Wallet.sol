pragma solidity ^0.4.25;

//-----------------------------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract _ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}
//-----------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------
contract _Root {
    function id2Handler(uint256 _id) constant public returns (address);
    function id2KeySet(uint256 _id) constant public returns (address,address);
    function key2id(address _primaryKey) constant public returns (uint256);
    function member2id(address _member) constant public returns (uint256);
    function portal() constant public returns (address);
    function handler(address _member) constant public returns (address);
    function isEnable(address _who) constant public returns (bool);
    function isWallet(address _who) constant public returns (bool);
    function isAvatar(address _who) constant public returns (bool);
    function update(address _user, bytes _msgPack) public;
}
contract _Portal {
    function checkIn(bool _in, bytes _msgPack) public;
    function isMember(address _contract) constant public returns (bool);
    function getPoint(address _contract) public;
    function givePoint(address _contract, bool _up, uint256 _point) public;
}
contract _Store {
    function () public payable {revert();}  // Don't accept ETH
    function currency() public constant returns (address);
    function checkIn(bool _in, bytes _msgPack) public;
    function voteFor() public constant returns (address);
    function pay(uint256[2][] _items) payable public;
    function pay(bytes _msgPack) payable public;

    function min(uint _a, uint _b) internal pure returns (uint256) {
        return _a>_b?_b:_a;
    }
}
//-----------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------
contract Portal is _Portal, SafeMath {
    struct _member {
        bool                        enable;
        uint256                     up;
        uint256                     down;
        mapping(address=>uint256)   points;
    }

    address internal                root;
    mapping(address=>_member)       members;

    constructor() public {root=msg.sender;}

    function checkIn(bool _in, bytes _msgPack) public {
        require(members[msg.sender].enable!=_in);
        members[msg.sender].enable = _in;
        emit INFO(msg.sender,_in,_msgPack);
    }
    event INFO(address indexed _member, bool indexed _state, bytes _msgPack);
    function info(bytes _msgPack) public {
        require(members[msg.sender].enable);
        emit INFO(msg.sender,members[msg.sender].enable,_msgPack);
    }
    function isMember(address _contract) constant public returns (bool) {
        return (members[_contract].enable);
    }

    function about(address _contract) constant public returns (bool,uint256,uint256,uint256) {
        return (members[_contract].enable,
                members[_contract].up,
                members[_contract].down,
                members[_contract].points[msg.sender]);
    }

    //-------------------------------------------------------
    // vote interface
    //-------------------------------------------------------
    modifier onlyWallet() {
        require(_Root(root).isWallet(msg.sender));
        _;
    }

    function getPoint(address _contract) onlyWallet public {
        members[_contract].points[msg.sender] = safeAdd(members[_contract].points[msg.sender],1);
    }
    function givePoint(address _contract, bool _up, uint256 _point) onlyWallet public {
        require(members[_contract].points[msg.sender]>=_point&&_point>0);

        members[_contract].points[msg.sender] -= _point;

        if(_up)
            members[_contract].up   = safeAdd(members[_contract].up,_point);
        else
            members[_contract].down = safeAdd(members[_contract].down,_point);
    }
}
//-----------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------
contract _Info {
    address internal                root;

    constructor(address _root, bytes _msgPack) public {
        root     = _root;
        emit INFO(_msgPack);
    }

    modifier onlyHandler() {
        require(msg.sender==_Root(root).handler(this));
        _;
    }

    event INFO(bytes _msgPack);
    function info(bytes _msgPack) onlyHandler public {
        emit INFO(_msgPack);
    }
}
//-----------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------
contract Wallet is _Info {

    constructor(bytes _msgPack) _Info(msg.sender,_msgPack) public {}
    function () public payable {}

    //-------------------------------------------------------
    // erc20 interface
    //-------------------------------------------------------
    function balanceOf(address _erc20) public constant returns (uint balance) {
        if(_erc20==address(0))
            return address(this).balance;
        return _ERC20Interface(_erc20).balanceOf(this);
    }
    function transfer(address _erc20, address _to, uint _tokens) onlyHandler public returns (bool success) {
        require(balanceOf(_erc20)>=_tokens);
        if(_erc20==address(0))
            _to.transfer(_tokens);
        else
            return _ERC20Interface(_erc20).transfer(_to,_tokens);
        return true;
    }
    function approve(address _erc20, address _spender, uint _tokens) onlyHandler public returns (bool success) {
        require(_erc20 != address(0)&&balanceOf(_erc20)>=_tokens);
        return _ERC20Interface(_erc20).approve(_spender,_tokens);
    }

    //-------------------------------------------------------
    // pay interface
    //-------------------------------------------------------
    function _pay(address _store, uint _tokens) private {
        address erc20   = _Store(_store).currency();

        if(_Portal(_Root(root).portal()).isMember(_store)&&_tokens>0)
            _Portal(_Root(root).portal()).getPoint(_store);

        if(erc20 == address(0))
            transfer(erc20,_store,_tokens);
        else
            _ERC20Interface(erc20).approve(_store,_tokens);
    }
    function pay(address _store, uint _tokens, uint256[2][] _items) onlyHandler public {
        _pay(_store,_tokens);
        _Store(_store).pay(_items);
    }
    function pay(address _store, uint _tokens, bytes _msgPack) onlyHandler public {
        _pay(_store,_tokens);
        _Store(_store).pay(_msgPack);
    }
    //-------------------------------------------------------
    // vote interface
    //-------------------------------------------------------
    function vote(address _store, bool _up, uint256 _point) onlyHandler public {
        require(_Portal(_Root(root).portal()).isMember(_Store(_store).voteFor()));
        _Portal(_Root(root).portal()).givePoint(_Store(_store).voteFor(), _up, _point);
    }
}
//-----------------------------------------------------------------------------------------------
