/* 
Auto-configuring boom script for SFsail. 
The boom prim must be named "boom"
*/


vector initPos;
rotation initRot;
vector hinge;

integer TACKLE; 
vector tackleLongAxis = <0,1,0>;
vector tackleHinge;
vector tackleSize;

                
default
{
    state_entry()
    {
        initPos = llGetLocalPos();
        initRot = llGetLocalRot();
        hinge = llGetScale();
        hinge.x /=2;
        hinge.y = 0; 
        hinge.z = 0;
        
        // boom script auto-configures to rotate at 1/2 of the x axis. If that's not the case you need to provide the pivot point below:
        // hinge = <0,0,0 > ;
    }
    
    
    
    link_message(integer from, integer num, string msg,key id)
    {

        if (msg == "rot" || msg == "rotflap")
        {
            rotation add = llEuler2Rot(<0, 0, num*DEG_TO_RAD>);
            llSetPrimitiveParams([PRIM_ROT_LOCAL, add*initRot, PRIM_POS_LOCAL, (initPos+hinge*initRot)- hinge*add*initRot]);

        }
        else if (msg == "reset")
        {
            llSetPrimitiveParams([PRIM_ROT_LOCAL, initRot, PRIM_POS_LOCAL, (initPos)]);
        }
            
    }
       
}
