// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract NFTOwnableUpgradeable is ContextUpgradeable {
  struct OwnableStorage {
    address contractAddress;
    uint256 tokenId;
  }

  bytes32 private constant OwnableStorageLocation =
    keccak256("openzeppelin.storage.Ownable");

  function _getOwnableStorage()
    private
    pure
    returns (OwnableStorage storage ownableStorage)
  {
    bytes32 slot = OwnableStorageLocation;
    assembly {
      ownableStorage.slot := slot
    }
  }

  error OwnableUnauthorizedTokenOwner(address tokenOwner);

  function __Ownable_init(address contractAddr, uint256 tokenId)
    internal
    onlyInitializing
  {
    __Ownable_init_unchained(contractAddr, tokenId);
  }

  function __Ownable_init_unchained(address contractAddr, uint256 tokenId)
    internal
    onlyInitializing
  {
    require(contractAddr != address(0), "OwnableUpgradeable: Zero address");
    require(tokenId != 0, "OwnableUpgradeable: Zero token ID");

    OwnableStorage storage ownableStorage = _getOwnableStorage();
    ownableStorage.contractAddress = contractAddr;
    ownableStorage.tokenId = tokenId;
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return
      IERC721(_getOwnableStorage().contractAddress).ownerOf(
        _getOwnableStorage().tokenId
      );
  }

  function _checkOwner() internal view virtual {
    OwnableStorage storage ownableStorage = _getOwnableStorage();
    if (
      IERC721(ownableStorage.contractAddress).ownerOf(ownableStorage.tokenId) !=
      _msgSender()
    ) {
      revert OwnableUnauthorizedTokenOwner(_msgSender());
    }
  }

  // function renounceOwnership() public virtual onlyOwner {
  //     OwnableStorage storage ownableStorage = _getOwnableStorage();
  //     IERC721(ownableStorage.contractAddress).transferFrom(owner(), address(this), ownableStorage.tokenId);
  // }

  // function transferOwnership(address newOwner) public virtual onlyOwner {
  //     OwnableStorage storage ownableStorage = _getOwnableStorage();
  //     IERC721(ownableStorage.contractAddress).transferFrom(owner(), newOwner, ownableStorage.tokenId);
  // }
}
