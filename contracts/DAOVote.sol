import "@openzeppelin/contracts/math/SafeMath.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}

contract DAOVote {
  using SafeMath for uint256;

  uint256 public totalTopicIds;
  IERC20 public token;

  struct TopicData {
    bool unvoteEnabled;
    uint256 candidatesCount;
    bool daedlineEnabled;
    uint256 daedline;
    bool created;
  }

  struct VoteData {
    uint256 voteBalance;
    bool isVoted;
  }

  mapping(uint256 => mapping(uint256 => uint256)) public topicResults;
  mapping(address => mapping(uint256 => mapping(uint256 => VoteData))) public votersData;
  mapping(uint256 => TopicData) public topicsData;

  event Vote(address indexed _from, uint256 topicId, uint256 candidateId);
  event Unvote(address indexed _from, uint256 topicId, uint256 candidateId);

  constructor(address _token) public {
    token = IERC20(_token);
  }

  // create new topic
  function create(
    bool unvoteEnabled,
    uint256 candidatesCount,
    bool daedlineEnabled,
    uint256 daedline
  )
    external
  {
    TopicData memory topicData = TopicData(
      unvoteEnabled,
      candidatesCount,
      daedlineEnabled,
      now + daedline,
      true
    );

    totalTopicIds = totalTopicIds + 1;
    topicsData[totalTopicIds] = topicData;
  }

  // vote
  function vote(uint256 topicId, uint256 candidateId) external {
    verify(topicId, candidateId, false);
    require(!votersData[msg.sender][topicId][candidateId].isVoted, "Voted");

    uint256 userBalance = token.balanceOf(msg.sender);
    require(userBalance > 0, "0 vote");

    topicResults[topicId][candidateId] += userBalance;
    VoteData memory _voteData = VoteData(userBalance, true);

    votersData[msg.sender][topicId][candidateId] = _voteData;

    emit Vote(msg.sender, topicId, candidateId);
  }

  // unvote
  function unvote(uint256 topicId, uint256 candidateId) external {
    verify(topicId, candidateId, true);
    require(votersData[msg.sender][topicId][candidateId].isVoted, "Not voted");

    VoteData memory _voteData = votersData[msg.sender][topicId][candidateId];

    topicResults[topicId][candidateId] -= _voteData.voteBalance;
    _voteData.voteBalance = 0;
    _voteData.isVoted = false;

    votersData[msg.sender][topicId][candidateId] = _voteData;

    emit Unvote(msg.sender, topicId, candidateId);
  }

  // verify topic
  function verify(uint256 topicId, uint256 candidateId, bool isUnvoteAction) internal {
    TopicData memory topicData = topicsData[topicId];
    // verify if topice created
    require(topicData.created, "Not created");
    // verify candidate count
    require(candidateId <= topicData.candidatesCount, "Wrong candidate");
    // verify deadline
    if(topicData.daedlineEnabled)
      require(now < topicData.daedline, "Deadline");
    // additional verification for unvote action
    if(isUnvoteAction)
      require(topicData.unvoteEnabled, "Unvote disabled");
  }
}
