// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

interface IWormholeSupport {
  function receivedWormholeTask(
    bytes memory payload,
    uint256 i,
    uint256 queueId
  ) external;

  function receivedWormholeTask(bytes memory payload) external;

      function forwardWormholeTask(
    bytes memory payload,
    address refundAddress,
    uint256 receiverValue
  ) external;
}
