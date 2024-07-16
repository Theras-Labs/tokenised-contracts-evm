// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract SimpleERC1155 is
  ERC1155,
  Ownable,
  ERC1155Pausable,
  ERC1155Burnable,
  ERC1155Supply
{
  // Track all minted token IDs
  mapping(uint256 => bool) private _tokenIds;
  uint256[] private _allTokenIds;

  constructor(address initialOwner) ERC1155("TEST_TRC") Ownable(initialOwner) {}

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  receive() external payable {
    // Delegate call to the implementation contract
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
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

  function mintCollectibleId(
    address to,
    uint256 tokenId,
    uint256 amount
  ) public {
    _mint(to, tokenId, amount, "");
    // _trackTokenId(id);
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

  // The following functions are overrides required by Solidity.

  function _update(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory values
  ) internal override(ERC1155, ERC1155Pausable, ERC1155Supply) {
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
  function balanceOfAll(address account)
    public
    view
    returns (
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
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
