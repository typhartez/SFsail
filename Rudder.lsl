/*

Rudder autoconfiguring script. If your boat uses a rudder, drop this in. 
The rudder prim must be named 'steer'

*/


rotation initRot;
default
{
    state_entry()
    {
        initRot = llGetLocalRot();
        llSetObjectName("steer");
    }
    
    link_message(integer from, integer num, string turn, key id)
    {

        if (num == 887) 
        {
            float f = (float)turn;
            if (f >0) f = -0.1;
            else if (f <0) f = 0.1;
            else f =0;
            
            llSetLocalRot(llEuler2Rot(<0,0, f> ) *initRot );
        }
        else if (turn == "reset") llSetLocalRot(initRot);
    }
}
