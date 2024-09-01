// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./wormhole/interface/IWormholeSupport.sol";

interface IUniversalClaim {
  function mintToken(address to, uint256 amount) external; // respective to erc20

  function mint(address to) external;

  function safeMint(address to) external;

  function safeMintBatch(address to, uint256 quantity) external;

  function mintCollectible(address to) external; // respective to erc721

  function mintCollectibleId(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external; // respective to erc1155
}

contract TherasShop is Pausable, Ownable {
  struct Ticket {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
  enum TokenType {
    ERC20,
    ERC721,
    ERC1155,
    // below is experiment and going to change into easier way
    ERC721_SAFE_MINT,
    ERC721_MINT,
    ERC721_SAFE_MINT_BATCH,
    ERC721_SAFE_MINT_BATCH_SHOP

    // ERC404
  }
  enum ActionType {
    MINT,
    TRANSFER,
    UNLOCK,
    LOCK,
    BURN
  }

  event WormholeTaskProcessed(
    address indexed sender,
    uint256 payloadIndex,
    uint256 queueIndex,
    ActionType actionType,
    TokenType tokenType,
    address productAddress,
    uint256 productId,
    uint256 quantity,
    address recipientAddress
  );

  address private offchainSigner;
  uint256 public therasFee; // Therashop fee as a fraction of 1000 (e.g., 100 for 10%)
  address public s_managerWormhole;

  constructor(
    address initialOwner,
    uint256 _fee,
    address _offchainSigner
  ) Ownable(initialOwner) {
    therasFee = _fee;
    offchainSigner = _offchainSigner;
  }

  receive() external payable {}

  function setupTherasFee(uint256 _fee) public onlyOwner {
    therasFee = _fee;
  }

  function setupOffchain(address _offchainSigner) public onlyOwner {
    offchainSigner = _offchainSigner;
  }

  function setupManagerWormhole(address _managerWormhole) public onlyOwner {
    s_managerWormhole = _managerWormhole;
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

  // claim cross + receive fund
  // buy cross product
  function TEST_buyCrossProduct(
    // /////////
    uint256 wm_receiverValue, // -> calculations  -> actually wrong and seems not needed yet
    uint256 wm_targetChain,
    address endManagerAddress,
    address actionAddress,
    ActionType actionType,
    TokenType tokenType,
    uint256 productId,
    uint256 quantity,
    address productAddress,
    address recipientAddress, //
    uint256 receiverValue // calculate if it's in array // Ticket
  ) external {
    // WormholeManager.getCost() -> // not needed here, use it offchain
    bytes memory payload = abi.encode(
      true, // isArray,
      wm_receiverValue, // -> can be array
      wm_targetChain, //-> can be array
      endManagerAddress, // -> can be array
      actionAddress, // -> the end contract either [ shop, bridge, or craft ]
      actionType, // ->   the end action will either  mint, mintBatch, locking, transfer, unlock
      tokenType, // -> erc721, erc1155, erc20, dnd404, unknown
      productId, // -> tokenId,
      quantity, // ->
      productAddress, //  -> contract NFT/token address,
      recipientAddress, //
      block.timestamp
    );

    IWormholeSupport(s_managerWormhole).forwardWormholeTask(
      payload,
      msg.sender,
      receiverValue //should be from wm_receiverValue calculations
    );
  }

  function TEST_buyCrossProduct(
    // /////////
    uint256 wm_receiverValue, // -> calculations  -> actually wrong and seems not needed yet?
    uint256 wm_targetChain,
    address endManagerAddress,
    address actionAddress,
    ActionType actionType,
    TokenType tokenType,
    uint256 productId,
    uint256 quantity,
    address productAddress,
    address recipientAddress, //
    uint256 receiverValue // calculate if it's in array // Ticket
  ) external {
    // WormholeManager.getCost() -> // not needed here, use it offchain
    bytes memory payload = abi.encode(
      true, // isArray,
      wm_receiverValue, // -> can be array
      wm_targetChain, //-> can be array
      endManagerAddress, // -> can be array
      actionAddress, // -> the end contract either [ shop, bridge, or craft ]
      actionType, // ->   the end action will either  mint, mintBatch, locking, transfer, unlock
      tokenType, // -> erc721, erc1155, erc20, dnd404, unknown
      productId, // -> tokenId,
      quantity, // ->
      productAddress, //  -> contract NFT/token address,
      recipientAddress, //
      block.timestamp
    );

    IWormholeSupport(s_managerWormhole).forwardWormholeTask(
      payload,
      msg.sender,
      receiverValue //should be from wm_receiverValue calculations if it's array
    );
  }

  function buyCrossProduct(
    uint256 wm_receiverValue,
    uint256 wm_targetChain,
    address endManagerAddress,
    address actionAddress,
    ActionType actionType,
    TokenType tokenType,
    uint256 productId,
    uint256 quantity,
    address productAddress,
    address recipientAddress,
    uint256 receiverValue,
    // default args
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

    bytes memory payload = abi.encode(
      true, // isArray,
      wm_receiverValue, // -> can be array
      wm_targetChain, //-> can be array
      endManagerAddress, // -> can be array
      actionAddress, // -> the end contract either [ shop, bridge, or craft ]
      actionType, // ->   the end action will either  mint, mintBatch, locking, transfer, unlock
      tokenType, // -> erc721, erc1155, erc20, dnd404, unknown
      productId, // -> tokenId,
      quantity, // ->
      productAddress, //  -> contract NFT/token address,
      recipientAddress, //
      block.timestamp
    );

    IWormholeSupport(s_managerWormhole).forwardWormholeTask(
      payload,
      msg.sender,
      receiverValue //should be from wm_receiverValue calculations if it's array
    );
  }

  // overload for array version
  function TEST_buyCrossProduct(
    /////////
    bool isArray,
    uint256[] memory wm_receiverValue, //store disni [base, sepolia, base] -> [3000, 2000, 3000] ->  value 3000 + 2000  as COST (not sure if not im using different COST here?)
    uint256[] memory wm_targetChain,
    address[] memory endManagerAddress,
    address[] memory actionAddress,
    ActionType[] memory actionType,
    TokenType[] memory tokenType,
    uint256[] memory productId,
    uint256[] memory quantity,
    address[] memory productAddress,
    address[] memory recipientAddress,
    address refundAddress,
    uint256 receiverValue,
    address refundAddress,
    uint256 receiverValue // calculate if it's in array // Ticket
  ) {
    // similar for single
  }

  // single
  function receivedWormholeTask(bytes memory payload) external {
    //check only from Manager
    require(
      msg.sender == address(s_managerWormhole),
      "Only wormhole manager allowed"
    );

    (
      bool isArray,
      uint256 wm_receiverValue,
      uint256 wm_targetChain,
      address endManagerAddress,
      address actionAddress,
      ActionType actionType,
      TokenType tokenType,
      uint256 productId,
      uint256 quantity, //[] ->
      address productAddress, //[] -> contract NFT/token address,
      address recipientAddress, //[]
      uint256 timestamp
    ) = abi.decode(
        payload,
        (
          bool,
          uint256,
          uint256,
          address,
          address,
          ActionType,
          TokenType,
          uint256,
          uint256,
          address,
          address,
          uint256
        )
      );

    if (actionType == ActionType.MINT) {
      __mintable(
        tokenType,
        productAddress,
        productId,
        quantity,
        recipientAddress
      );
    }
    // ActionType.TRANSFER
    // ActionType.BURN
  }

  // for multiple task
  // FOR ARRAY won't needed to ITERATE THE TASK, since wmanager sending it multiple times and iterated already
  // overload for array
  function receivedWormholeTask(
    bytes memory payload,
    uint256 payloadIndex,
    uint256 queueIndex
  ) external {
    //check only from Manager
    require(msg.sender == address(s_managerWormhole), "Only manager allowed");
    (
      bool isArray,
      uint256[] memory wm_receiverValue,
      uint256[] memory wm_targetChain,
      address[] memory endManagerAddress,
      address[] memory actionAddress,
      uint256[] memory actionType,
      uint256[] memory tokenType,
      uint256[] memory productId,
      uint256[] memory quantity,
      address[] memory productAddress,
      address[] memory recipientAddress,
      uint256 timestamp
    ) = abi.decode(
        payload,
        (
          bool,
          uint256[],
          uint256[],
          address[],
          address[],
          uint256[],
          uint256[],
          uint256[],
          uint256[],
          address[],
          address[],
          uint256
        )
      );

    if (actionType[payloadIndex] == ActionType.MINT) {
      __mintable(
        tokenType[payloadIndex],
        productAddress[payloadIndex],
        productId[payloadIndex],
        quantity[payloadIndex],
        recipientAddress[payloadIndex]
      );
    }

    // Emit an event for auditing and tracking
    emit WormholeTaskProcessed(
      msg.sender,
      payloadIndex,
      queueIndex,
      actionType[payloadIndex],
      tokenType[payloadIndex],
      productAddress[payloadIndex],
      productId[payloadIndex],
      quantity[payloadIndex],
      recipientAddress[payloadIndex]
    );
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
      // TODO: CHANGE TO VENDOR INSTEAD since some contract might not be able to receive
      // and product address might be a middleware too? but should be fine?
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

      // TODO: CHANGE TO VENDOR INSTEAD since some contract might not be able to receive
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

  // simplest version for wormhole testing
  // should migrate to recipientAddress as param
  function __mintable(
    TokenType tokenType,
    address productAddress,
    uint256 productId,
    uint256 quantity,
    address recipientAddress
  ) internal {
    if (tokenType == TokenType.ERC1155) {
      // ERC1155
      IUniversalClaim(productAddress).mintCollectibleId(
        recipientAddress,
        productId,
        quantity
      );
    }
  }

  // todo: change into dynamically method name instead
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
    //  721 - MINT
    else if (tokenType == TokenType.ERC721_SAFE_MINT) {
      // + mint
      // iterate base  quantity length
      IUniversalClaim(productAddress).safeMint(msg.sender);
    } else if (tokenType == TokenType.ERC721_MINT) {
      // + mint
      // iterate base  quantity length
      IUniversalClaim(productAddress).mint(msg.sender);
    } else if (tokenType == TokenType.ERC721_SAFE_MINT_BATCH) {
      // + mint
      // iterate base  quantity length
      IUniversalClaim(productAddress).safeMintBatch(msg.sender, quantity);
    } else if (tokenType == TokenType.ERC721_SAFE_MINT_BATCH_SHOP) {
      // BATCH BY SHOP -> a lot of gas?
      require(quantity > 0, "Quantity must be greater than 0");
      for (uint256 i = 0; i < quantity; i++) {
        IUniversalClaim(productAddress).safeMint(msg.sender);
      }
    }
  }

  // Function to transfer ownership of a managed contract
  function transferManagedContractOwnership(
    address contractAddress,
    address newOwner
  ) external onlyOwner {
    Ownable(contractAddress).transferOwnership(newOwner);
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

  //   internal

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
