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
  address public s_vendorAddress;

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
    // Ensure target contract is set
        require(s_vendorAddress != address(0), "Target contract not set");

        // Forward received Ether to target contract
        (bool success, ) = s_vendorAddress.call{value: msg.value}("");
        require(success, "Forwarding failed");

  }

    // Function to set the vendor  address
    function setVendorAddress(address _targetContract) external onlyOwner {
        s_vendorAddress = _targetContract;
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

  function mintCollectibleId(
    address to,
    uint256 tokenId,
    uint256 amount
  ) public onlyOperator {
    _mint(to, tokenId, amount, "");
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyOwner {
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
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
}
