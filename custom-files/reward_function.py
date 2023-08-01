import math

class Alfetta:
    def __init__(self):
        self.pre_progress = 0
        self.pre_progress2 = 0
        self.pre_progress3 = 0
        self.pre_speed = 0


    def reward_function(self, params):
        progress = max(0, params['progress'])
        steps = params['steps']
        speed = params['speed']
        is_offtrack = params['is_offtrack']
        x = params['x']
        y = params['y']
        MIN_REWARD = 1e-4
        reward = 0
        if steps == 2:
            self.pre_progress = 0
            self.pre_speed = 0

        if is_offtrack and progress != 100:  # Punish off tracks.
            return float(max(MIN_REWARD, reward))
        else:
            reward += progress - self.pre_progress

            # Add reward if the car is faster than previous step
            if speed > self.pre_speed:
                reward += (speed - self.pre_speed) * 0.5  # Adjust the weight as necessary

        self.pre_progress = progress
        self.pre_speed = speed

        return float(max(MIN_REWARD, reward))


myCarObject = Alfetta()


def reward_function(params):
        return myCarObject.reward_function(params)