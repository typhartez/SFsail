/*

SFsail - a sailing engine for opensim

Read more @ https://opensimworld.com/sfsail/

(c) Satyr  Aeon

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
    
*/

/* SFsail  Settings */

string ACCESS = "A";      // A=All, G=Group, O=Owner
float MAX_ANGLE = 70;     // Max boom angle

integer IS_UBODE =0;      // 1 for ubODE
integer HUD_ON=1;         // 0 = don't show hover text
integer ADV_HUD=1;        // 0 = don't show advanced info on hover text
integer THROTTLE_MAX=5;   // Max motor throttle step
float SPEEDUP=.9;        // Overall speedup of the boat
integer ENABLE_DYCAM = 1; // Enable dynamic camera
float   KEELING = 0.4;    // Change for more/less keel action
float   LEEWAY = 0.2;      // ditto for leeway

// Your boat's max speed curve (values must be 0-1) per 15 degrees from 0 to 180 degrees. Please add an extra duplicate of the last point at the end of the list.
list speedCurve = [-0.1, 0.0, 0.3, 0.8, 0.9,  .9, 1, 1, .96, 0.9, 0.7, 0.8, 0.7, 0.7];

// Optimal boom angle for each true wind angle (per 15 degrees as above)
list optAngle =   [10,  10,  10, 15, 20, 30,  45, 50, 55, 60, 65, 70, 70];


/* End of SFsail  Settings */





vector windVector = <-7.71667, 0, 0>; // default East wind
float  windDirection; // -180 , 180
float TWspeed; // m/s
float MS_TO_KNOTS = 1.944;
integer CHANNEL =0;

string status;
key avatar = NULL_KEY ; // Avatar controlling this boat

integer throttle;
integer turning;
integer JIB;
integer SAIL;
integer BOOM;
integer GENOA;
integer SPINNAKER;
integer GENNAKER;
integer WINDVANE;
integer STEER;
integer INSTRUMENTS;

integer jibIsUp;
integer spinIsUp;
integer genoaIsUp;
integer spinAngle;
float spinEff;
float windvaneOffset = 0; // rad

float AWangle;  //-180 - 180 
float boomAngle;  // degrees
float sheetAngle; // deg
float totalMiles; 
float bestAngle;  // deg
float sog;  // m/s

vector wayPoint; // Current destination or 0
list wayPoints;
float timeTick;

float holdValue = 999.0;
integer autoTrim=0;
key followId = NULL_KEY;


float curveAt(list curve, integer deg) // degrees 0-180
{
    integer idx = (integer)(deg / 15.0);
    float rem = (deg%15)/15.0;
    return llList2Float(curve, idx)*(1-rem) + llList2Float(curve, idx+1)*rem ;
}


float angleBetween(vector a, vector b)  // signed between -PI and PI
{
    vector c = a % b;
    return 2.*(0.5-(c.z>0))*llAtan2( llVecMag(c), a * b ); 
}



float AWspeed;
float TWangle;
float maxSpeed;
float efficiency;
float northAngle;
vector linear;
vector angular;
float power;

