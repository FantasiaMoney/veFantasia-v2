import "@openzeppelin/contracts/math/SafeMath.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}

contract DAOVote {
  using SafeMath for uint256;

  uint256 public totalTopicIds;
  IERC20 public token;

  struct VoteData {
    uint256 voteBalance;
    bool isVoted;
  }

  mapping(uint256 => mapping(uint256 => uint256)) public topics;
  mapping(address => mapping(uint256 => mapping(uint256 => VoteData))) public voteData;

  constructor(address _token) public {
      token = IERC20(_token);
  }

  function newTopic() external {
      totalTopicIds = totalTopicIds + 1;
  }

  function vote(uint256 topicId, uint256 candidateId) external {
      require(topicId <= totalTopicIds, "Not created");
      require(!voteData[msg.sender][topicId][candidateId].isVoted, "Voted");
      uint256 userBalance = token.balanceOf(msg.sender);
      require(userBalance > 0, "0 vote");
      topics[topicId][candidateId] += userBalance;
      VoteData memory _voteData = VoteData(userBalance, true);
      voteData[msg.sender][topicId][candidateId] = _voteData;
  }

  function unvote(uint256 topicId, uint256 candidateId) external {
      require(topicId <= totalTopicIds, "Not created");
      require(voteData[msg.sender][topicId][candidateId].isVoted, "Not voted");
      VoteData memory _voteData = voteData[msg.sender][topicId][candidateId];
      topics[topicId][candidateId] -= _voteData.voteBalance;
      _voteData.voteBalance = 0;
      _voteData.isVoted = false;
      voteData[msg.sender][topicId][candidateId] = _voteData;
  }
}
