# Reinforcement learning algorithms

Gym library create common env, but has no RL algorithm implemented

Ses baseline project fo RL algorithm implementations <https://github.com/openai/baselines>

OR <https://github.com/rll/rllab>

## Gym

### Lunar render

See docs in <https://github.com/openai/gym/blob/master/gym/envs/box2d/lunar_lander.py>

Clone gym and enter folder

play yourself `python3 examples/agents/keyboard_agent.py LunarLander-v2`

heuristic landing, run: `python3 gym/envs/box2d/lunar_lander.py`

### Cart pole

## Baseline

From <https://github.com/openai/baselines>

first `brew install cmake openmpi`

install `pip3 install baselines`

Train cart pole with mlp (multi layer perceptron)

Train:

- Code <https://github.com/openai/baselines/blob/master/baselines/deepq/experiments/train_cartpole.py>
- Execute  `python3 -m baselines.deepq.experiments.train_cartpole`

Run model:

- Code <https://github.com/openai/baselines/blob/master/baselines/deepq/experiments/enjoy_cartpole.py>
- Execute `python3 -m baselines.deepq.experiments.enjoy_cartpole` 