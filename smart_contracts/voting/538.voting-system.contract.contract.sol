// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.13;

struct VoteOption{
    string opt_title; 
    string opt_desc;
    int num_votes; // Number of votes recieved by the option
}

contract VotePool{
    
    string public title; // define the title of the pool 
    string public description; // define the description of the pool (
    bool public status; // define if the pool is open or close to new votes
    VoteOption[] public options; // opcoes
    uint public len_options;

    constructor(string memory new_title, string memory new_description) {
        title = new_title;
        description = new_description;
        status = true;
        len_options = 0;
    }
    function add_option(string memory new_opt_title, string memory new_opt_description) public{
        VoteOption memory new_option;
        new_option.opt_title = new_opt_title;
        new_option.opt_desc = new_opt_description;
        new_option.num_votes = 0;

        options.push(new_option);
        len_options = options.length; //atualiza a variavel com a quantidade de options
    }
    
    modifier opt_require(uint256 opt){
        require(opt < len_options); // verifica se a opção de voto existe 
        _;
    }

    modifier status_require(){
        require(status == true);
        _;
    }

    function vote(uint256 opt) public opt_require(opt) status_require{
       options[opt].num_votes ++;
    }

    function return_options() public view returns (VoteOption[] memory){
        VoteOption[] memory id = new VoteOption[](len_options);
        for (uint i = 0; i < len_options; i++) {
            VoteOption storage opt = options[i];
            id[i] = opt;
        }
        return id;
    }


    function changeStatus() public{ // Change the status of the voting pool
        if (status == false){
            status = true;
        }else{
            status = false;
        }
    }

    
}

contract VotingSystem{
    address[] public pool_list; //lista de endereços das pools 
    uint public len_pool_list; //tamanho da lista
    mapping (address => VotePool) public pools_map; //mapping do endereço para a variavel
    mapping (address => bool) public admins;


    constructor(){
        len_pool_list = 0;

        admins[0x5d84D451296908aFA110e6B37b64B1605658283f] = true;  //Danilo
        admins[0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad] = true;  //Roberta
        //admins[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;         //remix teste admins
    }

    modifier admin_require{
        require(admins[msg.sender] == true, "O usuario nao e um administrador."); //so admin pode criar pool
        _;
    }

    function change_admin_status(address new_admin) public admin_require{
        if(admins[new_admin] = true){
            admins[new_admin] = false;
        }else{
            admins[new_admin] = true;
        }
    }

    // FUNCTIONS OF CONTRACT FACTORY

    event pool_create_confirm(address pool_addr);

    /*
    Exemplo para chamada da funcao:
    titulo teste, desc teste, [['opt1name','desc1',0],['opt2','desc2',0]]  
    */
    function create_pool(string memory title, string memory description, VoteOption[] memory options) public admin_require{
        VotePool new_pool = new VotePool(title, description);

        for (uint256 i = 0; i < options.length; i++) {
            new_pool.add_option(options[i].opt_title, options[i].opt_desc);
        }

        pool_list.push(address(new_pool)); // adiciona o endereço do contrato na lista
        len_pool_list++;
        pools_map[address(new_pool)] = new_pool; // adicionar o map do endereço para a variavel do contrato

        emit pool_create_confirm(address(new_pool));
    }

    // require pool addr ta dentro do map
    function add_vote(address pool_addr, uint256 opt) public{
        pools_map[pool_addr].vote(opt);
    }

    event pool_status_updated();

    function change_pool_status(address pool_addr) public admin_require{
        pools_map[pool_addr].changeStatus();
        emit pool_status_updated(); // evento que indica que atualizou o status de algum pool
    }

    function return_pool(address pool_addr) public view returns(string memory, string memory, bool, VoteOption[] memory){
        VotePool rpool = VotePool(pools_map[pool_addr]);
        
        string memory rtitle = rpool.title();
        string memory rdesc = rpool.description();
        bool rstatus = rpool.status();
        
        VoteOption[] memory roptions = rpool.return_options();

        return(rtitle, rdesc, rstatus, roptions);
    }

}
