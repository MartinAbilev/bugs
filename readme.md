#BUGZ

[![Everything Is AWESOME]( https://bianca-ai.vercel.app/mqdefault.jpg )]( https://youtu.be/ZsoNCcIcb3U "BUGZ")


#Client (Next Js) work in progress

-vercel prod client whith local server:
        https://bianca-ai.vercel.app

#Reanimation of "The Bugs" Project

This repository breathes new life into the historic "The Bugs" project, an artificial neural network (ANN) simulation initially developed in Python. Unfortunately, none of the original code has survived, but the core concept remains the same: evolve a population of virtual "bugs" within a 2D, physically simulated environment.

Project Overview
In the original "The Bugs" project, the goal was to create and evolve ANN-controlled bugs with the simple objective of avoiding collisions with each other and with any red-colored objects in their environment.

Key Features:
2D Physics Simulation: Bugs exist in a 2D container where physical interactions are simulated, including collisions and movement.
ANN Sensors: Each bug is equipped with 4 input sensors that detect the presence of red pixels in its immediate surroundings.
Actuators: Bugs have 4 (or 5) actuators that allow them to move and rotate within the environment.
Survival of the Fittest: Bugs that survive the longest in this environment are selected to spawn the next generation, promoting the evolution of more adept behaviors.
Morphological Evolution: In the later iterations, bugs also began to evolve their "morphology," meaning the positions of their sensors could change, leading to fascinating evolutionary developments.

    #Dependencies
        uses  JOK https://github.com/Jack-Ji/jok
        http  TOKAMAK https://github.com/cztomsik/tokamak

    #To doos:

        #for physics
            add trsuters
            make them fire with some gfx

        #for jok
            add simple ui.
            togle world/brain mode
            function to grid layout nurons position

        #for ann logic
            *move update from nurons to brai this is brin functin to update and mutate
            !mutate weights function

        #for net
            *add simple server
            *make it nonblokng probably in separate tread;
            *crete response with bugz state
            *format bugstate responses to json
            create simple web ui here
                https://bianca-ai.vercel.app/
                kinda separate view


M.A 2024
