#Class to handle and calculate the calories burnt
class CaloriesBurnt:

    #We use the age and weight of the user
    def __init__(self, gender, weight, age):
        self.gender = gender.lower()
        self.weight = weight
        self.age = age

    #Function to make the calories burnt calculation and print the result
    def cal_count(self, heartbr, time = 1):
        if self.gender == 'male':
            cals = ((self.age * 0.2017) - (self.weight * 0.09036) + (heartbr * 0.6309) - 55.0969) * time / 4.184
        else:
            cals = ((self.age * 0.074) - (self.weight * 0.05741) + (heartbr * 0.4472) - 20.4022) * time / 4.184

        print(f"The calories burnt are {cals} calories for 1 minute.")
    

