pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

import "./src/SafeMath.sol";

//leandro 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//mari 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
//meli 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c

interface IERC20 {

    //  devuelve la cantidad de token en existencia
    function totalSupply() external view returns (uint256);
    //  devuelve la cantidad de tokens para una direccion indicada por parametro
    function balanceOf(address tokenOwner) external view returns (uint256);
    //  devuelve el numero de token que el spender podra gastar en nombre del propietario(owbner)
    function allowance(address owner, address delegate) external view returns (uint256);
    //  devuelve un valor boolean dependiendo si se puede o no realizar una transferencia
    function transfer(address recipient, uint256 tokensNumber) external returns (bool);
    //  devuelve bool con el resultado de la operacion de gaste
    function approve(address delegate, uint256 tokensNumber) external returns (bool);
    //  devuelve bool con el resultado de la operacion usando el metodo allowance
    function transferFrom(address owner, address recipient, uint256 tokensNumber) external returns (bool);

    function transferLottery(address recipient, address emisor, uint256 tokensNumber) external returns (bool);

    //  evento que se emite cuando una cantidad de tokens pase de un prigen a otro
    event Transfer(address indexed from, address indexed to, uint256 value);
    //  evento que se emite cuando se establece una asignacion con el metodo allawance
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Basic is IERC20 {

    using SafeMath for uint256;

    string public constant name = "ERC20Blockchain";
    string public constant symbol = "PijaDeMono";
    uint8 public constant decimals = 2;
    mapping(address => uint) balanceMapping;
    mapping(address => mapping(address => uint)) allowedMapping;
    uint256 totalSupply_;

    constructor (uint256 initialSupply) public {
        totalSupply_ = initialSupply;
        balanceMapping[msg.sender] = totalSupply_;
    }

    function increaseTotalSupply(uint newTokensAmount) public {
        totalSupply_ += newTokensAmount;
        balanceMapping[msg.sender] += newTokensAmount;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balanceMapping[tokenOwner];
    }

    function transfer(address recipient, uint256 tokensNumber) public override returns (bool) {
        require(tokensNumber <= balanceMapping[msg.sender]);
        balanceMapping[msg.sender] = balanceMapping[msg.sender].sub(tokensNumber);
        balanceMapping[recipient] = balanceMapping[recipient].add(tokensNumber);
        emit Transfer(msg.sender, recipient, tokensNumber);
        return true;
    }

    /*
    El cliente paga la atracin en token
            Ha sido necesario crear una funcion en ERC20.sol con el nombre de "transferLottery".
            debido a que en caso de usar el transfer o transferFrom las direcciones que escojian para realizar la
            transferencia eran equivocados, Ya que el msg,sender que reciba el metodo trtansfer o
            transferFrom era la direccion del contrato
            */
    function transferLottery(address recipient, address emisor, uint256 tokensNumber) public override returns (bool) {
        require(tokensNumber <= balanceMapping[msg.sender]);
        balanceMapping[msg.sender] = balanceMapping[msg.sender].sub(tokensNumber);
        balanceMapping[recipient] = balanceMapping[recipient].add(tokensNumber);
        emit Transfer(msg.sender, recipient, tokensNumber);
        return true;
    }

    function transferFrom(address owner, address recipient, uint256 tokensNumber) public override returns (bool) {
        require(tokensNumber <= balanceMapping[owner]);
        require(tokensNumber <= allowedMapping[owner][msg.sender]);

        balanceMapping[owner] = balanceMapping[owner].sub(tokensNumber);
        allowedMapping[owner][msg.sender] = allowedMapping[owner][msg.sender].sub(tokensNumber);
        balanceMapping[recipient] = balanceMapping[recipient].add(tokensNumber);
        emit Transfer(owner, recipient, tokensNumber);
        return true;
    }

}