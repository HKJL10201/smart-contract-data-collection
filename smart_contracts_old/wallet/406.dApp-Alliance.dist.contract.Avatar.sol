pragma solidity ^0.4.25;

import "./Wallet.sol";

//-----------------------------------------------------------------------------------------------
contract Badge is _Info {
    address                     updater;
    mapping(address=>uint256)   status;

    constructor(bytes _msgPack) _Info(msg.sender,_msgPack) public {updater=msg.sender;}

    //-------------------------------------------------------
    // register assets
    //-------------------------------------------------------
    event ASSET(uint8 indexed _category, uint8 indexed _index, string _title, bytes _img);
    function asset(uint8 _category, uint8 _index, string _title, bytes _img) onlyHandler public {
        require(_index>0);
        emit ASSET(_category,_index,_title,_img);
    }

    //-------------------------------------------------------
    // update badge
    //-------------------------------------------------------
    function setUpdater(address _newUpdater) onlyHandler public {
        updater = _newUpdater;
    }
    function update(address _user, uint8 _newBadge) public {
        require(msg.sender==updater);
        status[_user] |= (1<<uint256(_newBadge-1));
    }
    function about(address _user) constant public returns(uint256) {
        return status[_user];
    }
}
//-----------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------
contract Avatar is _Info, _Store, SafeMath {
    address                     erc20;
    uint256                     price;
    uint256                     stamp;

    mapping(address=>uint256)   stamps;
    mapping(address=>uint256)   coupons;
    uint256                     totalSupply;

    constructor(address _erc20, uint256 _price, uint256 _stamp, bytes _msgPack) _Info(msg.sender,_msgPack) public {
        erc20   = _erc20;
        price   = _price;
        stamp   = _stamp;
    }

    function currency() public constant returns (address) {
        return erc20;
    }

    function update(uint256 _price, uint256 _stamp) onlyHandler public {
        price   = _price;
        stamp   = _stamp;
    }

    function about(address _user) constant public returns(uint256, uint256, uint256, uint256, uint256) {
        return (price, stamp, stamps[_user], coupons[_user], totalSupply);
    }

    //-------------------------------------------------------
    // register assets
    //-------------------------------------------------------
    uint256                     index;
    event ASSET(uint256 indexed _category, uint256 indexed _index, bytes _img);
    function asset(uint256 _category, bytes _img) onlyHandler public {
        emit ASSET(_category,index,_img);
        index   = safeAdd(index,1);
    }

    //-------------------------------------------------------
    // register setting
    //-------------------------------------------------------
    event SETTING(bytes _msgPack);
    function setting(bytes _msgPack) onlyHandler public {
        emit SETTING(_msgPack);
    }

    //-------------------------------------------------------
    // coupon
    //-------------------------------------------------------
    event COUPON(address indexed _to, address indexed _from, uint256 _count);
    function mint(address _who, uint256 _count) private {
        coupons[_who]   = safeAdd(coupons[_who],_count);
        totalSupply     = safeAdd(totalSupply,_count);
        emit COUPON(_who,address(0),_count);
    }
    function burn(address _who, uint256 _count) private {
        _count = min(_count,coupons[_who]);
        coupons[_who]   = safeSub(coupons[_who],_count);
        totalSupply     = safeSub(totalSupply,_count);
        emit COUPON(address(0),_who,_count);
    }
    function gift(address _who, uint256 _count) onlyHandler public {
        mint(_who,_count);
    }

    //-------------------------------------------------------
    // _Store
    //-------------------------------------------------------
    function checkIn(bool _in, bytes _msgPack) onlyHandler public {
        _Portal(_Root(root).portal()).checkIn(_in,_msgPack);
    }
    function voteFor() public constant returns (address) {
        return this;
    }
    function pay(uint256[2][] _items) payable public {
        revert();
    }
    function pay(bytes _msgPack) payable public {
        require(_Root(root).isEnable(this));
        uint256 _value = erc20==address(0)?msg.value:min(_ERC20Interface(erc20).allowance(msg.sender,this),_ERC20Interface(erc20).balanceOf(msg.sender));
        require(price==0||(_value>=price)||coupons[msg.sender]>0);

        if(price>0) {
            if(_value>=price) {
                if(stamp>0) {
                    stamps[msg.sender]  = safeAdd(stamps[msg.sender],1);
                    if(stamps[msg.sender]%stamp==0)
                        mint(msg.sender,1);
                }

                if(erc20==address(0))
                    _Root(root).handler(this).transfer(_value);
                else
                    _ERC20Interface(erc20).transferFrom(msg.sender,_Root(root).handler(this),_value);
            } else
                burn(msg.sender,1);
        }

        _Root(root).update(msg.sender, _msgPack);
    }
}
//-----------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------
contract Root is _Root, SafeMath {
    enum TYPE {ROOT,WALLET,AVATAR,BADGE}
    struct KeySet {
        address     _primary;
        address     _handler;
        uint        _until;
    }
    struct Member {
        TYPE        _type;
        uint256     _id;
        bool        _enable;
    }

    address                     _portal;

    uint256                     _index;
    mapping(uint256=>KeySet)    _id2KeySet;
    mapping(address=>uint256)   _key2id;
    mapping(address=>Member)    _members;

    uint256                     _wallets;
    uint256                     _badges;
    uint256                     _avatarStores;
    uint256                     _avatarTotal;
    uint256                     _avatarActive;
    mapping(address=>bool)      _avatarUsers;

    constructor(address _primaryKey) public {
        listup(_primaryKey,msg.sender);
        createMember(_primaryKey,this,TYPE.ROOT);
        _portal = new Portal();
    }

    mapping(address=>bool)      _used;
    //-------------------------------------------------------
    // ownership
    //-------------------------------------------------------
    modifier onlyPrimary() {
        require(msg.sender==_id2KeySet[1]._primary);
        _;
    }
    modifier onlyHandler() {
        require(msg.sender==_id2KeySet[1]._handler);
        _;
    }
    modifier onlyMember(address _member) {
        require(_members[_member]._id>0);
        _;
    }

    //-------------------------------------------------------
    //
    //-------------------------------------------------------
    event STATUS(address indexed _who, bool _state, bytes _msgPack);
    function enable(address _who, bool _enable, bytes _msgPack) onlyHandler onlyMember(_who) public {
        require(_members[_who]._enable!=_enable&&_members[_who]._type==TYPE.AVATAR);
        _members[_who]._enable   = _enable;
        emit STATUS(_who,_members[_who]._enable,_msgPack);
    }

    event WALLET(address indexed _who, uint256 indexed _to, uint256 indexed _from);
    event BADGE(address indexed _who, uint256 indexed _to, uint256 indexed _from);
    event AVATAR(address indexed _who, uint256 indexed _to, uint256 indexed _from);
    function emitEvent(address _who, uint256 _from) private {
        if(_members[_who]._type==TYPE.WALLET)       emit WALLET(_who,_members[_who]._id,_from);
        else if(_members[_who]._type==TYPE.BADGE)   emit BADGE(_who,_members[_who]._id,_from);
        else if(_members[_who]._type==TYPE.AVATAR)  emit AVATAR(_who,_members[_who]._id,_from);
    }
    function transfer(address _primaryKey, address _what) onlyMember(_what) public {
        require(_id2KeySet[_members[_what]._id]._handler==msg.sender&&_key2id[_primaryKey]>0);
        uint256 _from = _members[_what]._id;
        _members[_what]._id = _key2id[_primaryKey];
        emitEvent(_what,_from);
    }
    function resetHandler(address _newHandler) notSame(msg.sender,_newHandler) newKey(_newHandler) public {
        require(_key2id[msg.sender]>0);
        _id2KeySet[_key2id[msg.sender]] = KeySet(msg.sender,_newHandler,now+30 minutes);    // you can change primary key in 30 minutes
        _used[_newHandler]              = true;
    }
    function resetPrimary(address _oldPrimary, address _newPrimary) notSame(msg.sender,_newPrimary) newKey(_newPrimary) public {
        uint256 id = _key2id[_oldPrimary];
        require(id>0&&_id2KeySet[id]._handler==msg.sender&&_id2KeySet[id]._until>now);
        _id2KeySet[id]                  = KeySet(_newPrimary,msg.sender,0);
        _used[_newPrimary]              = true;
    }
    function id2Handler(uint256 _id) constant public returns (address) {
        return (_id2KeySet[_id]._handler);
    }
    function id2KeySet(uint256 _id) constant public returns (address,address) {
        return (_id2KeySet[_id]._primary,_id2KeySet[_id]._handler);
    }
    function key2id(address _primaryKey) constant public returns (uint256) {
        return (_key2id[_primaryKey]);
    }
    function member2id(address _member) constant public returns (uint256) {
        return _members[_member]._id;
    }
    function status(address _member) constant public returns (uint256,TYPE,bool) {
        return (_members[_member]._id,_members[_member]._type,_members[_member]._enable);
    }
    function about() constant public returns (uint256,uint256,uint256,uint256,uint256) {
        return (_wallets,_badges,_avatarStores,_avatarActive,_avatarTotal);
    }

    //-------------------------------------------------------
    // Portal
    //-------------------------------------------------------
    function portal() constant public returns (address) {
        return _portal;
    }

    //-------------------------------------------------------
    //
    //-------------------------------------------------------
    function handler(address _member) constant public returns (address) {
        return _id2KeySet[_members[_member]._id]._handler;
    }
    function isEnable(address _member) constant public returns (bool) {
        return _members[_member]._enable&&_id2KeySet[_members[_member]._id]._handler!=address(0);
    }

    modifier notSame(address _key0,address _key1) {
        require(_key0!=_key1);
        _;
    }
    modifier newKey(address _key) {
        require(!_used[_key]);
        _;
    }

    function listup(address _primaryKey, address _handlerKey) private {
        if(_key2id[_primaryKey]==0) {
            _index  = safeAdd(_index,1);
            _key2id[_primaryKey]    = _index;
            _id2KeySet[_index]      = KeySet(_primaryKey,_handlerKey,0);

            _used[_primaryKey]      = true;
            _used[_handlerKey]      = true;
        }
    }
    function createKeySet(address _primaryKey) notSame(_primaryKey,msg.sender) newKey(_primaryKey) newKey(msg.sender) public {
        require(_key2id[_primaryKey]==0);
        listup(_primaryKey,msg.sender);
    }

    //-------------------------------------------------------
    //
    //-------------------------------------------------------
    modifier canCreate(address _primaryKey) {
        require((_key2id[_primaryKey]==0&&!_used[_primaryKey]&&!_used[msg.sender])||(_key2id[_primaryKey]>0&&_id2KeySet[_key2id[_primaryKey]]._handler==msg.sender));
        _;
    }
    function createMember(address _primaryKey, address _temp, TYPE _type) private returns (address) {
        _members[_temp] = Member(_type,_key2id[_primaryKey],true);
        emitEvent(_temp,0);
        return _temp;
    }

    //-------------------------------------------------------
    // Wallet
    //-------------------------------------------------------
    function wallet(address _primaryKey, bytes _msgPack) notSame(_primaryKey,msg.sender) canCreate(_primaryKey) public {
        listup(_primaryKey,msg.sender);
        createMember(_primaryKey,new Wallet(_msgPack),TYPE.WALLET);
        _wallets    = safeAdd(_wallets,1);
    }
    function isWallet(address _who) constant public returns (bool) {
        return _members[_who]._type==TYPE.WALLET;
    }

    //-------------------------------------------------------
    // Badge
    //-------------------------------------------------------
    function badge(address _primaryKey, bytes _msgPack) notSame(_primaryKey,msg.sender) canCreate(_primaryKey) public {
        listup(_primaryKey,msg.sender);
        createMember(_primaryKey,new Badge(_msgPack),TYPE.BADGE);
        _badges    = safeAdd(_badges,1);
    }

    //-------------------------------------------------------
    // Avatar
    //-------------------------------------------------------
    event TOKEN(address indexed _who, address indexed _erc20);
    function avatar(address _primaryKey, address _erc20, uint256 _price, uint8 _stamp, bytes _msgPack) notSame(_primaryKey,msg.sender) canCreate(_primaryKey) public {
        listup(_primaryKey,msg.sender);
        emit TOKEN(createMember(_primaryKey,new Avatar(_erc20,_price,_stamp,_msgPack),TYPE.AVATAR),_erc20);
        _avatarStores    = safeAdd(_avatarStores,1);
    }
    function isAvatar(address _who) constant public returns (bool) {
        return _members[_who]._type==TYPE.AVATAR;
    }

    event USER (address indexed _user, address indexed _who, bytes _msgPack);
    function update(address _user, bytes _msgPack) public {
        require(isEnable(msg.sender)&&_members[msg.sender]._type==TYPE.AVATAR);
        emit USER(_user,msg.sender,_msgPack);
        _avatarTotal        = safeAdd(_avatarTotal,1);
        if(!_avatarUsers[_user]) {
            _avatarUsers[_user] = true;
            _avatarActive= safeAdd(_avatarActive,1);
        }
    }
}
//-----------------------------------------------------------------------------------------------
