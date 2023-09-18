// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

//Interface de nuestro token ERC20
interface IERC20 {
    //Devuelve la cantidad de tokens en existencia
    function totalSupply() external view returns (uint256);

    //Devuelve la cantidad de tokens para una dirección indicada por parámetro
    function balanceOf(address _account) external view returns (uint256);

    //Devuelve el número de token que el spender podrá gastar en nombre del propietario (owner)
    function allowance(address _owner, address _spender) external view returns (uint256);

    //Devuelve un valor booleano resultado de la operación indicada
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    // Transferencia Disney
    function transferencia_loteria(address sender, address recipient, uint256 amount) external returns (bool);

    //Devuelve un valor booleano con el resultado de la operación de gasto
    function approve(address _spender, uint256 _amount) external returns (bool);

    //Devuelve un valor booleano con el resultado de la operación de paso de una cantidad de tokens usando el método allowance()
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);



    //Evento que se debe emitir cuando una cantidad de tokens pase de un origen a un destino
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Evento que se debe emitir cuando se establece una asignación con el mmétodo allowance()
    event Approval(address indexed owner, address indexed spender, uint256 value);
}// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

//Interface de nuestro token ERC20
interface IERC20 {
    //Devuelve la cantidad de tokens en existencia
    function totalSupply() external view returns (uint256);

    //Devuelve la cantidad de tokens para una dirección indicada por parámetro
    function balanceOf(address _account) external view returns (uint256);

    //Devuelve el número de token que el spender podrá gastar en nombre del propietario (owner)
    function allowance(address _owner, address _spender) external view returns (uint256);

    //Devuelve un valor booleano resultado de la operación indicada
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    // Transferencia Disney
    function transferencia_loteria(address sender, address recipient, uint256 amount) external returns (bool);

    //Devuelve un valor booleano con el resultado de la operación de gasto
    function approve(address _spender, uint256 _amount) external returns (bool);

    //Devuelve un valor booleano con el resultado de la operación de paso de una cantidad de tokens usando el método allowance()
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);



    //Evento que se debe emitir cuando una cantidad de tokens pase de un origen a un destino
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Evento que se debe emitir cuando se establece una asignación con el mmétodo allowance()
    event Approval(address indexed owner, address indexed spender, uint256 value);
}