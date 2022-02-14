// // TODO 

// pragma solidity ^0.6.2;
//
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
//
//
// contract Treasury is Ownable {
//   using SafeERC20 for IERC20;
//
//   struct VoteData {
//     uint256 topicId;
//   }
//
//   mapping(address => VoteData) public voteData;
//   mapping(STATUS => mapping(address => bool)) public permissions;
//
//   enum STATUS {
//     TOKENMANAGER,
//     LIQUIDITYMANAGER,
//     LIQUIDITYTOKEN
//   }
//
//   function setVote(address) external onlyOwner {
//
//   }
//
//   function withdraw(uint256 _amount, address _token) external {
//     if(permissions[STATUS.RESERVEDEPOSITOR][_token]){
//       require(permissions[STATUS.LIQUIDITYMANAGER][msg.sender], "NOT LIQUIDITYMANAGER");
//     }else{
//       require(permissions[STATUS.TOKENMANAGER][msg.sender], "NOT TOKENMANAGER");
//     }
//
//     IERC20(_token).safeTransfer(msg.sender, _amount);
//   }
// }
