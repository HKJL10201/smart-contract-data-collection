
/*
   this contract is responsible for 

 */

pragma solidity >=0.4.21 <0.7.0;

import "./Deal.sol";

contract Store {
    uint public value;

    struct Product {
        // [2021-2-7] uid 在系统中设置不可以为0
        uint uid;
        string name;
        string imageLink;
        uint perPrice;
        uint expirationTime;
        uint amount;
        string origin;
        address payable owner;
        uint productType;
        // 如果是加工产品，在这个mapping里面需要将涉及到的原料的相应交易以及用了多少原料记录下来
        // [2021-2-7] 如果是转手材料，也视作原材料为产品本身
        // 最多十种原料
        address payable [10] materialDeal;
        uint[10] materialAmount;
    }

    // todo:
    // 链上后期不再返回溯源链条明文，而是将其存储在链条下的数据库中，链条上存储溯源链路的hash值
    // [2021-2-7] 暂时不考虑todo的内容
    // string PlaceHash;

    // [2021-1-30]索引=> uid
    uint[] productUidList;
    // [2021-1-30]uid=> product
    mapping (uint => Product) productList;
    // [2021-1-30]每种商品被卖掉还剩多少，用于验证该商品是否还有库存可以卖
    // [2021-1-30]uid=> amount
    mapping (uint => uint) productRemainAmount;
    // [2021-1-30]uid=> downstream
    // mapping (uint => address payable []) productDownStreamList;
    // [2021-1-30]uid=> upstream
    mapping (uint => address payable []) productUpStreamList;

    address payable[] envolvedMemberList;
    //    mapping (address => mapping (uint => address[])) memberProductList;
    // 每个参与者每种产品手头有多少，仅仅用于验证这个人有没有足够的原材料
    // [2021-1-30] member => (uid => amount)
    mapping (address => mapping (uint => uint)) memberProductList;


    // 每个消费者对应的交易集合，用于验证这个订单交易属于这个消费者
    mapping (address => address payable []) currentDealList;

    constructor() public {}

    modifier notOdd() {
        value = (msg.value / 2);
        require (
            value * 2 == msg.value,
            "value has to be even"
        );
        _;
    }

    /*
    ========================================================================
    开始合约事件
    ========================================================================
     */

  

    // 添加商品成功时候返回商品信息存储进数据库中
    event ProductInfo(
        uint _productId,
        string _name,
        string _imageLink,
        uint _perPrice,
        uint _expirationTime,
        uint _amount,
        string _origin,
        address payable _owner,
        uint _productType,
        address payable [10] _materialDeal,
        uint[10] _materialAmount
    );

    // 添加商品失败
    event AddProductFail(
        uint _productId,
        string _name,
        string _error
    );


    // 搜索商品信息失败事件
    event SearchProductFail(
        uint _productId
    );


    // [2021-1-30] 查询交易事件, 希望不要达到solidity 函数调用的参数限制
    // [2021-2-4] 为了让代码简洁，避免每次改变状态的时候都调用DealInfo，仅仅在发起的时候调用
    event DealInfo(
        address payable _dealAddress,
        uint _productId,
        address payable _seller,
        address payable _buyer,
        uint _price,
        uint _amount,
        string _fromWhere,
        string _toWhere,
        uint _dealLaunchTime,
        uint _dealPayTime,
        uint _dealFinishedTime,
        // 这里为了节约空间，使用数字来代表交易的状态
        uint _state
    );

    // 发起交易事件
    event LaunchDealFail(
        string _message
    );

    // 交易终止事件
    event AbortDealResult(
        address payable _dealAddress,
        string _message,
        bool result
    );

    // 支付事件
    event PayDealResult(
        address payable _dealAddress,
        string _message,
        bool result
    );

    // 收货事件
    event FinishDealResult(
        address payable _dealAddress,
        string _message,
        bool result
    );
    
    
    event AllProductId(
        uint[] _productIdList
        );
 


    /*
    ========================================================================
    开始合约函数
    ========================================================================
     */

    // 添加新的商品
    function addNewProduct(
        uint _uid,
        string memory _name,
        string memory _imageLink,
        string memory _origin,
        uint _expirationTime,
        uint _amount,
        uint _perPrice,
        uint _productType,
        address payable [10] memory _materialDeal,
        uint[10] memory _materialAmount
    )
    public notOdd payable returns (bool){
        // [2021-1-29]价格不对，抬走
        // [2021-2-4] 这里的_amount * _perPrice 的结果是以人民币作为单位的，因此，需要乘100000000000000
        // [2021-2-4]	10000 CNY	=	1    eth	= 1000000000000000000 Wei
        // [2021-2-4]	1 CNY		=	0.0001 eth	= 100000000000000 Wei
        if (_amount * _perPrice * 2 * 100000000000000 != msg.value) {
            emit AddProductFail(
                _uid,
                _name,
                "price error"
            );

            // [2021-2-4]然后需要把钱还给人家
            msg.sender.transfer(msg.value);
            return false;
        }
        Product memory product = Product(
            _uid,
            _name,
            _imageLink,
            _perPrice,
            _expirationTime,
            _amount,
            _origin,
            msg.sender,
            _productType,
            _materialDeal,
            _materialAmount
        );

        // 验证一：已经买卖过的商品不允许上架，即便是经手买卖，也需要更改id才可以上架
        for(uint i=0;i<productUidList.length;i++){
            if(productUidList[i] == product.uid){
                emit AddProductFail(
                    product.uid,
                    product.name,
                    "product has been dealed"
                );
                // [2021-2-4]然后需要把钱还给人家
                msg.sender.transfer(msg.value);
                return false;
            }
        }

        // 看这个商品的所有人是否是新来的
        uint flag = 0;
        for(uint i=0;i<envolvedMemberList.length;i++){
            if(envolvedMemberList[i] == msg.sender){
                flag = 1;
                break;
            }
        }

        // 验证二：如果有配料表，持有者需要有足够的原料
        for(uint i=0;i<product.materialDeal.length;i++){
            // 配料表的终结
            if (product.materialAmount[i] == 0)break;

            // 新来的人不可能有原料在名下，返回false
            if(flag == 0){
                emit AddProductFail(
                    product.uid,
                    product.name,
                    "illegal material"
                );

                // [2021-2-4]然后需要把钱还给人家
                msg.sender.transfer(msg.value);
                return false;
            }
            if (memberProductList[msg.sender][Deal(product.materialDeal[i]).uidInfo()] < product.materialAmount[i]){
                emit AddProductFail(
                    product.uid,
                    product.name,
                    "no enough material"
                );
                // [2021-2-4]然后需要把钱还给人家
                return false;
            }
        }


        // 验证通过之后
        // 首先扣除原料，然后添加商品
        for(uint i=0;i<product.materialDeal.length;i++){
            if(product.materialAmount[i] == 0)break;
            memberProductList[msg.sender][Deal(product.materialDeal[i]).uidInfo()] -= product.materialAmount[i];
        }

        // 添加商品索引
        productUidList.push(product.uid);
        // 添加商品
        productList[product.uid] = product;
        // 添加商品的上游交易
        productUpStreamList[product.uid] = product.materialDeal;
        // 添加商品剩余量
        productRemainAmount[product.uid] = product.amount;


        // 如果是新来的，就添加这个所有人
        if(flag == 0){
            envolvedMemberList.push(msg.sender);
        }
        // 将商品添加到这个人的商品列表中
        // [2021-2-7] 一个人的商品持有列表只可能在自己的商品被人买走和自己买别人商品的时候会改变,记住，这个列表仅仅用于验证商家是否有足够的原料上架加工商品或者转手商品
        if(memberProductList[msg.sender][product.uid] > 0){
            memberProductList[msg.sender][product.uid] += product.amount;
        }else{
            memberProductList[msg.sender][product.uid] = product.amount;
        }

        // 到此为止，添加成功，发送添加商品成功的事件
        emit ProductInfo(
            product.uid,
            product.name,
            product.imageLink,
            product.perPrice,
            product.expirationTime,
            product.amount,
            product.origin,
            product.owner,
            product.productType,
            product.materialDeal,
            product.materialAmount
        );
        
       
        return true;
    }

    // 购买者发起交易，但是还没有付钱
    function launchDeal(
        uint _uid, // 买啥
        uint _amount, // 买多少
        string memory _toWhere, // 送哪里
        uint _dealLaunchTime // 交易发起的时间
    ) public returns (bool){

        // [2021-1-30] 需要验证要买的这个东西是存在的且量是足够的，否则要发送失败事件
        uint productExist = 0;
        for(uint i=0;i<productUidList.length;i++){
            if(_uid == productUidList[i]){
                if(_amount > productRemainAmount[_uid]){
                    emit LaunchDealFail(
                        "No enough product!"
                    );
                    return false;
                }
                productRemainAmount[_uid] = productRemainAmount[_uid] - _amount;
                productExist = 1;
                break;
            }
        }
        // [2021-1-30]商品不存在，发送错误事件
        if (productExist == 0){
            emit LaunchDealFail(
                "Porduct not exits!"
            );
            return false;
        }

        // [2021-1-29]允许交易用户存在未完成交易，不过也不能要购物车，需要确保，每一笔交易都只有一种商品参与，这是为了方便溯源
        Product memory product = productList[_uid];
        Deal deal = new Deal(
            product.uid,
            product.owner,
            msg.sender,
            product.perPrice * _amount,
            product.origin,
            _toWhere,
            _amount,
            _dealLaunchTime
        );

        // 添加到用户的当前交易中
        currentDealList[msg.sender].push(payable(address(deal)));

        // 这里不用deal.xxx() 是因为某几个参数类型是string但是函数会返回string memory。
        // emit DealInfo(
        // payable(address(deal)),
        // product.uid,
        // product.owner,
        // msg.sender,
        // product.perPrice * _amount,
        // _amount,
        // product.origin,
        // _toWhere,
        // _dealLaunchTime,
        // 0,
        // 0,
        // 0
        // )

        emit DealInfo(
            payable(address(deal)),
            deal.uidInfo(),
            deal.sellerInfo(),
            deal.buyerInfo(),
            deal.priceInfo(),
            deal.amountInfo(),
            deal.fromWhereInfo(),
            deal.toWhereInfo(),
            deal.dealLaunchTimeInfo(),
            deal.dealPayTimeInfo(),
            deal.dealFinishedTimeInfo(),
            0
        );
        return true;
    }

    // [2021-1-29] 中断交易功能，可以在交易发起、锁定这两个状态的时候执行
    function abortDeal(address payable _dealAddress) public payable returns (bool){
        // [2021-1-29] 检查这个交易是否属于消息这个用户
        uint flag=0;
        for(uint i=0;i< currentDealList[msg.sender].length; i++) {
            if (_dealAddress == currentDealList[msg.sender][i]){
                flag = 1;
                break;
            }
        }
        if (flag == 0) {
            // [2021-1-29] 这个交易不属于这个消费者，发送报错事件
            emit AbortDealResult(
                _dealAddress,
                "this deal is not belong to you",
                false
            );
            return false;
        }

        uint result = Deal(_dealAddress).abortDeal(msg.sender);

        // 已经受到货物了不可以终止交易
        if (result == 2){
            emit AbortDealResult(
                _dealAddress,
                "you can not abort the deal!",
                false
            );
            return false;
        }
        // 不是购买者调用这个合约
        if (result == 3){
            emit AbortDealResult(
                _dealAddress,
                "only buyer can call this!",
                false
            );
            return false;
        }
        if (result == 1){
            // 如果是付过钱的就把钱退回去
            // [2021-1-29] 保证金也要退还给消费者
            msg.sender.transfer(Deal(_dealAddress).priceInfo() * 2 * 100000000000000 );
        }

        // [2021-1-30] 成功终止交易，需要把该交易的商品量恢复到列表中去
        // 修改UTXO在完成订单之后
        // productRemainAmount[Deal(_dealAddress).uidInfo()] = productRemainAmount[Deal(_dealAddress).uidInfo()] + Deal(_dealAddress).amountInfo();

        emit AbortDealResult(
            _dealAddress,
            "Abort deal successful!",
            true
        );


        // [2021-2-4] 明明只需要上面的那个事件就可以让后台更新状态了
        // [2021-1-30]发送交易状态，更新数据库
        // Deal deal = Deal(_dealAddress);
        // emit DealInfo(
        // payable(address(deal)),
        // deal.uidInfo(),
        // deal.sellerInfo(),
        // deal.buyerInfo(),
        // deal.priceInfo(),
        // deal.amountInfo(),
        // deal.fromWhereInfo(),
        // deal.toWhereInfo(),
        // deal.dealLaunchTimeInfo(),
        // deal.dealPayTimeInfo(),
        // deal.dealFinishedTimeInfo(),
        // 3
        // );
        return true;
    }

    // 当购买者确认付款后触发函数
    function purchaseConfirm(uint _dealPayTime, address payable _dealAddress) public payable notOdd returns(bool) {
        // 没有交易可以付款
        for(uint i=0;i<currentDealList[msg.sender].length;i++) {
            if(_dealAddress == currentDealList[msg.sender][i]){
                Deal deal = Deal(_dealAddress);
                uint price = deal.priceInfo();
                // 付款金额错误，需要付保证金的
                // [2021-2-4] 单位转化成人民币
                if (msg.value != price * 2 * 100000000000000 ) {
                    emit PayDealResult(
                        _dealAddress,
                        "The amount of payment is incorrect!",
                        false
                    );
                    msg.sender.transfer(msg.value);
                    return false;

                }
                // 将交易状态错误和方法调用者错误两种错误统一处理
                if (deal.getPayment(msg.sender, _dealPayTime) != 0){
                    emit PayDealResult(
                        _dealAddress,
                        "You can not pay for this deal!",
                        false
                    );
                    msg.sender.transfer(msg.value);
                    return false;
                }
                // 成功付款
                emit PayDealResult(
                    _dealAddress,
                    "Purchase successful!",
                    true
                );

                // [2021-2-4] 同理，这里也不需要调用DealInfo事件
                // emit DealInfo(
                // payable(address(deal)),
                // deal.uidInfo(),
                // deal.sellerInfo(),
                // deal.buyerInfo(),
                // deal.priceInfo(),
                // deal.amountInfo(),
                // deal.fromWhereInfo(),
                // deal.toWhereInfo(),
                // deal.dealLaunchTimeInfo(),
                // deal.dealPayTimeInfo(),
                // deal.dealFinishedTimeInfo(),
                // 1
                // );

                return true;
            }
        }
        // 没有交易可以让消息发送者付款
        emit PayDealResult(
            _dealAddress,
            "There is no deal you can pay for!",
            false
        );
        return false;
    }

    // 买家收到货物点击确认收货按钮时候的操作
    function receivedConfirm(uint _receivedTime, address payable _dealAddress) public returns (bool){
        // 如果不是消费者的交易
        for (uint i=0;i<currentDealList[msg.sender].length;i++){
            if(_dealAddress == currentDealList[msg.sender][i]){

                Deal deal = Deal(_dealAddress);
                uint result = deal.finishConfirm(msg.sender, _receivedTime);

                // 如果交易的状态非法
                if(result == 1){
                // require(1==2, 'end point 3');
                    emit FinishDealResult(
                        _dealAddress,
                        "the state of the product is illegal!",
                        false
                    );
                    return false;
                }

                // 如果消息调用者不是买家
                // require(1==2, 'end point 4');
                if(result == 2){
                // require(1==2, 'end point 5');
                    emit FinishDealResult(
                        _dealAddress,
                        "This method can only be called by buyer!",
                        false
                    );
                    return false;
                }
                // require(1==2, 'end point 6');

                // 发送确认收货事件
                emit FinishDealResult(
                    _dealAddress,
                    "Receive confirm!",
                    true
                );


                //给卖家钱和保证金
                // [2021-2-4] 注意单位转化成人民币
                address payable seller = Deal(_dealAddress).sellerInfo();
                seller.transfer(Deal(_dealAddress).priceInfo() * 3 * 100000000000000 );
                // 给买家返还保证金
                // [2021-2-4] 注意单位转化成人民币
                address payable buyer = Deal(_dealAddress).buyerInfo();
                buyer.transfer(Deal(_dealAddress).priceInfo() * 100000000000000 );
                // require(1==2, 'end point 8');

                // [2021-2-7] 更新持有者持有列表,卖家那里要扣掉，买家这里要加上
                memberProductList[msg.sender][Deal(_dealAddress).uidInfo()] += Deal(_dealAddress).amountInfo();
                memberProductList[Deal(_dealAddress).sellerInfo()][Deal(_dealAddress).uidInfo()] -= Deal(_dealAddress).amountInfo();

                // 在参与人员中添加买家地址
                uint flag = 0;
                for(uint j=0;j<envolvedMemberList.length;j++) {
                    if (msg.sender == envolvedMemberList[j]) {
                        flag = 1;
                        break;
                    }
                }
                if ( flag == 0 ) envolvedMemberList.push(msg.sender);
                
               

                // 更新该产品下游交易记录
                // 暂时取消该功能
                // productDownStreamList[Deal(_dealAddress).uidInfo()].push(_dealAddress);

                // [2021-2-4] 这里也不需要调用DealInfo事件就可以完成状态更新
                // Deal deal = Deal(_dealAddress);
                // emit DealInfo(
                // payable(address(deal)),
                // deal.uidInfo(),
                // deal.sellerInfo(),
                // deal.buyerInfo(),
                // deal.priceInfo(),
                // deal.amountInfo(),
                // deal.fromWhereInfo(),
                // deal.toWhereInfo(),
                // deal.dealLaunchTimeInfo(),
                // deal.dealPayTimeInfo(),
                // deal.dealFinishedTimeInfo(),
                // 2
                // );


                return true;
            }
        }

        // 找不到交易，发送收货失败事件
        emit FinishDealResult(
            _dealAddress,
            "There is no deal you can confirm",
            false
        );
        return false;

    }

    // 以下是信息展示函数
    // 查询商品信息
    // [2021-2-2] 理论上来说，应该不需要这个函数，因为每次添加商品后商品信息都存储在了数据库中，应该不需要调用合约来查询
    function productInfo(uint _productId) public returns(bool) {
        Product memory product = productList[_productId];
        if (product.uid == 0){
            emit SearchProductFail(
                _productId
            );
            return false;
        }
        emit ProductInfo(
            product.uid,
            product.name,
            product.imageLink,
            product.perPrice,
            product.expirationTime,
            product.amount,
            product.origin,
            product.owner,
            product.productType,
            product.materialDeal,
            product.materialAmount
        );
        return true;
    }
    
    
    function getAllProductId() public returns(bool){
        emit AllProductId(productUidList);
        return true;
    }
    
    

    // [2021-2-2] 前端在查询的时候首先向后端发送请求，如果后端在数据库中找到交易信息的话就直接显示，如果找不到交易信息的话就向合约查询，查询到的结果在回显之后存进数据库供下一次查询。那么，下面这个函数显得没有必要了，因为后端知道deal的合约地址之后就可以直接实例化deal然后去调用deal的getter来查询一些信息，不用和store交互
    // function dealInfo(address payable _dealAddress) public returns(bool) {
    // Deal deal = Deal(_dealAddress);
    // // [2021-1-30] 怎么处理查询不到交易的情况？

    // emit DealInfo(
    // payable(address(deal)),
    // deal.uidInfo(),
    // deal.sellerInfo(),
    // deal.buyerInfo(),
    // deal.priceInfo(),
    // deal.amountInfo(),
    // deal.fromWhereInfo(),
    // deal.toWhereInfo(),
    // deal.dealLaunchTimeInfo(),
    // deal.dealPayTimeInfo(),
    // deal.dealFinishedTimeInfo(),
    // deal.stateInfo()
    // );

    // return true;

    // }
}


