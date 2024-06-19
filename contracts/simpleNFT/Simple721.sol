// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Simple721 is
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  ERC721Pausable,
  Ownable,
  ERC721Burnable
{
  uint256 private _nextTokenId;
  uint256 public maxSupply;
  string public _baseTokenURI;

  constructor(
    address initialOwner,
    uint256 _maxSupply,
    string memory initialBaseURI,
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) Ownable(initialOwner) {
    maxSupply = _maxSupply;
    _baseTokenURI = initialBaseURI;
  }

  receive() external payable {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
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

  //

  function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
    require(
      newMaxSupply >= _nextTokenId,
      "New max supply cannot be less than the current supply"
    );
    maxSupply = newMaxSupply;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function safeMint(address to, string memory uri) public onlyOwner {
    require(_nextTokenId < maxSupply, "Max supply reached");
    uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  function safeMint(address to) public onlyOwner {
    require(_nextTokenId < maxSupply, "Max supply reached");
    uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
  }

  function safeMintBatch(address to, uint256 quantity) public onlyOwner {
    require(quantity > 0, "Quantity must be greater than 0");
    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = _nextTokenId++;
      _safeMint(to, tokenId);
    }
  }

  function mint(address to) public onlyOwner {
    require(_nextTokenId < maxSupply, "Max supply reached");
    uint256 tokenId = _nextTokenId++;
    _mint(to, tokenId);
  }

  // The following functions are overrides required by Solidity.

  function _update(
    address to,
    uint256 tokenId,
    address auth
  )
    internal
    override(ERC721, ERC721Enumerable, ERC721Pausable)
    returns (address)
  {
    return super._update(to, tokenId, auth);
  }

  function _increaseBalance(address account, uint128 value)
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._increaseBalance(account, value);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, ERC721URIStorage)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
