pragma solidity ^0.5.7;

/// @title FullWalletByteCode
/// @dev A contract containing the FullWallet bytecode, for use in deployment.
contract FullWalletByteCode {
    /// @notice This is the raw bytecode of the full wallet. It is encoded here as a raw byte
    ///  array to support deployment with CREATE2, as Solidity's 'new' constructor system does
    ///  not support CREATE2 yet.
    ///
    ///  NOTE: Be sure to update this whenever the wallet bytecode changes!
    ///  Simply run `npm run build` and then copy the `"bytecode"`
    ///  portion from the `build/contracts/FullWallet.json` file to here,
    ///  then append 64x3 0's.
    bytes constant fullWalletBytecode = "60806040523480156200001157600080fd5b5";

    // bytes constant fullWalletBytecode = hex'60806040523480156200001157600080fd5b5060405162002b5b38038062002b5b833981810160405260608110156200003757600080fd5b50805160208201516040909201519091906200005e8383836001600160e01b036200006716565b5050506200033b565b60045474010000000000000000000000000000000000000000900460ff1615620000f257604080517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601f60248201527f6d757374206e6f7420616c726561647920626520696e697469616c697a656400604482015290519081900360640190fd5b6004805460ff60a01b1916740100000000000000000000000000000000000000001790556001600160a01b0383811690821614156200017d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252603981526020018062002af46039913960400191505060405180910390fd5b806001600160a01b0316826001600160a01b03161415620001ea576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252602e81526020018062002b2d602e913960400191505060405180910390fd5b6001600160a01b0383166200024b576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252602681526020018062002aac6026913960400191505060405180910390fd5b6001600160a01b038216620002ac576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252602281526020018062002ad26022913960400191505060405180910390fd5b600480546001600160a01b0319166001600160a01b03838116919091179091557401000000000000000000000000000000000000000060008181559185169081018252600160209081526040928390208590558251918252810184905281517fb39b5f240c7440b58c1c6cfd328b09ff9aa18b3c8ef4b829774e4f5bad039416929181900390910190a1505050565b612761806200034b6000396000f3fe60806040526004361061019c5760003560e01c806375857eba116100ec578063a3c89c4f1161008a578063ce2d4f9611610064578063ce2d4f96146109e1578063ef009e42146109f6578063f0b9e5ba14610a78578063ffa1ad7414610b085761019c565b8063a3c89c4f14610867578063bf4fb0c0146108e2578063c0ee0b8a1461091b5761019c565b80638bf78874116100c65780638bf78874146107635780639105d9c41461077857806391aeeedc1461078d578063a0a2daf0146108335761019c565b806375857eba146106d85780637ecebe00146106ed57806388fb06e7146107205761019c565b8063210d66f81161015957806349efe5ae1161013357806349efe5ae146105aa57806357e61e29146105dd578063710eb26c1461066e578063727b7acf1461069f5761019c565b8063210d66f81461048b5780632698c20c146104c757806343fc00b8146105675761019c565b806301ffc9a71461027757806308405166146102bf578063150b7a02146102f1578063158ef93e146103c25780631626ba7e146103d75780631cd61bad14610459575b34156101dd576040805133815234602082015281517f88a5966d370b9919b20f3e2c13ff65706f196a4e32cc2c12bf57088f88525874929181900390910190a15b361561027557600080356001600160e01b0319168152600360205260409020546001600160a01b031660018111610251576040805162461bcd60e51b815260206004820152601360248201527224b73b30b634b2103a3930b739b0b1ba34b7b760691b604482015290519081900360640190fd5b3660008037600080366000845afa3d6000803e808015610270573d6000f35b3d6000fd5b005b34801561028357600080fd5b506102ab6004803603602081101561029a57600080fd5b50356001600160e01b031916610b92565b604080519115158252519081900360200190f35b3480156102cb57600080fd5b506102d4610c4d565b604080516001600160e01b03199092168252519081900360200190f35b3480156102fd57600080fd5b506102d46004803603608081101561031457600080fd5b6001600160a01b03823581169260208101359091169160408201359190810190608081016060820135600160201b81111561034e57600080fd5b82018360208201111561036057600080fd5b803590602001918460018302840111600160201b8311171561038157600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929550610c58945050505050565b3480156103ce57600080fd5b506102ab610c68565b3480156103e357600080fd5b506102d4600480360360408110156103fa57600080fd5b81359190810190604081016020820135600160201b81111561041b57600080fd5b82018360208201111561042d57600080fd5b803590602001918460018302840111600160201b8311171561044e57600080fd5b509092509050610c78565b34801561046557600080fd5b5061046e610fe5565b604080516001600160f81b03199092168252519081900360200190f35b34801561049757600080fd5b506104b5600480360360208110156104ae57600080fd5b5035610fea565b60408051918252519081900360200190f35b3480156104d357600080fd5b5061027560048036036101208110156104eb57600080fd5b6040820190608083019060c0840135906001600160a01b0360e086013516908501856101208101610100820135600160201b81111561052957600080fd5b82018360208201111561053b57600080fd5b803590602001918460018302840111600160201b8311171561055c57600080fd5b509092509050610ffc565b34801561057357600080fd5b506102756004803603606081101561058a57600080fd5b506001600160a01b03813581169160208101359160409091013516611499565b3480156105b657600080fd5b50610275600480360360208110156105cd57600080fd5b50356001600160a01b03166116af565b3480156105e957600080fd5b506102756004803603608081101561060057600080fd5b60ff8235169160208101359160408201359190810190608081016060820135600160201b81111561063057600080fd5b82018360208201111561064257600080fd5b803590602001918460018302840111600160201b8311171561066357600080fd5b5090925090506117c1565b34801561067a57600080fd5b50610683611a3e565b604080516001600160a01b039092168252519081900360200190f35b3480156106ab57600080fd5b50610275600480360360408110156106c257600080fd5b506001600160a01b038135169060200135611a4d565b3480156106e457600080fd5b506104b5611c02565b3480156106f957600080fd5b506104b56004803603602081101561071057600080fd5b50356001600160a01b0316611c0a565b34801561072c57600080fd5b506102756004803603604081101561074357600080fd5b5080356001600160e01b03191690602001356001600160a01b0316611c1c565b34801561076f57600080fd5b506104b5611ce2565b34801561078457600080fd5b50610683611ce8565b34801561079957600080fd5b50610275600480360360c08110156107b057600080fd5b60ff823516916020810135916040820135916060810135916001600160a01b03608083013516919081019060c0810160a0820135600160201b8111156107f557600080fd5b82018360208201111561080757600080fd5b803590602001918460018302840111600160201b8311171561082857600080fd5b509092509050611ced565b34801561083f57600080fd5b506106836004803603602081101561085657600080fd5b50356001600160e01b03191661202c565b34801561087357600080fd5b506102756004803603602081101561088a57600080fd5b810190602081018135600160201b8111156108a457600080fd5b8201836020820111156108b657600080fd5b803590602001918460018302840111600160201b831117156108d757600080fd5b509092509050612047565b3480156108ee57600080fd5b506102756004803603604081101561090557600080fd5b506001600160a01b0381351690602001356120f7565b34801561092757600080fd5b506102756004803603606081101561093e57600080fd5b6001600160a01b0382351691602081013591810190606081016040820135600160201b81111561096d57600080fd5b82018360208201111561097f57600080fd5b803590602001918460018302840111600160201b831117156109a057600080fd5b91908080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525092955061229a945050505050565b3480156109ed57600080fd5b5061046e61229f565b348015610a0257600080fd5b5061027560048036036040811015610a1957600080fd5b81359190810190604081016020820135600160201b811115610a3a57600080fd5b820183602082011115610a4c57600080fd5b803590602001918460208302840111600160201b83111715610a6d57600080fd5b5090925090506122a7565b348015610a8457600080fd5b506102d460048036036060811015610a9b57600080fd5b6001600160a01b0382351691602081013591810190606081016040820135600160201b811115610aca57600080fd5b820183602082011115610adc57600080fd5b803590602001918460018302840111600160201b83111715610afd57600080fd5b5090925090506123ab565b348015610b1457600080fd5b50610b1d6123bb565b6040805160208082528351818301528351919283929083019185019080838360005b83811015610b57578181015183820152602001610b3f565b50505050905090810190601f168015610b845780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b60006001600160e01b031982166301ffc9a760e01b1480610bc357506001600160e01b03198216630a85bd0160e11b145b80610bde57506001600160e01b0319821663785cf2dd60e11b145b80610bf957506001600160e01b0319821663607705c560e11b145b80610c1457506001600160e01b03198216630b135d3f60e11b145b15610c2157506001610c48565b506001600160e01b031981166000908152600360205260409020546001600160a01b031615155b919050565b63607705c560e11b81565b630a85bd0160e11b949350505050565b600454600160a01b900460ff1681565b60408051601960f81b6020808301919091526000602183018190523060601b602284015260368084018890528451808503909101815260569093019093528151910120610cc36125b0565b610ccb6125b0565b610cd36125b0565b6000806041881415610da457610d2960008a8a8080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929392505063ffffffff6123dc169050565b60ff908116865290865281875284518651604080516000815260208181018084528d9052939094168482015260608401949094526080830152915160019260a0808401939192601f1981019281900390910190855afa158015610d90573d6000803e3d6000fd5b505050602060405103519150819050610f48565b6082881415610f3857610df760008a8a8080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929392505063ffffffff6123dc169050565b60ff16855285528552604080516020601f8b01819004810282018101909252898152610e4a91604191908c908c9081908401838280828437600092019190915250929392505063ffffffff6123dc169050565b60ff908116602087810191909152878101929092528188019290925284518751875160408051600081528086018083528d9052939095168386015260608301919091526080820152915160019260a08082019392601f1981019281900390910190855afa158015610ebf573d6000803e3d6000fd5b505060408051601f19808201516020808901518b8201518b830151600087528387018089528f905260ff909216868801526060860152608085015293519096506001945060a08084019493928201928290030190855afa158015610f27573d6000803e3d6000fd5b505050602060405103519050610f48565b5060009550610fde945050505050565b6001600160a01b038216610f66575060009550610fde945050505050565b6001600160a01b038116610f84575060009550610fde945050505050565b806001600160a01b031660016000846001600160a01b0316600054018152602001908152602001600020546001600160a01b031614610fcd575060009550610fde945050505050565b50630b135d3f60e11b955050505050505b9392505050565b600081565b60016020526000908152604090205481565b601b60ff88351614806110135750601c60ff883516145b611064576040805162461bcd60e51b815260206004820152601e60248201527f696e76616c6964207369676e61747572652076657273696f6e20765b305d0000604482015290519081900360640190fd5b601b60ff60208901351614806110815750601c60ff602089013516145b6110d2576040805162461bcd60e51b815260206004820152601e60248201527f696e76616c6964207369676e61747572652076657273696f6e20765b315d0000604482015290519081900360640190fd5b604051601960f81b6020820181815260006021840181905230606081811b6022870152603686018a905288901b6bffffffffffffffffffffffff1916605686015290938492899189918991899190606a018383808284378083019250505097505050505050505060405160208183030381529060405280519060200120905060006001828a60006002811061116357fe5b602002013560ff168a60006002811061117857fe5b604080516000815260208181018084529690965260ff90941684820152908402919091013560608301528a3560808301525160a08083019392601f198301929081900390910190855afa1580156111d3573d6000803e3d6000fd5b505060408051601f1980820151600080845260208085018087528990528f81013560ff16858701528e81013560608601528d81013560808601529451919650945060019360a0808501949193830192918290030190855afa15801561123c573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b0382166112a4576040805162461bcd60e51b815260206004820152601d60248201527f496e76616c6964207369676e617475726520666f72207369676e65722e000000604482015290519081900360640190fd5b6001600160a01b0381166112ff576040805162461bcd60e51b815260206004820152601f60248201527f496e76616c6964207369676e617475726520666f7220636f7369676e65722e00604482015290519081900360640190fd5b856001600160a01b0316826001600160a01b03161461134f5760405162461bcd60e51b815260040180806020018281038252602281526020018061270b6022913960400191505060405180910390fd5b6001600160a01b03821660009081526002602052604090205487146113a55760405162461bcd60e51b81526004018080602001828103825260218152602001806126bc6021913960400191505060405180910390fd5b600080546001600160a01b038085169182018352600160205260409092205491821614806113e45750816001600160a01b0316816001600160a01b0316145b61142e576040805162461bcd60e51b815260206004820152601660248201527524b73b30b634b21030baba3437b934bd30ba34b7b71760511b604482015290519081900360640190fd5b6001600160a01b038316600090815260026020908152604091829020805460010190558151601f880182900482028101820190925286825261148c91869189908990819084018382808284376000920191909152506123f892505050565b5050505050505050505050565b600454600160a01b900460ff16156114f8576040805162461bcd60e51b815260206004820152601f60248201527f6d757374206e6f7420616c726561647920626520696e697469616c697a656400604482015290519081900360640190fd5b6004805460ff60a01b1916600160a01b1790556001600160a01b0383811690821614156115565760405162461bcd60e51b81526004018080602001828103825260398152602001806126836039913960400191505060405180910390fd5b806001600160a01b0316826001600160a01b031614156115a75760405162461bcd60e51b815260040180806020018281038252602e8152602001806126dd602e913960400191505060405180910390fd5b6001600160a01b0383166115ec5760405162461bcd60e51b815260040180806020018281038252602681526020018061263b6026913960400191505060405180910390fd5b6001600160a01b0382166116315760405162461bcd60e51b81526004018080602001828103825260228152602001806126616022913960400191505060405180910390fd5b600480546001600160a01b0319166001600160a01b0383811691909117909155600160a01b60008181559185169081018252600160209081526040928390208590558251918252810184905281517fb39b5f240c7440b58c1c6cfd328b09ff9aa18b3c8ef4b829774e4f5bad039416929181900390910190a1505050565b333014611703576040805162461bcd60e51b815260206004820152601e60248201527f6d7573742062652063616c6c65642066726f6d2060696e766f6b652829600000604482015290519081900360640190fd5b600080546001600160a01b0383811690910182526001602052604090912054161561175f5760405162461bcd60e51b81526004018080602001828103825260398152602001806125cf6039913960400191505060405180910390fd5b600480546001600160a01b038381166001600160a01b0319831617928390556040805192821680845293909116602083015280517f568ab3dedd6121f0385e007e641e74e1f49d0fa69cab2957b0b07c4c7de5abb69281900390910190a15050565b8460ff16601b14806117d657508460ff16601c145b611827576040805162461bcd60e51b815260206004820152601a60248201527f496e76616c6964207369676e61747572652076657273696f6e2e000000000000604482015290519081900360640190fd5b336000818152600260209081526040808320549051601960f81b9281018381526021820185905230606081811b60228501526036840185905287901b6056840152929585939287928a918a9190606a0183838082843780830192505050975050505050505050604051602081830303815290604052805190602001209050600060018289898960405160008152602001604052604051808581526020018460ff1660ff1681526020018381526020018281526020019450505050506020604051602081039080840390855afa158015611904573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116611961576040805162461bcd60e51b815260206004820152601260248201527124b73b30b634b21039b4b3b730ba3ab9329760711b604482015290519081900360640190fd5b6000805433018152600160205260409020546001600160a01b03818116908316148061199557506001600160a01b03811633145b6119df576040805162461bcd60e51b815260206004820152601660248201527524b73b30b634b21030baba3437b934bd30ba34b7b71760511b604482015290519081900360640190fd5b336000908152600260209081526040918290206001870190558151601f8801829004820281018201909252868252611a3391859189908990819084018382808284376000920191909152506123f892505050565b505050505050505050565b6004546001600160a01b031681565b6004546001600160a01b03163314611aac576040805162461bcd60e51b815260206004820152601f60248201527f73656e646572206d757374206265207265636f76657279206164647265737300604482015290519081900360640190fd5b6001600160a01b038216611af15760405162461bcd60e51b815260040180806020018281038252602681526020018061263b6026913960400191505060405180910390fd5b6004546001600160a01b0383811691161415611b3e5760405162461bcd60e51b81526004018080602001828103825260398152602001806126836039913960400191505060405180910390fd5b6001600160a01b038116611b99576040805162461bcd60e51b815260206004820152601e60248201527f54686520636f7369676e6572206d757374206e6f74206265207a65726f2e0000604482015290519081900360640190fd5b60008054600160a01b81810183556001600160a01b038516918201018252600160209081526040928390208490558251918252810183905281517fa9364fb2836862098c2b593d2d3f46759b4c6d5b054300f96172b0394430008a929181900390910190a15050565b600160a01b81565b60026020526000908152604090205481565b333014611c70576040805162461bcd60e51b815260206004820152601e60248201527f6d7573742062652063616c6c65642066726f6d2060696e766f6b652829600000604482015290519081900360640190fd5b6001600160e01b0319821660008181526003602090815260409182902080546001600160a01b0319166001600160a01b03861690811790915582519384529083015280517fd09b01a1a877e1a97b048725e0697d9be07bb94320c536e72b976c81016891fb9281900390910190a15050565b60005481565b600181565b8660ff16601b1480611d0257508660ff16601c145b611d53576040805162461bcd60e51b815260206004820152601a60248201527f496e76616c6964207369676e61747572652076657273696f6e2e000000000000604482015290519081900360640190fd5b604051601960f81b6020820181815260006021840181905230606081811b6022870152603686018a905288901b6bffffffffffffffffffffffff1916605686015290938492899189918991899190606a018383808284378083019250505097505050505050505060405160208183030381529060405280519060200120905060006001828a8a8a60405160008152602001604052604051808581526020018460ff1660ff1681526020018381526020018281526020019450505050506020604051602081039080840390855afa158015611e31573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116611e8e576040805162461bcd60e51b815260206004820152601260248201527124b73b30b634b21039b4b3b730ba3ab9329760711b604482015290519081900360640190fd5b6001600160a01b0381166000908152600260205260409020548614611ef3576040805162461bcd60e51b81526020600482015260166024820152756d7573742075736520636f7272656374206e6f6e636560501b604482015290519081900360640190fd5b846001600160a01b0316816001600160a01b031614611f435760405162461bcd60e51b815260040180806020018281038252602281526020018061270b6022913960400191505060405180910390fd5b600080546001600160a01b03808416918201835260016020526040909220549182161480611f7957506001600160a01b03811633145b611fc3576040805162461bcd60e51b815260206004820152601660248201527524b73b30b634b21030baba3437b934bd30ba34b7b71760511b604482015290519081900360640190fd5b6001600160a01b03821660009081526002602090815260409182902060018a0190558151601f870182900482028101820190925285825261202091859188908890819084018382808284376000920191909152506123f892505050565b50505050505050505050565b6003602052600090815260409020546001600160a01b031681565b6000805433908101825260016020526040909120546001600160a01b0316146120b0576040805162461bcd60e51b815260206004820152601660248201527524b73b30b634b21030baba3437b934bd30ba34b7b71760511b604482015290519081900360640190fd5b6120f36000801b83838080601f0160208091040260200160405190810160405280939291908181526020018383808284376000920191909152506123f892505050565b5050565b33301461214b576040805162461bcd60e51b815260206004820152601e60248201527f6d7573742062652063616c6c65642066726f6d2060696e766f6b652829600000604482015290519081900360640190fd5b6001600160a01b0382166121905760405162461bcd60e51b815260040180806020018281038252602681526020018061263b6026913960400191505060405180910390fd5b6004546001600160a01b03838116911614156121dd5760405162461bcd60e51b81526004018080602001828103825260398152602001806126836039913960400191505060405180910390fd5b6001600160a01b038116158061220157506004546001600160a01b03828116911614155b61223c5760405162461bcd60e51b815260040180806020018281038252602e8152602001806126dd602e913960400191505060405180910390fd5b600080546001600160a01b0384169081018252600160209081526040928390208490558251918252810183905281517fb39b5f240c7440b58c1c6cfd328b09ff9aa18b3c8ef4b829774e4f5bad039416929181900390910190a15050565b505050565b601960f81b81565b6000831180156122ba575063ffffffff83105b61230b576040805162461bcd60e51b815260206004820152601760248201527f496e76616c69642076657273696f6e206e756d6265722e000000000000000000604482015290519081900360640190fd5b60005460a084901b9081106123515760405162461bcd60e51b81526004018080602001828103825260338152602001806126086033913960400191505060405180910390fd5b60005b828110156123a4576001600085858481811061236c57fe5b905060200201356001600160a01b03166001600160a01b03168401815260200190815260200160002060009055806001019050612354565b5050505050565b63785cf2dd60e11b949350505050565b604051806040016040528060058152602001640312e312e360dc1b81525081565b0160208101516040820151606090920151909260009190911a90565b60008060606040518060400160405280601481526020017311185d1848199a595b19081d1bdbc81cda1bdc9d60621b815250905060606040518060400160405280600b81526020016a10d85b1b0819985a5b195960aa1b815250905060558551101582906124e45760405162461bcd60e51b81526004018080602001828103825283818151815260200191508051906020019080838360005b838110156124a9578181015183820152602001612491565b50505050905090810190601f1680156124d65780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b5060208501805160001a865182016001830192505b808310156125645760348301516054840181018281111561251c57865160208801fd5b60008083605488016014890151895160601c5af161255457836001811461254a578960020a89179850612552565b865160208801fd5b505b60018901985080945050506124f9565b5050604080518881526020810186905280820187905290517f101214446435ebbb29893f3348e3aae5ea070b63037a3df346d09d3396a34aee92509081900360600190a1505050505050565b6040518060400160405280600290602082028038833950919291505056fe446f206e6f742075736520616e20617574686f72697a6564206164647265737320617320746865207265636f7665727920616464726573732e596f752063616e206f6e6c79207265636f766572206761732066726f6d2065787069726564206175746856657273696f6e732e417574686f72697a656420616464726573736573206d757374206e6f74206265207a65726f2e496e697469616c20636f7369676e6572206d757374206e6f74206265207a65726f2e446f206e6f742075736520746865207265636f76657279206164647265737320617320616e20617574686f72697a656420616464726573732e6d7573742075736520636f7272656374206e6f6e636520666f72207369676e6572446f206e6f742075736520746865207265636f766572792061646472657373206173206120636f7369676e65722e617574686f72697a656420616464726573736573206d75737420626520657175616ca265627a7a723058203e27aaf42e5acdb44185fc5c91f25ca2c3ac6ab9c16f3e90a8832e6a750e865164736f6c634300050a0032417574686f72697a656420616464726573736573206d757374206e6f74206265207a65726f2e496e697469616c20636f7369676e6572206d757374206e6f74206265207a65726f2e446f206e6f742075736520746865207265636f76657279206164647265737320617320616e20617574686f72697a656420616464726573732e446f206e6f742075736520746865207265636f766572792061646472657373206173206120636f7369676e65722e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';

}
