using ReinforcementLearning
using SnakeGames

env = SnakeGames.SnakeGameEnv();

run(
    RandomPolicy(),
    env,
    StopAfterStep(1_000),
    TotalRewardPerEpisode()
);