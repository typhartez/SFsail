/*
SFsail wake script

The wake is also used to play the sailing loop sound (because Playing the loop in the root object leads to a weird repetitive loop when the boat collides anywhere)


*/

default
{
    state_entry()
    {
         llParticleSystem([]);
    }
    
    link_message(integer from, integer n, string str, key id)
    {


        if (str=="lower" || str == "moor" || str == "motorstop" || str == "reset")
        {
            llParticleSystem([]);
            llStopSound();
        }
        else if (str=="start" )
        {

            llParticleSystem(
            [
                PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE_CONE,
                PSYS_SRC_BURST_RADIUS, .5,
                PSYS_SRC_ANGLE_BEGIN,PI/2,
                PSYS_SRC_ANGLE_END, PI/2+.1 ,
                PSYS_SRC_TARGET_KEY,llGetKey(),
                PSYS_PART_START_COLOR,<1.000000,1.000000,1.000000>,
                PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
                PSYS_PART_START_ALPHA, .7,
                PSYS_PART_END_ALPHA, 0.1,
                PSYS_PART_START_GLOW,0,
                PSYS_PART_END_GLOW,0,
                PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                PSYS_PART_START_SCALE, <1.0000, 1.00000, 0.000000>,
                PSYS_PART_END_SCALE,<4, 4, 0.000000>,
                PSYS_SRC_TEXTURE,"3a7ea058-e486-4d21-b2e6-8b47462bb45b",
                PSYS_SRC_MAX_AGE,0,
                PSYS_PART_MAX_AGE,8,
                PSYS_SRC_BURST_RATE,0.02,
                PSYS_SRC_BURST_PART_COUNT,1,
                PSYS_SRC_ACCEL,<0.000000,0.000000,-1.00000>,
                PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                PSYS_SRC_BURST_SPEED_MIN, .1 ,
                PSYS_SRC_BURST_SPEED_MAX, .5 ,
                PSYS_PART_FLAGS,
                    0
                    | PSYS_PART_INTERP_COLOR_MASK
                    | PSYS_PART_BOUNCE_MASK
                    | PSYS_PART_EMISSIVE_MASK
                ]);
                
                llStopSound();

                llLoopSound("sailing", 1.0);
                

        }
    }
}
