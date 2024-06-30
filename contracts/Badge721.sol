// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-v4/proxy/ClonesUpgradeable.sol";

interface ITRC1155 {
  function initialize(
    address contractAddress,
    uint256 tokenId,
    string memory uri,
    address shopAddress

  ) external;
}

interface ITRC721 {
  function initialize(
    address contractAddress,
    uint256 tokenId,
    string memory uri,
    address shopAddress

  ) external;
}

interface IDynamicContract {
  function initialize(
    address contractAddress,
    uint256 tokenId,
    string memory uri
  ) external;
}

contract Badge721 is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721URIStorageUpgradeable,
  ERC721PausableUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  uint256 private _nextTokenId = 1; 
  address public s_masterContractTRC721;
  address public s_masterContractTRC1155;
  address public s_shopAddress;
  // address public s_vendorAddress;
  string private s_baseTokenURI; // Updated to state variablez
  using ClonesUpgradeable for address;

  enum ContractType {
    ERC20,
    ERC721,
    ERC1155,
    UNKNOWN
    //another type?
  }

  // todo: change into dynamic masterContract
  // struct MasterContracts {
  //     // address addressContract
  //     // name contractName
  //     // bool archived  // still working or not
  // }

  struct DetailSmartContract {
    string contractName;
    address addressContract;
    ContractType contractType;
    // uint contractTypeId;
  }

  // MasterContracts[] = public s_master
  mapping(uint256 => DetailSmartContract[]) public s_listContracts;
  mapping(uint256 => uint256) public s_listContractsLength;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address initialOwner, string memory baseTokenURI, address _shopAddress)
    public
    initializer
  {
    __ERC721_init("Theras BADGE", "BADGE");
    __ERC721Enumerable_init();
    __ERC721URIStorage_init();
    __ERC721Pausable_init();
    __Ownable_init(initialOwner);
    s_baseTokenURI = baseTokenURI;
    s_shopAddress = _shopAddress;


  }

  receive() external payable {
      // Delegate call to the implementation contract
      _delegate(_implementation());
  }

  function _implementation() internal view returns (address) {
      return _getImplementation();
  }
  function _getImplementation() internal view returns (address impl) {
      bytes32 slot = keccak256("eip1967.proxy.implementation");
      assembly {
          impl := sload(slot)
      }
  }

  function _delegate(address implementation) internal {
    assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
        calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
        let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

        // Copy the returned data.
        returndatacopy(0, 0, returndatasize())

        switch result
        // delegatecall returns 0 on error.
        case 0 { revert(0, returndatasize()) }
        default { return(0, returndatasize()) }
    }
}


  // Function to withdraw Ether from the contract
  function withdrawEther(uint256 amount) external onlyOwner {
    require(amount <= address(this).balance, "Insufficient Ether balance");
    payable(msg.sender).transfer(amount);
  }

  // Function to withdraw ERC20 tokens from the contract
  function withdrawToken(address tokenAddress, uint256 amount)
    external
    onlyOwner
  {
    IERC20 token = IERC20(tokenAddress);
    require(
      amount <= token.balanceOf(address(this)),
      "Insufficient token balance"
    );
    token.transfer(msg.sender, amount);
  }

  function getListContracts(uint256 tokenId) external view returns (DetailSmartContract[] memory) {
    return s_listContracts[tokenId];
  }

  function getListContractsLength(uint256 tokenId) external view returns (uint256) {
      return s_listContractsLength[tokenId];
  }


  // New setter function for base URI
  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    s_baseTokenURI = baseTokenURI;
  }
  function setShopAddress(address _shopAddress) external onlyOwner {
    s_shopAddress = _shopAddress;
  }

  function _baseURI() internal view override returns (string memory) {
    return s_baseTokenURI;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function updateMasterContract(address _newAddress, bool is721)
    public
    onlyOwner
  {
    if (is721) {
      s_masterContractTRC721 = _newAddress;
    } else {
      s_masterContractTRC1155 = _newAddress;
    }
  }

  // todo: add master contract dynamically
  // function addMasterContract(address _newAddress, bool is721) public onlyOwner {
  // }

  function mintOwner(    address to,
    string memory uri) external onlyOwner {
        uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  // onlyOperator?
  // will be executed by theras contract ?
  // mint 1155 or 721 here, using bytes here as it will dynamic?

  function createProject(
    address to,
    string memory uri,
    string memory contractName, // project name
    ContractType _contractType
  ) public {
    // isPaused?
    // using bytes?
    // NAME OF PROJECT ?

    uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);

    _listingProject(tokenId, uri, contractName, _contractType);
  }

  // add something here?
  function addProjectCollection(
    uint256 projectId,
    string memory uri,
    string memory contractName,
    ContractType _contractType
  ) public {
    _listingProject(projectId, uri, contractName, _contractType);
  }

  // function updateProjectCollection(
  //     uint256 _projectId,
  //     uint256 _indexProject
  // ) external {
  //     DetailSmartContract memory newDetail = DetailSmartContract({
  //         addressContract: clone,
  //         contractType: ContractType.ERC1155,
  //         contractName
  //     });
  //     s_listContracts[_projectId].[_indexProject] = newDetail;
  //     // emit UpdateProjectDetail
  // }

  // // shadow fnction with self implementation
  // function createProject(
  //     // address masterContract,
  // ) public {
  //     // check smart contract has NFTOwnableUpgradeable
  // check smart contract has Operator modifier
  // }


  // todo: add detail implementation contract address too
  // so the if there's update on master contract address then possibly the previous project have certain issue.
  function _listingProject(
    uint256 tokenId,
    string memory uri,
    string memory contractName,
    ContractType _contractType
  ) internal {
    if (_contractType == ContractType.ERC1155) {
      // todo: need to update into more dynamic array options
      address clone = ClonesUpgradeable.clone(s_masterContractTRC1155);

      // Initialize the clone
      ITRC1155(clone).initialize(address(this), tokenId, uri,
      s_shopAddress
      );

      // and then update  mapping s_listContracts and add the id  here
      DetailSmartContract memory newDetail = DetailSmartContract({
        addressContract: clone,
        contractType: ContractType.ERC1155,
        // contractTypeId: 2,
        contractName: contractName
      });

      s_listContracts[tokenId].push(newDetail);
      s_listContractsLength[tokenId]++;
    } else if (_contractType == ContractType.ERC721) {
      address clone = ClonesUpgradeable.clone(s_masterContractTRC1155);

      // Initialize the clone
      ITRC721(clone).initialize(address(this), tokenId, uri,
      s_shopAddress
      );

      // and then update  mapping s_listContracts and add the id  here
      DetailSmartContract memory newDetail = DetailSmartContract({
        addressContract: clone,
        contractType: ContractType.ERC721,
        // contractTypeId: 1,
        contractName: contractName
      });
      s_listContracts[tokenId].push(newDetail);
      s_listContractsLength[tokenId]++;
    } 
    else {
      // todo later
    }
    // emit events
  }

  // =======DEFAULT======
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  // The following functions are overrides required by Solidity.

  function _update(
    address to,
    uint256 tokenId,
    address auth
  )
    internal
    override(
      ERC721Upgradeable,
      ERC721EnumerableUpgradeable,
      ERC721PausableUpgradeable
    )
    returns (address)
  {
    return super._update(to, tokenId, auth);
  }

  function _increaseBalance(address account, uint128 value)
    internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
  {
    super._increaseBalance(account, value);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(
      ERC721Upgradeable,
      ERC721EnumerableUpgradeable,
      ERC721URIStorageUpgradeable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
