/*

Auto-configuring script for the spinnaker. 

The spinnaker prim must be named "spinnaker"

*/

vector initPos;
rotation initRot;
vector initSize;
vector hinge;
integer flaps;
integer isUp;

scale(float scale)
{
    llSetPrimitiveParams([PRIM_ROT_LOCAL, initRot, PRIM_POS_LOCAL, (initPos - <0, 0,initSize.z*(1-scale)/2>*initRot), PRIM_SIZE, <initSize.x, initSize.y,initSize.z*scale>]);
}


default
{
    state_entry()
    {
        initPos = llGetLocalPos();
        initRot = llGetLocalRot();
        initSize = llGetScale();
        
        hinge = llGetScale();
        hinge.x /= -2;
        hinge.y = 0; 
        hinge.z = 0;
        
        /// If the autodetected hinge point does not work, enter your hinge point below:
        // hinge = <0, 0, 0> ;
    }
    
    
    link_message(integer from, integer num, string msg,key id)
    {

        if (msg == "rotflap" || msg == "rot")
        {
            if(isUp)
            {
                rotation add = llEuler2Rot(<0,0, num*DEG_TO_RAD>);
                llSetPrimitiveParams([PRIM_ROT_LOCAL, add*initRot, PRIM_POS_LOCAL, (initPos+hinge*initRot)- hinge*initRot*add]);
                if (msg == "rotflap") llSetScale(<initSize.x, initSize.y*(.1+llFrand(.3)), initSize.z>);
                else llSetScale(initSize);
            }
        }
        else if (msg == "reset")
        {
            flaps=0;
            llSetPrimitiveParams([PRIM_ROT_LOCAL, initRot, PRIM_POS_LOCAL, (initPos), PRIM_SIZE,initSize]);
            llSetAlpha( 0, ALL_SIDES );

        }
        else if (msg == "raise")
        {
            flaps=0;
            scale(.1);
            llSleep(.2);
            llSetAlpha( 1, ALL_SIDES);
            llSleep(.4);
            scale(.5);
            llSleep(.4);
            scale(1.);
            isUp=1;
        }
        else if (msg == "lower" && isUp)
        {
            flaps=0;
            scale(.8);
            llSleep(.3);
            scale(.5);
            llSleep(.4);
            scale(.1);
            llSetAlpha( 0, ALL_SIDES );
            isUp=0;
        }
    }
 
   
}