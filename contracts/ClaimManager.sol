// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniversalClaim {
  function mintToken(address to, uint256 amount) external; // respective to erc20

  function mint(address to, uint256 amount) external; // respective to erc20

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

contract ClaimManager is Pausable, Ownable {
  struct Ticket {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
  enum TokenType {
    ERC20, // using mint shadow
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

  address private offchainSigner;
  uint256 public therasFee; // Therashop fee as a fraction of 1000 (e.g., 100 for 10%)

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
  function claimReward(
    bool isNativeToken,
    address productAddress,
    uint256 productId,
    uint256 quantity,
    TokenType tokenType, //todo: remove this and use from contracts??
    Ticket memory _ticket
  ) public {
    // 1. encode with msg.sender
    bytes32 digest = keccak256(
      abi.encode(
        msg.sender,
        isNativeToken,
        productAddress,
        productId,
        quantity,
        tokenType
      )
    );
    require(isVerifiedTicket(digest, _ticket), "Invalid ticket");
    __mintable(tokenType, productAddress, productId, quantity);
    //emit Events
  }

  // todo: change into dynamically method name instead
  function __mintable(
    TokenType tokenType,
    address productAddress,
    uint256 productId,
    uint256 quantity
  ) internal {
    if (tokenType == TokenType.ERC20) {
      IUniversalClaim(productAddress).mint(msg.sender, quantity);

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
