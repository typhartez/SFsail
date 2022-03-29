For new boats you can use an existing boat or SFsail template and then to link your boat with it. 

Change the texture opacity to 0% and then move the sails to their final positions (DO NOT SIT on the boat while you do this), and then right click on the boat -> Object -> Reset scripts to reset all the scripts in all prims. The sails / boom included with SFsail do not need more configuration, just make sure you reset the scripts every time you edit the positions. 


## Windvane

The SFsail main script will rotate the object named "windvane" along its Z axis to point to the true wind . If you have a more coomplicated setup, they will receive the "windDirection" link_message whenever the wind changes

## Wake / Motor

See the Wake / Motor scripts

## Sails / Boom

See the sails script. SFsail recognizes the prims named 'boom', 'sail', 'jib' , 'genoa' and 'spinnaker'

## Instruments

SFsail uses a custom set of compass instruments and displays. The prim named 'instruments' receives the instrument commands. See the instrument script for details

## Rudder/ Helm wheel

The prim being the rudder or the helm must be named 'steer'. Place the appropriate script for either of them 