updateCourse()
{
    vector fwd  = <1,0,0>*llGetRot();
    vector vel  = llGetVel();
    vel.z=0;
    fwd.z =0;

    sog = llVecMag(vel);
    totalMiles += sog*0.000539957;

    vector AWvector = windVector-vel;
    AWspeed  = llVecMag(AWvector);
    AWangle  = angleBetween(-1*fwd, AWvector);
    TWangle  = angleBetween(-1*fwd,  windVector);

    updateSails();

    maxSpeed  = curveAt(speedCurve, (integer) llFabs(TWangle*RAD_TO_DEG) );   // 0-1
    
    bestAngle = curveAt(optAngle,   (integer) llFabs(TWangle*RAD_TO_DEG) -1); // degrees

    efficiency = llFabs(bestAngle-sheetAngle)*DEG_TO_RAD;
    efficiency = 1./((efficiency*efficiency*16.0) + 1.);

    northAngle = angleBetween(<0,1,0>, fwd)*RAD_TO_DEG;
    
    updateHud();
    updateInstruments();

    if (status == "sailing" || status == "motor")
    {
        if (!IS_UBODE && turning !=0) if (turning < 6) turning++;
    }

    if (status == "sailing")
    {
        linear.z = 0;
        
        power = 0.6; // Mainsail power
        if (jibIsUp) power += 0.3;
        else if (genoaIsUp) power += 0.4;
        
        if (spinIsUp )
        {
            spinEff =   llFabs(llCos(TWangle)) * llCos(  ( (PI-TWangle)  + spinAngle*DEG_TO_RAD  )); // spinnaker efficiency
            power += spinEff*0.4;
        }
        
        if (power >1.0) power = 1.0;

        linear.x = SPEEDUP*efficiency*maxSpeed*TWspeed*power;

        float f  = (llFabs(llSin(AWangle))+0.2)*llSin(boomAngle*DEG_TO_RAD + AWangle)*AWspeed; // Angle of attack * wind speed
        linear.y = f*LEEWAY; // leeway
        angular.x = - f * KEELING*power; // heel

        if (timeTick++>2) {
            timeTick=0;
            angular.y = -0.5; // Wavy motion
        }
        else angular.y=0;

        angular.z =0;
 


        if (autoTrim>0 && llFabs(bestAngle - sheetAngle)>3)
        {
            if (bestAngle>sheetAngle)
                sheetAngle+= 5;
            else 
                sheetAngle-= 5;
        }
        
        if (sheetAngle > MAX_ANGLE) sheetAngle = MAX_ANGLE;
        if (sheetAngle < 5) sheetAngle = 5;
        
        if (followId != NULL_KEY)
        {
            list lst  =llGetObjectDetails(followId, [OBJECT_POS]);
            if (llGetListLength(lst) ==0) 
            {
                followId=NULL_KEY;
                wayPoint = ZERO_VECTOR;
            }
            else
            {
                wayPoint = llList2Vector(lst, 0);
                wayPoint.z=0;
            }
        }
        
        if (wayPoint != ZERO_VECTOR)
        {
            vector pos = llGetPos();
            pos.z=0;
            if (llVecMag(wayPoint-pos) < 10) 
            {
                if (llGetListLength(wayPoints)>0)
                {
                    say((string)llGetListLength(wayPoints)+" waypoints left");
                    wayPoint = llList2Vector(wayPoints, 0);
                    wayPoints = [] + llDeleteSubList(wayPoints, 0 , 0);
                }
                else if (followId == NULL_KEY)
                {
                    say("Waypoint reached");
                    lowerSails();
                    wayPoint = ZERO_VECTOR;
                    return;
                }
            }
            else
            {
                angular.z  = angleBetween(wayPoint - pos, fwd)*1.2;
            }
        }
        else if (holdValue != 999.0)
        {
            if (llFabs(northAngle - holdValue)>1)
                angular.z  = (northAngle - holdValue)*DEG_TO_RAD*5.5;
        }
       

        llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, linear);
        llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, angular);
    }
    else if (status == "motor")
    {
        llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, linear);
    }

}


updateSails()
{
    boomAngle = -1*TWangle*RAD_TO_DEG;
    if ( llFabs(boomAngle) > sheetAngle ) {
        if (TWangle > 0) boomAngle = -sheetAngle;
        else boomAngle = sheetAngle;
    }
    
    if (status == "sailing")
    {
        string s = "rot";
        if (efficiency < 0.7 || maxSpeed < 0.1) s = "rotflap";
        llMessageLinked(SAIL, (integer)boomAngle, s, "");
        llMessageLinked(BOOM, (integer)boomAngle, s, "");
        
        float ja = TWangle*RAD_TO_DEG;
        if (ja > 175 ) ja = - boomAngle; //butterfly wings when downwind
        else ja = boomAngle;
        
        if (jibIsUp) llMessageLinked(JIB, (integer)ja, s, "");
        if (genoaIsUp) llMessageLinked(GENOA, (integer)ja, s, "");
        
        if (spinIsUp )
        {   
            if ( spinEff > 0.7) s = "rot";
            else s = "rotflap";
            llMessageLinked(SPINNAKER, (integer)spinAngle, s, "");
        }
    }
}

