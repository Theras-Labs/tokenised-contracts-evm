// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IWormholeRelayer.sol";
import "./interface/IWormholeReceiver.sol";
import "./interface/IWormholeSupport.sol";
import "../utils/AllowedContracts.sol";

contract WormholeManager is IWormholeReceiver, AllowedContracts, Ownable {
  event WormholeMessageForwarded(
    address indexed sender,
    bytes payload,
    address refundAddress,
    uint256 cost
  );

  event WormHoleReceive(
    uint16 chainId,
    address relayer,
    address vault,
    bytes payload
  );

  /**
   * @dev wormhole relayer which manages crosschain communication
   */
  IWormholeRelayer public wormholeRelayer;
  uint16 public wm_currentChain;
  uint16 public wm_hubChain = 16; // Moonbeam
  address public hubAddress; // moonbeam only
  uint256 public receiverValue = 0; // Can be left 0, since we don't need an airdrop of gas token on destination contract
  uint256 public gasLimit = 500_000;

  constructor(
    address initialOwner,
    uint16 _wm_currentChain,
    address _wormholeRelayer
  ) Ownable(initialOwner) {
    wm_currentChain = _wm_currentChain;
    wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
  }

  ///--------------------- ADMIN
  function addAllowedContract(address contractAddress) public onlyOwner {
    _addAllowedContract(contractAddress);
  }

  function removeAllowedContract(address contractAddress) public onlyOwner {
    _removeAllowedContract(contractAddress);
  }

  function setHubAddress(address _hubAddress) public onlyOwner {
    hubAddress = _hubAddress;
  }

  ///--------------------- VIEW

  function getCost() public view returns (uint256 cost) {
    (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
      wm_hubChain,
      receiverValue,
      gasLimit
    );

    return cost;
  }

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

  function forwardWormholeTask(
    bytes memory payload,
    address refundAddress,
    uint256 receiverValue
  ) external payable onlyOperator {
    uint256 cost = getCost(); // Retrieve cost
    require(msg.value == cost, "crosschain fee mismatch");
    // require(msg.value == receiverValue, "crosschain fee mismatch");

    // msgSender
    wormholeRelayer.sendPayloadToEvm{ value: receiverValue }(
      // wormholeRelayer.sendPayloadToEvm{ value: cost }(
      wm_hubChain, // uint256
      hubAddress, // address
      payload, // payload
      receiverValue, // uint256 //-> for moonbeam -> x (if array multiple)
      gasLimit, // uint256
      wm_currentChain, // should refund to this chain
      refundAddress // refundAddress
    );

    // emit WormholeMessageForwarded(msg.sender, payload, refundAddress, cost);
    emit WormholeMessageForwarded(
      msg.sender,
      payload,
      refundAddress,
      receiverValue
    );
  }

  // therasAddress -> reporter/responsible
  // might need pass value to cover gas mint?
  //-------------------
  function receiveWormholeMessages(
    bytes memory payload,
    bytes[] memory, // additionalVaas
    bytes32 sourceAddress,
    uint16 sourceChain,
    bytes32 // deliveryHash
  ) public payable override {
    require(msg.sender == address(wormholeRelayer), "Only relayer allowed");
    address sourceAddr = fromWormholeFormat(sourceAddress);
    require(sourceAddr == hubAddress, "Unauthorized");

    // identify array
    (bool isArray, , , , , , , , , , , ) = abi.decode(
      payload,
      (
        bool,
        uint256,
        uint256,
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

    if (isArray) {
      // find the related item here
      (
        ,
        ,
        uint256[] memory wm_targetChain,
        ,
        address[] memory actionAddress,
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

      uint256 queueId = 0;
      for (uint256 i = 0; i < wm_targetChain.length; i++) {
        // find selfChain
        if (wm_targetChain[i] == wm_currentChain) {
          queueId++;
          // on end will check timestamp + queueId, still need i for match the array index later
          IWormholeSupport(actionAddress[i]).receivedWormholeTask(
            payload,
            i,
            queueId
          );
          emit WormHoleReceive(
            sourceChain,
            msg.sender,
            fromWormholeFormat(sourceAddress),
            payload
          );
        }
      }
    } else {
      (, , , , address actionAddress, , , , , , , ) = abi.decode(
        payload,
        (
          bool,
          uint256,
          uint256,
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

      IWormholeSupport(actionAddress).receivedWormholeTask(payload);
      emit WormHoleReceive(
        sourceChain,
        msg.sender,
        fromWormholeFormat(sourceAddress),
        payload
      );
    }
  }
}
