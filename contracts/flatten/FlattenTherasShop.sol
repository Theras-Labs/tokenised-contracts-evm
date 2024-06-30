

// Sources flattened with hardhat v2.22.4 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/Pausable.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File contracts/TherasShop.sol

// Original license: SPDX_License_Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;



// interface Ownable {
//   function transferOwnership(address to) external;
// }

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
    ERC721_SAFE_MINT,
    ERC721_MINT,
    ERC721_SAFE_MINT_BATCH,
    ERC721_SAFE_MINT_BATCH_SHOP
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
