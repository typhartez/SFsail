vector vec;
float angle;
float spd;

integer setterOn;

changeme()
{
    spd  = 7 + llFrand(22);
    angle += llFrand(2.0) - 1.; // max step 1 rad
    vec  = (1./1.94) * (<llCos(angle)*spd , llSin(angle)*spd, 0>);
    float windSpeed = llVecMag(vec)*1.944;        
    float windDir = ((llAtan2(vec.x,vec.y)* RAD_TO_DEG)+180.0);
    llSetText( (string)llRound( windDir ) +"°\n"+llGetSubString((string)windSpeed, 0,4)+" Knots", <1,1,1>, 1.);
    
    llSetLinkPrimitiveParamsFast(3, [PRIM_ROTATION, llRotBetween(<1,0,0>, vec)]);
    llSetLinkPrimitiveParamsFast(2, [PRIM_OMEGA, <0,0,1>, windSpeed/1.4, 1.0]); 
}


integer channel = 88731112;

default
{
    state_entry()
    {
        llListen(channel, "", "", "");
    }
    
    touch_start(integer n)
    {
        if (llDetectedKey(0) != llGetOwner()) return;
        list opts ;
        
        if (setterOn) opts += "Setter OFF";
        else opts += "Setter ON";
        opts += "CLOSE";
        llDialog(llGetOwner(), "Select", opts, channel);
    }
 
     listen(integer ch, string who, key id, string  m)
     {
        if (m == "Setter ON")
        {
            changeme();
            llSetTimerEvent(20);
            setterOn=1;
        }
        else if (m == "Setter OFF")
        {
            llSetTimerEvent(0);
            setterOn=0;
            llSetLinkPrimitiveParamsFast(2, [PRIM_OMEGA, <0,0,0>, 1.4, 1.0]); 
        }
        else if (llGetSubString(m, 0,5) == "ROUTE|")
        {
            
            string rn = llGetSubString(m, 6, -1);
            list ln = llParseStringKeepNulls(osGetNotecard(".Sailroutes"), ["=", "\n"], []);
            integer idx = llListFindList(ln, rn);
            if (idx >=0)
            {
                integer start =0;
                float min = 99999999.0;
                
                list pt = llParseString2List(llList2String(ln, idx+1), [" "] , []);
                integer i;
                
                vector pos = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
                pos.z =0;

                for (i=0; i < llGetListLength(pt); i+=2) // Find the closest point
                {
                    vector np = < llList2Float(pt,i) , llList2Float(pt, i+1) , 0.0> ;
                    float dist = llVecDist(np , pos  );
                    if ( min > dist)
                    {
                        min = dist;
                        start =i;
                    }
                }
                pt = llList2List(pt, start, -1);
                string d = "dest "+llDumpList2String( pt, " ");
                osMessageObject(id, d);
            }
            else osMessageObject(id, "umsg Route not found: "+rn);
        }
     }
    
    timer()
    {
        
        if (llFrand(1.) < 0.25) changeme();        
        llRegionSay(-54001, "wind\nwvel="+(string)vec);
    }
}