setVehicleParams() {

    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]); // Makes everything but the root prim non-physical

    llSetVehicleFlags(0);
    llSetVehicleType         (VEHICLE_TYPE_BOAT);
    llSetVehicleRotationParam(VEHICLE_REFERENCE_FRAME,ZERO_ROTATION); 
    llSetVehicleFlags( VEHICLE_FLAG_HOVER_UP_ONLY | VEHICLE_FLAG_HOVER_WATER_ONLY );


    if (IS_UBODE>0)
    {
        llSetVehicleFloatParam   (VEHICLE_LINEAR_MOTOR_TIMESCALE,9.0);
        llSetVehicleFloatParam   (VEHICLE_HOVER_HEIGHT,-.1);
        llSetVehicleFloatParam   (VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY,.3);
        llSetVehicleFloatParam   (VEHICLE_ANGULAR_MOTOR_TIMESCALE, 1.5);

    }
    else
    {
        llSetVehicleFloatParam   (VEHICLE_LINEAR_MOTOR_TIMESCALE,5.0);
        llSetVehicleFloatParam   (VEHICLE_HOVER_HEIGHT,0.1);
        llSetVehicleFloatParam   (VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY,1.0);
        llSetVehicleFloatParam   (VEHICLE_ANGULAR_MOTOR_TIMESCALE, 1.);
    }
    
    llSetVehicleFloatParam   (VEHICLE_VERTICAL_ATTRACTION_TIMESCALE, 2.);
    
    llSetVehicleVectorParam  (VEHICLE_ANGULAR_FRICTION_TIMESCALE, < 5., 2., 1.>);
    
    llSetVehicleFloatParam   (VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE,1);
    llSetVehicleVectorParam  (VEHICLE_LINEAR_FRICTION_TIMESCALE, <50.0, 1.0, 0.1>);;
    llSetVehicleVectorParam  (VEHICLE_LINEAR_MOTOR_DIRECTION,ZERO_VECTOR);

    llSetVehicleFloatParam   (VEHICLE_LINEAR_DEFLECTION_EFFICIENCY, 0.85);
    llSetVehicleFloatParam   (VEHICLE_LINEAR_DEFLECTION_TIMESCALE, 10.0);

    llSetVehicleFloatParam   (VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE, 3.0);

    llSetVehicleVectorParam  (VEHICLE_ANGULAR_MOTOR_DIRECTION,ZERO_VECTOR);

    llSetVehicleFloatParam   (VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY,1.0);
    llSetVehicleFloatParam   (VEHICLE_ANGULAR_DEFLECTION_TIMESCALE, 10.0);




    llSetVehicleFloatParam   (VEHICLE_BANKING_EFFICIENCY,0.0);
    //llSetVehicleFloatParam   (VEHICLE_BANKING_MIX,1.0);
    //llSetVehicleFloatParam   (VEHICLE_BANKING_TIMESCALE,1.2);

    llSetVehicleFloatParam   (VEHICLE_HOVER_EFFICIENCY,1.0);
    llSetVehicleFloatParam   (VEHICLE_HOVER_TIMESCALE,1.);
    llSetVehicleFloatParam   (VEHICLE_BUOYANCY,1.0);
}



string num(float num)
{
    return llGetSubString((string)num, 0,3);
}


updateInstruments()
{
    if (WINDVANE) llSetLinkPrimitiveParamsFast(WINDVANE, [PRIM_ROT_LOCAL, llEuler2Rot(<0, 0, windvaneOffset - AWangle >) ] );

    if (INSTRUMENTS) llMessageLinked(INSTRUMENTS, 887, (string)(sheetAngle)+"|"+(string)(sog*MS_TO_KNOTS)+"|"+(string)(TWangle*RAD_TO_DEG)+"|"+(string)(TWspeed*MS_TO_KNOTS)+"|"+(string)efficiency+"|"+(string)(northAngle) +"|"+(string)(AWangle*RAD_TO_DEG)+"|"+(string)(AWspeed*MS_TO_KNOTS), "");
}



string strFull  = "|||||--------";

