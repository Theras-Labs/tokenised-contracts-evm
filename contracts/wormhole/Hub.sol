// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IWormholeRelayer.sol";
import "./interface/IWormholeReceiver.sol";

contract WormholeHub is IWormholeReceiver, Ownable {
  event WormholeMessageForwarded(
    address indexed sender,
    bytes payload,
    address refundAddress,
    uint256 cost
  );
  /**
   * @dev wormhole relayer which manages crosschain communication
   */
  IWormholeRelayer public wormholeRelayer;
  uint16 public wm_currentChain = 16; //moonbeam
  uint256 public gasLimit = 500_000;

  // chain -> address -> true
  mapping(uint16 => mapping(address => bool)) public whitelisted; // chainId => contract address => true/false

  constructor(
    address initialOwner,
    // uint16 _wm_currentChain,
    address _wormholeRelayer
  ) Ownable(initialOwner) {
    // wm_currentChain = _wm_currentChain;
    wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    // s_wormholeRelayer = _wormholeRelayer;
  }

  receive() external payable {}

  ///--------------------- ADMIN

  //   or set manager address here
  function whitelist(
    uint16 sourceChain,
    address sourceAddr,
    bool isWhitelisted
  ) public onlyOwner {
    whitelisted[sourceChain][sourceAddr] = isWhitelisted;
  }

  // todo: change gas limit

  ///--------------------- VIEW

  // function getCost(uint256 _targetChain, uint256 receiverValue)
  //   view public
  //   // returns (uint256 cost)
  // {
  //   (uint256 cost,)  = wormholeRelayer.quoteEVMDeliveryPrice(
  //     _targetChain,
  //     receiverValue,
  //     gasLimit
  //   );

  //   return cost;
  // }

  /**
   * @dev Convert bytes32 to address
   */
  function fromWormholeFormat(bytes32 whFormatAddress)
    public
    pure
    returns (address)
  {
    if (uint256(whFormatAddress) >> 160 != 0) {
      revert NotAnEvmAddress(whFormatAddress);
    }
    return address(uint160(uint256(whFormatAddress)));
  }

  ///--------------------- EXTERNAL

  // payable subsidized by receiverValue through wormhole relayer
  function receiveWormholeMessages(
    bytes memory payload,
    bytes[] memory, // additionalVaas
    bytes32 sourceAddress,
    uint16 sourceChain,
    bytes32 // deliveryHash
  ) public payable override {
    // make sure only relayer
    require(msg.sender == address(wormholeRelayer), "Only relayer allowed");
    address sourceAddr = fromWormholeFormat(sourceAddress);

    // only sending to Manager Address
    require(whitelisted[sourceChain][sourceAddr], "Unauthorized");

    //check if array or not to reduce gas complexity?
    (bool isArray, , , , , , , , , , , ) = abi.decode(
      payload,
      (
        bool,
        uint256,
        uint16,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        address,
        uint256
      )
    );

    // need to check if it's array
    // todo: probably just separate the chain tx offchain + UX so on wormhole always a single purpose chain bridge
    if (isArray) {
      // no need check if it's array already checked on manager
      (
        ,
        uint256[] memory wm_receiverValue,
        uint16[] memory wm_targetChain,
        address[] memory endManagerAddress,
        ,
        ,
        ,
        ,
        ,
        ,
        ,

      ) = abi.decode(
          payload,
          (
            bool,
            uint256[],
            uint16[],
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

      // If it's same wm_targetChain shouldnt repeat
      // Temporary array to track processed chains
      uint16[] memory uniqueTargetChains = new uint16[](wm_targetChain.length);
      uint16 uniqueCount = 0;

      // iterate
      for (uint16 i = 0; i < wm_targetChain.length; i++) {
        bool alreadyProcessed = false;

        // Check if targetChain has already been processed
        for (uint16 j = 0; j < uniqueCount; j++) {
          if (uniqueTargetChains[j] == wm_targetChain[i]) {
            alreadyProcessed = true;
            break;
          }
        }

        // If not processed, add to unique list and call forwardRelayer
        if (!alreadyProcessed) {
          uniqueTargetChains[uniqueCount] = wm_targetChain[i];
          uniqueCount++;

          forwardRelayer(
            payload,
            wm_receiverValue[i],
            wm_targetChain[i],
            endManagerAddress[i]
          );
        }
      }
    } else {
      // decode single
      (
        ,
        uint256 wm_receiverValue,
        uint16 wm_targetChain,
        address endManagerAddress,
        ,
        ,
        ,
        ,
        ,
        ,
        ,

      ) = abi.decode(
          payload,
          (
            bool,
            uint256,
            uint16,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            address,
            uint256
          )
        );

      forwardRelayer(
        payload,
        wm_receiverValue,
        wm_targetChain,
        endManagerAddress
      );
    }
  }

  ///--------------------- INTERNAL

  function forwardRelayer(
    bytes memory payload,
    uint256 _receivedValue, // for cost
    uint16 _targetChain,
    address _endManagerAddress
  ) internal {
    uint256 nextReceiverValue = 0; // manager wont passing token? todo: what if user also bridge native token with extra NFTs?

    (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
      _targetChain,
      nextReceiverValue,
      gasLimit
    );
    require(msg.value >= cost, "crosschain fee mismatch"); // bcause msg.value combined and more than
    // require(msg.value >= _receivedValue, "crosschain fee mismatch");
    // require(_receivedValue == cost, "_receivedValue  fee mismatch");

    // send data to base
    wormholeRelayer.sendPayloadToEvm{ value: cost }(
    // wormholeRelayer.sendPayloadToEvm{ value: _receivedValue }(
      _targetChain,
      _endManagerAddress,
      payload,
      nextReceiverValue,
      gasLimit,
      wm_currentChain, // refundChainId // just send back here
      address(this) // refundAddress
    );

    //   emit WormHoleReceive(
    //     sourceChain,
    //     msg.sender,
    //     fromWormholeFormat(sourceAddress),
    //     payload
    //   );
  }
}
