# Jockulus
We came into this hackathon wanting to do bridge the gap between the natural and digital worlds. Although technological progress has benefited society, it increasingly encourages a sedentary lifestyle.
Consequently, we created Jockulus, a hack that combines the Oculus Rift and Myo to provide a seamless, virtual running experience. Users can put on their Oculus Rift and immediately be placed on a virtual track, simulating the canals of Rome. The terrain is procedurally generated using Unity. and changes to reflect your running pace. Additionally, using the Spotify and echo-nest APIs, our iPhone app will play tracks that match your cadence. Qualities of the track playing will change the virtual world you run in. Finally, we integrated with Myo to allow for easy song manipulation. Gestures allow runners to pause and skip tracks to their discretion. After the run, users will be prompted to share their distance on Facebook.
Our targets users are treadmill users, aspiring runners, and technologists who want to break out of a sedentary lifestyle.

This particular repository is for the iPhone app. This means it handles 4 primary functions:
#####1. Pedometer
#####2. Spotify Integration
#####3. Music Control Through Myo
#####4. Facebook Integration

The app constantly measures the rate at which the user is walking then adjusts the song accordingly using spotify and echo-nest
on the backend.As well, the app handles the ability to pause, resume, and skip tracks using the Myo. Finally, the app handles
Facebook authentication such that the user can post the estimated length of their run (in meters) on Facebook.

###[Backend Found Here](https://github.com/AndrewAday/PennApps_2015s)
