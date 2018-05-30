import gym
import gym.spaces
from gym import envs

print(f"Available ens: {envs.registry.all()}")


def taxi():
    env = gym.make("Taxi-v2")
    observation = env.reset()
    for _ in range(1000):
        env.render()
        action = env.action_space.sample()  # your agent here (this takes random actions)
        observation, reward, done, info = env.step(action)
    env.env.close()


def cart_pole_random():
    env = gym.make('CartPole-v0')
    env.reset()
    for _ in range(1000):
        env.render()
        env.step(env.action_space.sample())  # take a random action
    env.env.close()


def cart_pole():
    env = gym.make('CartPole-v0')
    # env = gym.make('MountainCarContinuous-v0')
    for i_episode in range(200):
        observation = env.reset()
        for t in range(100):
            env.render()
            print(observation)
            action = env.action_space.sample() # Select a random action
            observation, reward, done, info = env.step(action)
            if done:
                print("Episode finished after {} timesteps".format(t+1))
                break
    env.env.close()

# TODO: cart_pole with a learning strategy from https://github.com/openai/baselines
cart_pole_random()
