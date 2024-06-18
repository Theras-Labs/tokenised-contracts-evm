// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/NFTOwnableUpgradeable.sol";
import "../utils/AllowedContracts.sol";

// try mint this nft,
// try list this NFT?
// setup supply on each ID ?
// checkin supply on id

// UPDATE SUPPLY ID
// UPDATE LOCK ID


// todo: cannot be upgraded for now, need another proxy
contract TRC1155 is
  Initializable,
  ERC1155Upgradeable,
  AllowedContracts,
  NFTOwnableUpgradeable,
  ERC1155PausableUpgradeable,
  ERC1155BurnableUpgradeable,
  ERC1155SupplyUpgradeable,
  UUPSUpgradeable
{
  // Track all minted token IDs
  mapping(uint256 => bool) private _tokenIds;
  uint256[] private _allTokenIds;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address initialOwner,
    uint256 tokenId,
    string memory uri,
    address shopAddress
  ) public initializer {
    __ERC1155_init(uri);
    __Ownable_init(initialOwner, tokenId);
    __ERC1155Pausable_init();
    __ERC1155Burnable_init();
    __ERC1155Supply_init();
    __UUPSUpgradeable_init();
    _addAllowedContract(shopAddress);
    //add operator => THERAS SHOP
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
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
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

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // update the uri? and supply for each id?

  function addAllowedContract(address contractAddress) public onlyOwner {
    _addAllowedContract(contractAddress);
  }

  function removeAllowedContract(address contractAddress) public onlyOwner {
    _removeAllowedContract(contractAddress);
  }

 function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function mintCollectibleId(
    address to,
    uint256 id,
    uint256 amount
  ) public onlyOperator {
    _mint(to, id, amount, "");
    _trackTokenId(id);
  }


  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyOwner {
    _mint(account, id, amount, data);
    _trackTokenId(id);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
    for (uint256 i = 0; i < ids.length; i++) {
      _trackTokenId(ids[i]);
    }
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  // The following functions are overrides required by Solidity.

  function _update(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory values
  )
    internal
    override(
      ERC1155Upgradeable,
      ERC1155PausableUpgradeable,
      ERC1155SupplyUpgradeable
    )
  {
    super._update(from, to, ids, values);
  }


  // Private function to track token IDs
  function _trackTokenId(uint256 id) private {
    if (!_tokenIds[id]) {
      _tokenIds[id] = true;
      _allTokenIds.push(id);
    }
  }

 // View function to get all balances for an address
    function balanceOfAll(address account) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256 count = _allTokenIds.length;

        uint256[] memory tokenIds = new uint256[](count);
        uint256[] memory balances = new uint256[](count);
        uint256[] memory supplies = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 id = _allTokenIds[i];
            tokenIds[i] = id;
            balances[i] = balanceOf(account, id);
            supplies[i] = totalSupply(id);
        }

        return (tokenIds, balances, supplies);
    }
}
