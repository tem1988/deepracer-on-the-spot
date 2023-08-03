import math

class Alfetta:
    def __init__(self):
        self.pre_progress = 0
        self.pre_progress2 = 0
        self.pre_progress3 = 0

    def reward_function(self, params):
        progress = max(0, params['progress'])
        steps = params['steps']
        speed = params['speed']
        is_offtrack = params['is_offtrack']
        x = params['x']
        y = params['y']
        MIN_REWARD = 1e-4
        MAX_STEPS = 250  # Define el nÃƒÂºmero mÃƒÂ¡ximo de pasos permitidos para alcanzar la meta.


        reward=MIN_REWARD
        if steps == 2:
            self.pre_progress = 0

        if is_offtrack and progress != 100:  # Punish off tracks.
            return float(max(MIN_REWARD, reward))
        else:
            # Recompensa basada en el progreso.
            reward = progress - self.pre_progress
            self.pre_progress = progress

             # Give additional reward if the car pass every 50 steps faster than expected
            if (steps % 50) == 0 and progress > (steps / MAX_STEPS) * 100 :
                print("5")
                reward += 5.0

        return float(max(MIN_REWARD, reward))


myCarObject = Alfetta()

def reward_function(params):
    return myCarObject.reward_function(params)