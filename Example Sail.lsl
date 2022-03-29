/*

Auto-configuring sail script for mainsail / jib/ genoa

It should work out of the box for sails that are rotating around their Z axis. 

You should change the faces in the "rotflap" command indicated below if they don't match your sail

The mainsail prim must be named "sail", the jib "jib" and genoa "genoa"

*/

vector initPos;
rotation initRot;
vector initSize;
vector hinge;
integer flaps;
integer face1;
integer face2;
integer isUp;

scale(float scale)
{
    llSetPrimitiveParams([PRIM_ROT_LOCAL, initRot, PRIM_POS_LOCAL, (initPos - <0, 0,initSize.z*(1-scale)/2>*initRot), PRIM_SIZE, <initSize.x, initSize.y*scale,initSize.z*scale>]);
}


default
{
    state_entry()
    {
        if (llGetLinkNumber() >1)
        {
            initPos = llGetLocalPos();
            initRot = llGetLocalRot();
            initSize= llGetScale();
            hinge = llGetScale();
            hinge.x /=2;
            hinge.y = 0; 
            hinge.z = 0;
        }
        
        /// If the autodetected hinge point does not work, enter your hinge point below:
        // hinge = <0, 0, 0> ;
    }
    
    
    link_message(integer from, integer num, string msg,key id)
    {
        if (llGetLinkNumber() < 1) return;
        if (msg == "rot" || msg == "rotflap")
        {
            if (!isUp) return;
            llSetAlpha(0, ALL_SIDES);   
            
            
            // Change faces to match left-most and right-most face for your sail:
            if (num> 0) llSetAlpha(1, 0); 
            else llSetAlpha(1, 2); 
            
            rotation add = llEuler2Rot(<0,0, num*DEG_TO_RAD>);
            
            llSetPrimitiveParams([PRIM_ROT_LOCAL, add*initRot, PRIM_POS_LOCAL,  (initPos+hinge*initRot)- hinge*add*initRot]);
            
            if (msg == "rotflap" && flaps <=0)
            {
                if (num>0)
                {
                    face1 = 0; 
                    face2 = 1;
                }
                else 
                {
                    face1 = 2; 
                    face2 = 3;
                }
                flaps = 5;
                llSetTimerEvent(.2);
            }
        }
        else if (msg == "reset")
        {
            llSetPrimitiveParams([PRIM_ROT_LOCAL, initRot, PRIM_POS_LOCAL, (initPos), PRIM_SIZE, initSize]);
            llSetAlpha( 0, ALL_SIDES );
            flaps=0;
        }
        else if (msg == "raise")
        {
            flaps=0;
            scale(.1);
            llSleep(.4);
            llSetAlpha( 1, 0);
            llSleep(.4);
            scale(.5);
            llSleep(.4);
            scale(1.);
            isUp=1;
        }
        else if (msg == "lower"&& isUp)
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
    
    timer()
    {
        if (!isUp || flaps<=0) llSetTimerEvent(0);
        else
        {
            llSetAlpha(0, ALL_SIDES);
            flaps--;
            if (flaps%2) llSetAlpha(1, face1);
            else llSetAlpha(1, face2);
        }

    }
}