updateHud()
{
    if (!HUD_ON) 
    {
        llSetText("", <1,1,1>, 1);
        return;
    }
    
    string s;

    s += (string)llRound((360+northAngle)%360) 
        +"° " + getRose(northAngle) + " " + num(sog*MS_TO_KNOTS)+" Kn";


    s += "\nWind: "+getRose(windDirection*RAD_TO_DEG)+ " "
            + num(TWspeed*MS_TO_KNOTS) +" Kn TWA: "
            + (string)llRound(llFabs(TWangle*RAD_TO_DEG))+"° ";

    if (autoTrim) s += "\nAutotrim";
    else s += "\nTrim";
    s += ": "+(string)((integer)sheetAngle)+"° ";

    integer t = llRound(efficiency*5.);
    s += ""+ llGetSubString(strFull, 5-t, 9-t  );


    if (ADV_HUD)
    {
        s +=  "\nAWA: "+(string)llRound(llFabs(AWangle*RAD_TO_DEG))+" AWS: "+num(AWspeed*MS_TO_KNOTS)
         + "\nM/S:" +num(maxSpeed)+ " Eff:"+num(efficiency)+" Opt: "+(string)((integer)bestAngle)
         + "\nMiles: "+num(totalMiles);
        if (wayPoint != ZERO_VECTOR)
            s +="\nWaypoint: "+(string)llRound(wayPoint.x)+", "+(string)llRound(wayPoint.y);
     //   s += "\nLin: "+(string)(linear*MS_TO_KNOTS)+ " pow:"+(string)power ;
    }

    vector color = <.3, 1,1>;
    if (efficiency > 0.7) color = <0,1,0>;
    if (maxSpeed < 0.1) color = <1,0,0>;
    llSetText(s, color ,1.0);

}



scanLinks()
{
    integer i;
    for (i=1; i <= llGetNumberOfPrims();i++)
    {
        string n = llGetLinkName(i);
        if (n == "boom") BOOM = i;
        else if (n == "jib") JIB  = i;
        else if (n == "sail") SAIL= i;
        else if (n == "steer") STEER = i;
        else if (n == "spinnaker") SPINNAKER = i;
        else if (n == "genoa") GENOA = i;
        else if (n == "windvane") 
        {
            WINDVANE = i;
            windvaneOffset = DEG_TO_RAD* ((float)llList2String( llGetLinkPrimitiveParams(i, [PRIM_DESC]),  0));
        }
        else if (n == "instruments") INSTRUMENTS= i;
    }

}



string getArrow(float dir)
{
    if ( dir <= 23 && dir >= -23) return "↑";
    else if (dir <=-157 || dir >=157)   return "↓";

    else if (dir > 112) return "↘";
    else if (dir > 67) return "→";
    else if (dir > 23) return "↗";

    else if (dir > -67) return "↖";
    else if (dir > -112) return "←";
    else return "↙";
}


string getRose(float dir)
{
    if ( dir <= 23 && dir >= -23) return "N";
    else if (dir <=-157 || dir >=157)   return "S";

    else if (dir > 112) return "SE";
    else if (dir > 67) return "E";
    else if (dir > 23) return "NE";

    else if (dir > -67) return "NW";
    else if (dir > -112) return "W";
    else return "SW";
}


float getAngle(string dir)
{
    if (dir=="nw") return 45;
    else if (dir=="ne") return -45;
    else if (dir=="e")  return -90;
    else if (dir=="s")  return 180;
    else if (dir=="sw") return 135;
    else if (dir=="se") return -135;
    else if (dir=="w")  return 90;
    else return 0;
}



upright()
{
    vector v = llRot2Euler(llGetRot());
    v.x =0; v.y =0;
    llSetRot(llEuler2Rot(v));
}

integer hasAccess(key u, string a) {

    if ( a=="A"  || u==llGetOwner() || osIsNpc(u) || (a=="G" && llSameGroup(u)) ) return TRUE;
    return FALSE;
}




say(string str)
{
    if (avatar != NULL_KEY && !osIsNpc(avatar)) llRegionSayTo(avatar, 0, str);
    else llSay(0, str);
}


setVisible(string what , float visible)
{
    integer i=0;
    for (i =1; i <= llGetNumberOfPrims(); i++)
    if (llGetLinkName(i) == what) llSetLinkAlpha(i, visible, ALL_SIDES);
}



