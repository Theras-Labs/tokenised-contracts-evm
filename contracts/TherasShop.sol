// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IUniversalClaim {
  function mintToken(address to, uint256 amount) external; // respective to erc20

  function mintCollectible(address to) external; // respective to erc721

  function mintCollectibleId(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external; // respective to erc1155
}

contract TherasShop is
  Initializable,
  PausableUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  struct Ticket {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
  enum TokenType {
    ERC20,
    ERC721,
    ERC1155
  }
  address private offchainSigner;
  uint256 public therasFee; // Therashop fee as a fraction of 1000 (e.g., 100 for 10%)

  // address public s_vendorAddress;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address initialOwner,
    uint256 _fee,
    address _offchainSigner
  ) public initializer {
    __Pausable_init();
    __Ownable_init(initialOwner);
    __UUPSUpgradeable_init();
    therasFee = _fee;
    offchainSigner = _offchainSigner;
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

  function setupTherasFee(uint256 _fee) public onlyOwner {
    therasFee = _fee;
  }

  function setupOffchain(address _offchainSigner) public onlyOwner {
    offchainSigner = _offchainSigner;
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

  // todo: cannot quantity 0 or minus?
  // gameId, gameAddressNFT,
  function buyProduct(
    // projectId // gameId
    // projectAddress
    bool isNativeToken,
    address payable productAddress,
    address paymentToken,
    uint256 paymentAmount, // price base
    uint256 productId,
    uint256 quantity,
    TokenType tokenType, //todo: remove this and use from contracts?? // shopAddress?? broker sale?
    uint256 payoutAmount, // For broker
    uint256 payoutPercentageDenominator, // For broker
    address payable brokerAddress,
    Ticket memory _ticket // bytes detail
  ) public payable {
    // 1. encode with msg.sender
    bytes32 digest = keccak256(
      abi.encode(
        msg.sender,
        isNativeToken,
        productAddress,
        paymentToken,
        paymentAmount,
        productId,
        quantity,
        tokenType,
        payoutAmount,
        payoutPercentageDenominator,
        brokerAddress
      )
    );

    require(isVerifiedTicket(digest, _ticket), "Invalid ticket");

    // change price * quantity??
    // uint256 _fullPrice = paymentAmount * quantity //payment amount already setup from offchain
    __paymentDistribution(
      isNativeToken,
      productAddress, // Changed to payable address
      paymentToken,
      paymentAmount, // Full price
      payoutAmount, // For broker
      payoutPercentageDenominator, // For broker
      brokerAddress
    );

    __mintable(tokenType, productAddress, productId, quantity);

    //emit Events
  }

  function __paymentDistribution(
    bool isNativeToken,
    address payable productAddress, // Changed to payable address
    address paymentToken,
    uint256 paymentAmount, // Full price
    uint256 payoutAmount, // For broker
    uint256 payoutPercentageDenominator, // For broker
    address payable brokerAddress
  ) internal {
    // Calculate Therashop fee
    uint256 therasFeeAmount = (paymentAmount * therasFee) / 1000;

    // Adjust payment amount for Therashop fee
    uint256 adjustedPaymentAmount = paymentAmount - therasFeeAmount;

    // Check if payment is made in native token (ether)
    if (isNativeToken) {
      require(msg.value >= paymentAmount, "Insufficient payment amount");

      // If there's a broker, calculate their cut from the adjusted payment
      if (brokerAddress != address(0)) {
        // Calculate broker cut as a percentage of adjusted payment amount
        uint256 brokerCut = (adjustedPaymentAmount * payoutAmount) /
          payoutPercentageDenominator;
        payable(brokerAddress).transfer(brokerCut);
        // Reduce the adjusted payment amount by the broker's cut
        adjustedPaymentAmount -= brokerCut;
      }

      // todo: add checker to identify contact address has receive module

      (bool success, ) = payable(productAddress).call{
        value: adjustedPaymentAmount
      }("");
      require(success, "Failed to send Ether to product address");

      (bool success2, ) = payable(address(this)).call{ value: therasFeeAmount }(
        ""
      );
      require(success2, "Failed to send Ether to Therashop");
    } else {
      // Check if payment token is ERC20
      require(
        paymentAmount <= IERC20(paymentToken).balanceOf(msg.sender),
        "Insufficient ERC20 balance"
      );

      // Check if the contract is allowed to spend the sender's tokens
      require(
        paymentAmount <=
          IERC20(paymentToken).allowance(msg.sender, address(this)),
        "Shop Contract not allowed to spend sender's tokens"
      );
      //
      require(
        paymentAmount <=
          IERC20(paymentToken).allowance(msg.sender, productAddress),
        "Collection Contract not allowed to spend sender's tokens"
      );

      // If there's a broker, transfer their cut
      if (brokerAddress != address(0)) {
        uint256 brokerCut = (adjustedPaymentAmount * payoutAmount) /
          payoutPercentageDenominator;
        IERC20(paymentToken).transfer(brokerAddress, brokerCut);

        // Reduce the adjusted payment amount by the broker's cut
        adjustedPaymentAmount -= brokerCut;
      }

      // Transfer payment token to product address
      IERC20(paymentToken).transferFrom(
        msg.sender,
        productAddress,
        adjustedPaymentAmount
      );

      // Transfer payment token to Therashop
      IERC20(paymentToken).transferFrom(
        msg.sender,
        address(this),
        therasFeeAmount
      );
    }
  }

  function __mintable(
    TokenType tokenType,
    address productAddress,
    uint256 productId,
    uint256 quantity
  ) internal {
    if (tokenType == TokenType.ERC20) {
      // ERC20 buying bundle or something
    } else if (tokenType == TokenType.ERC721) {
      // ERC721
      IUniversalClaim(productAddress).mintCollectible(msg.sender);
    } else if (tokenType == TokenType.ERC1155) {
      // ERC1155
      IUniversalClaim(productAddress).mintCollectibleId(
        msg.sender,
        productId,
        quantity
      );
    }
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // Function to get the value of offchainSigner
  function getOffchainSigner() public view onlyOwner returns (address) {
    return offchainSigner;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  function isVerifiedTicket(bytes32 _digest, Ticket memory _ticket)
    internal
    view
    returns (bool)
  {
    address signer = ecrecover(_digest, _ticket.v, _ticket.r, _ticket.s);
    require(signer != address(0), "ECDSA: invalid signature");
    return signer == offchainSigner;
  }
}