raiseSails() {
    setVehicleParams(); // sail params
    llSetStatus(STATUS_PHYSICS,TRUE);
    linear = ZERO_VECTOR;
    angular = ZERO_VECTOR;
    status = "sailing";
    llSetText("[[  Sailing!  ]]", <0,1,1>, 1);


    llMessageLinked(LINK_ALL_CHILDREN, 888, "start", NULL_KEY);
    llMessageLinked(SAIL, 0, "raise", NULL_KEY);
    llMessageLinked(JIB, 0, "raise", NULL_KEY);
    jibIsUp  =1;
    spinIsUp =0;
    genoaIsUp=0;
    llSleep(.5);
    llSetTimerEvent(1.0);
    setVisible("fenders", 0.0);
    setVisible("anchor", 1.0);
    
    say("Sailing!");
}

startMotor()
{
    if (status == "sailing") lowerSails();
    setVehicleParams(); // doesn't hurt to do it again
    sheetAngle=0;
    boomAngle =0;
    linear = ZERO_VECTOR;
    angular = ZERO_VECTOR;
    llSetStatus(STATUS_PHYSICS,TRUE);
    llSetText("[[  Motor ON ]]", <0,1,1>, 1);
    llSetTimerEvent(1.0);
    llMessageLinked(LINK_ALL_CHILDREN , 888, "motorstart", NULL_KEY);
    status = "motor";
    setVisible("anchor", 0);
}


lowerSails() {
    say("Lowering sails.");
    llMessageLinked(LINK_ALL_CHILDREN , 888, "lower", NULL_KEY);
    status = "lower";
}

setWindVector(vector v)
{
    windVector = v;
    windDirection = angleBetween(<0,1,0>, - windVector);

    llMessageLinked(LINK_ALL_CHILDREN, (integer)(windDirection*RAD_TO_DEG), "windDirection", "");
}


moor() {
    if (status == "sailing")  lowerSails();
    say("Mooring.");
    status = "moor";
    llSetTimerEvent(0);
    llMessageLinked(LINK_ALL_CHILDREN , 888, "reset", NULL_KEY);
    reset();
    llSleep(.2);
    upright();
    setVisible("fenders", 1);
    setVisible("anchor", 0);
    llSetObjectDesc((string)totalMiles);
    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_PRIM]);
    if (SPINNAKER) llSetLinkPrimitiveParamsFast(SPINNAKER, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
    if (GENOA) llSetLinkPrimitiveParamsFast(GENOA, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
}

stopMotor()
{
    llMessageLinked(LINK_ALL_CHILDREN , 888, "motorstop", NULL_KEY);
}


integer setterListen;

reset() {
    llSetStatus(STATUS_PHYSICS,FALSE);
    llSetStatus(STATUS_PHANTOM,FALSE);
}



getPerms( key u )
{
   // if (llGetPermissionsKey() != u || !(llGetPermissions()&PERMISSION_TAKE_CONTROLS))
   llRequestPermissions(u, PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA| PERMISSION_TRIGGER_ANIMATION);
}


process(string msg)
{
    if (msg=="raise")
    {
        setWindVector( windVector );
        llTriggerSound("raise", 1.0);
        stopMotor();
        if (status != "sailing")
            raiseSails();
    }
    else if (msg=="motor")
    {
        lowerSails();
        llTriggerSound("motor", 1.0);
        llSleep(.3);
        startMotor();
    }
    else if (msg=="flip") llSetRot(llGetRot()*llEuler2Rot(<0,0,PI>));
    else if (msg == "dycam")
    {
        ENABLE_DYCAM=!ENABLE_DYCAM;
        setDycam(ENABLE_DYCAM);
    }
    else if (msg == "jib")
    {
        if (JIB && status == "sailing")
        {
            if (jibIsUp) {
                llMessageLinked(JIB, 888, "lower", "");
                jibIsUp=0;
            }
            else {
                if (!genoaIsUp)
                {
                    jibIsUp=1;
                    llMessageLinked(JIB, 888, "raise", "");
                } else say("You must lower genoa");
            }
            llTriggerSound("raise", 1);
        }
        else say("There is no jib!");
    }
    else if (msg == "genoa")
    {
        if (GENOA && status == "sailing")
        {
            if (genoaIsUp) {
                llMessageLinked(GENOA, 888, "lower", "");
                genoaIsUp=0;
            }
            else {
                if (!jibIsUp)
                {
                    genoaIsUp=1;
                    llMessageLinked(GENOA, 888, "raise", "");
                } else say("You must lower jib");
            }
            llTriggerSound("raise", 1);
        }
        else say("There is no genoa!");

    }
    else if (msg == "spin")
    {
        if (SPINNAKER && status == "sailing")
        {
            if (spinIsUp) {
                llMessageLinked(SPINNAKER, 888, "lower", "");
                spinIsUp=0;
            }
            else {
                if (llFabs(TWangle)*RAD_TO_DEG > 140)
                {
                    spinIsUp=1;
                    llMessageLinked(SPINNAKER, 888, "raise", "");
                } else say("You must face away from the wind");
            }
            llTriggerSound("raise", 1);
        }
        else say("There is no spinnaker!");
    }
    else if (msg=="lower")
    {
        llTriggerSound("raise", 1.0);
        lowerSails();
    }
    else if (msg=="moor")
    {
        llTriggerSound("raise", 1);
        moor();
    }
    else if (msg=="hold")
    {
        holdValue = northAngle;
        say("Holding heading at "+llRound(holdValue));
    }
    else if (msg=="trim")
    {
        autoTrim = !autoTrim;
        if (autoTrim) say("Auto trim enabled");
        else say("Auto trim disabled");
    }
    else if (msg=="setter")
    {
        if (setterListen<=0)
        {
            setterListen = llListen(-54001,"","","");
            say("Wind setter enabled");
        }
        else
        {
            llListenRemove(setterListen);
            setterListen = -1;
            say("Wind setter disabled");
        }
    }
    else if (msg=="w" || msg == "e" || msg == "n" || msg == "s" || msg == "nw"  || msg == "ne" || msg == "sw"  || msg == "se")
    {
        if (setterListen <=0) {
            float ang = (float)getAngle(msg);
            ang *= DEG_TO_RAD;

            setWindVector ( TWspeed*<0, -1, 0>*llEuler2Rot(<0,0, ang>) );

            say("Wind now blowing from "+msg+" ");
        }
    }
    else if (msg=="8" || msg == "11" || msg == "15" || msg == "18" || msg == "21"  || msg == "25")
    {
        setWindVector( llVecNorm(windVector)*(float)msg/MS_TO_KNOTS );
        TWspeed = llVecMag(windVector);
        say("Wind speed set to "+msg+" Knots");
    }
    else if (msg=="help")
    {
        string s = "SFsail commands:\n---\n"
        +"raise - raise mainsail & jib (trim with up/down arrows)\n"
        +"lower - lower sails\n"
        +"moor - stop sailing / motor\n"
        +"motor - lower sails, start motor"
        +"jib - hoist/drop Jib\n"
        +"spin - hoist/drop Spinnaker (use PgUp & PgDn to trim)\n"
        +"genoa - hoist/drop Genoa\n"
        +"trim - enable/disable autotrim\n"
        +"sheet nn - add degrees to sheet\n"
        +"hold - hold current heading\n"
        +"dest x y [x2 y2 x3 y3 ...] - Enable autopilot to x y region coordinates [then to x2 y2 , x3 y3 ..., optionally]\n"
        +"follow <avatar name or object name> - Use autopilot to follow a user or another boat\n"
        +"stop - Stop autopilot / following\n"
        +"flip - flip the boat when moored\n"
        +"---\n"
        +"n,s,e,w,nw,ne,sw,se- set wind direction\n"
        +"8,11,15,18,21,25 - set wind speed\n"
        +"setter - enable/disable OE/WeatherOS setter\n"
        +"hud - enable/disable hud (text)\n"
        +"adv - enable/disable advanced hud\n"
        +"milesreset - reset miles counter to zero\n"
        +"---\n"
        +"HUD indicates trim efficiency. Red means irons angle\n"
        +"\n";
        say(s);
    }
    else if (msg=="adv" ) ADV_HUD = !ADV_HUD;
    else if (msg=="hud" ) HUD_ON = !HUD_ON;
    else if (msg == "milesreset") totalMiles =0;
    else if (llSubStringIndex(msg,  "route ") ==0)
    {
        string r = llStringTrim(llGetSubString(msg, 6, -1), STRING_TRIM);

        llRegionSay(88731112, "ROUTE|"+r);
    }
    else if (llSubStringIndex(msg,  "speedup ") ==0) {
        SPEEDUP = (float)llGetSubString(msg,7, -1); 
    }
    else if (llSubStringIndex(msg,  "dest ") ==0)
    {
        wayPoints = [];
        list tk = llParseString2List(msg, [" ", ",", "<"], []);
        wayPoint.x = llList2Float(tk, 1);
        wayPoint.y = llList2Float(tk, 2);
        if (llGetListLength(tk)>3)
        {
            integer i;
            for (i=3; i < llGetListLength(tk) -1 ; i+=2)
            {
               vector v =<llList2Float(tk, i), llList2Float(tk, i+1), 0>;;
               if (v != ZERO_VECTOR) wayPoints+= v;
            }
        }
                
        if (wayPoint!= ZERO_VECTOR) say((string)(llGetListLength(wayPoints)+1)+" Waypoint(s) set");
        else 
        {
            wayPoint = ZERO_VECTOR;
            say("Waypoint(s) cleared");
        }
    }
    else if (llSubStringIndex(msg,  "follow ") ==0)
    {
        string w = llStringTrim(llGetSubString(msg, 7, -1), STRING_TRIM);
        if (w != "") 
        {
            wayPoints = [];
            wayPoint = ZERO_VECTOR;
            llSensor(w, NULL_KEY, AGENT | PASSIVE | ACTIVE, 96, PI);
        }
    }
    else if (msg =="stop")
    {
        wayPoints = [];
        wayPoint = ZERO_VECTOR;
        followId =NULL_KEY;
        say("Waypoint(s) cleared");
    }
    else if (llSubStringIndex(msg,  "umsg ") ==0)
    {
        say(llGetSubString(msg, 5, -1));
    }
}


setDycam(integer isOn)
{
    
            llClearCameraParams();
            if (isOn)
            llSetCameraParams([
                       CAMERA_ACTIVE, 1,                     // 0=INACTIVE  1=ACTIVE
                       CAMERA_BEHINDNESS_ANGLE, 15.0,         // (0 to 180) DEGREES
                       CAMERA_BEHINDNESS_LAG, 1.,           // (0 to 3) SECONDS
                       CAMERA_DISTANCE, 4.0,                 // ( 0.5 to 10) METERS
                       CAMERA_PITCH, 20.0,                    // (-45 to 80) DEGREES
                       CAMERA_POSITION_LOCKED, FALSE,        // (TRUE or FALSE)
                       CAMERA_POSITION_LAG, 1.,             // (0 to 3) SECONDS
                       CAMERA_POSITION_THRESHOLD, 4.0,       // (0 to 4) METERS
                       CAMERA_FOCUS_LOCKED, FALSE,           // (TRUE or FALSE)
                       CAMERA_FOCUS_LAG, 1. ,               // (0 to 3) SECONDS
                       CAMERA_FOCUS_THRESHOLD, 0.1,          // (0 to 4) METERS
                       CAMERA_FOCUS_OFFSET, <0.0,0.0,1.0>   // <-10,-10,-10> to <10,10,10> METERS
                      ]);
}




default
{
    state_entry()
    {
        TWspeed = llVecMag(windVector);
        setWindVector( windVector );
        llSetText("",ZERO_VECTOR,1.0);
        reset();
        totalMiles = (float)llGetObjectDesc();
        upright();
        scanLinks();

    }

    on_rez(integer n)
    {
        llResetScript();
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key u =llAvatarOnSitTarget(); // First avatar to sit controls the boat, if allowed
            if ( u == NULL_KEY) {
                if (avatar != NULL_KEY)
                {
                    llTriggerSound("raise", 1);
                    moor();
                    llReleaseControls();
                    llResetScript();
                }
           }
           else if (avatar == NULL_KEY)
           {
                if (!hasAccess(u, ACCESS)) llWhisper(0,"You are not allowed to operate this boat.");
                else {
                    avatar = u;
                    getPerms(avatar);
                    llListen(CHANNEL,"",avatar,""); //listen to first seated  avatar only...
                    say("Say 'raise' to raise sails, 'help' for commands...");
                    say("SFsail defaults to East Wind, 15 Knots...");
                }
            }
        }
    }


    run_time_permissions(integer perms) {
        if (perms & (PERMISSION_TAKE_CONTROLS)) {
            llTakeControls(CONTROL_RIGHT | CONTROL_LEFT | CONTROL_ROT_RIGHT |
            CONTROL_ROT_LEFT | CONTROL_FWD | CONTROL_BACK | CONTROL_DOWN | CONTROL_UP,TRUE,FALSE);
        }

        if ((perms & PERMISSION_CONTROL_CAMERA) && ENABLE_DYCAM) {

            setDycam(1);
        }
    }

    listen(integer ch, string n, key id, string m)
    {
        if (ch==0)
        {
               process(m);
        }
        else if (ch==-54001)
        {
            list lines=llParseString2List(m,["\n"],[]);
            if (llList2String(lines,0)=="wind")      
            {
                list tk=llParseString2List(llList2String(lines,1),["=",";","/"],[]);
                if (llList2String(tk,0)=="wvel") 
                {

                    vector newWind =llList2Vector(tk,1);
                    if (newWind != windVector)
                    {
                        llSetTimerEvent(2);
                        windVector = newWind;
                        windVector.z =0;
                        windDirection = angleBetween(<0,1,0>, - windVector);
                        TWspeed = llVecMag(windVector);

                        string s = "--------\nWIND CHANGE!\n "+getRose(windDirection*RAD_TO_DEG)+ " " + num(TWspeed*MS_TO_KNOTS) +" Kn\n--------";
                        llSetText(s, <1.000, 0.329, 0.990>, 1.);
                    }
                }
            }
        }
    }


    link_message(integer from,integer to,string msg,key id) {
        if (to ==889) process(msg); // Comes from SFposer buttons or other
    }
    
    dataserver(key id, string s)
    {
        if (llGetOwnerKey(id)  == llGetOwner())
        {
            process(s);
        }
    }

    timer()
    {
        updateCourse();
    }


    control(key id, integer held, integer change)
    {

        if ( held & (CONTROL_LEFT|CONTROL_ROT_LEFT|CONTROL_RIGHT|CONTROL_ROT_RIGHT) ) {
            if (holdValue!=999.0)
            {
                holdValue = 999.0;
                say("Course hold disabled.");
            }

            float spd;
            if (turning ==0) turning=1;
            if (held & (CONTROL_RIGHT|CONTROL_ROT_RIGHT)) spd = -turning*(.5 + sog/10.)/1.5;
            else spd = turning*(.5 + sog/10.)/1.5;

            llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION,<angular.x/2, angular.y, spd>);
            
            if (STEER && (change & (CONTROL_LEFT|CONTROL_ROT_LEFT|CONTROL_RIGHT|CONTROL_ROT_RIGHT)) ) 
                llMessageLinked(STEER, 887, (string)spd, "");

        }
        else if ( change & ~held & (CONTROL_LEFT|CONTROL_ROT_LEFT|CONTROL_RIGHT|CONTROL_ROT_RIGHT) ) {
            turning = 0;
            if (STEER ) llMessageLinked(STEER, 887, (string)0, "");
        }

        if ( change &  held & (CONTROL_FWD | CONTROL_BACK)  ) {
            if (status == "sailing") {

                if (held & CONTROL_FWD) sheetAngle+=5;
                else sheetAngle -= 5;

                if (sheetAngle>MAX_ANGLE) sheetAngle=MAX_ANGLE;
                if (sheetAngle <5) sheetAngle =5;

                updateSails();

                if (autoTrim)
                {
                    autoTrim = 0;
                    say("Auto trim disabled.");
                }
            }
            else if (status == "motor")
            {
                if (held & CONTROL_FWD)
                {
                    if (throttle < THROTTLE_MAX) throttle++;
                }
                else
                {
                    if (throttle > -THROTTLE_MAX) throttle --;
                }

                say("Throttle "+(string)throttle);
                linear = <throttle*1.2,0,0>;
            }
        }
        else if (change & held & (CONTROL_UP| CONTROL_DOWN))
        {
            if (status == "sailing" && spinIsUp)
            {
                if ( (held&CONTROL_UP) && spinAngle< 50) spinAngle+=5;
                else if ( (held&CONTROL_DOWN) && spinAngle>- 50) spinAngle-=5;                
                updateSails();
            }
        }
    }
    
    no_sensor()
    {
        say("Could not find user or object to follow!");
        followId =NULL_KEY;

    }
    
    sensor(integer n)
    {
        say("Following "+(string)llDetectedName(0)+". Say 'stop' to stop.");
        followId = llDetectedKey(0);
    }
}
