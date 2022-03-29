/*

SFsail instruments script. This controls the compass (prim named 'instruments') and 4 displays that are included in SFsail boats. 

*/



integer LCD_SPD;
integer LCD_TWS;
integer LCD_TWA;
integer LCD_BOOM;
integer COMPASS;



setPanel(integer lnk, integer d)
{

    float f = (d%10)/10. -0.45;
    llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXTURE,3,"", <0.11, 0.17, 0>, < f, 0.42, 0>, 0.0]);
    f = ((d/10)%10)/10. -0.45;
    llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXTURE,2,"", <0.11, 0.17, 0>, < f,  0.42, 0>, 0.0]);
    f = ((d/100)%10)/10. -0.45;
    llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXTURE,1,"", <0.11, 0.17, 0>, < f, 0.42, 0>, 0.0]);
}

string lastStr;
default
{
    state_entry()
    {
        
        integer i;
        for (i=2; i <= llGetNumberOfPrims(); i++)
        {

            if (llGetLinkName(i) == "lcd_spd") LCD_SPD = i;
            else if (llGetLinkName(i) == "lcd_boom") LCD_BOOM = i;
            else if (llGetLinkName(i) == "lcd_twa") LCD_TWA = i;
            else if (llGetLinkName(i) == "lcd_tws") LCD_TWS = i;
            else if (llGetLinkName(i) == "instruments") COMPASS = i;
        }
        
    }
    
    link_message(integer l, integer num, string str, key id)
    {
        if (num == 887)
        {
            if (lastStr != str)
            {
                list tk = llParseStringKeepNulls(str, ["|"], []);
                

                if (LCD_BOOM) setPanel(LCD_BOOM, (integer)(llList2Float(tk, 0)));
                if (LCD_SPD) setPanel(LCD_SPD, (integer)((llList2Float(tk, 1)*10)));
                if (LCD_TWA) setPanel(LCD_TWA, (integer)(llList2Float(tk, 2)));
                if (LCD_TWS) setPanel(LCD_TWS, (integer)(llList2Float(tk, 3)*10));


                if (COMPASS)
                {
                    vector col = <1, 1, 1>;
                    if (llFabs(llList2Float(tk, 2)) < 30)
                        col = <1, .5, 0.5>;
                    else if (llList2Float(tk, 4) > 0.7)
                        col = <0.5, 1,0.5>;
    
                    float ang = llList2Float(tk, 5)*DEG_TO_RAD;
    
                    if (COMPASS) llSetLinkPrimitiveParamsFast(COMPASS, [PRIM_COLOR, 0, col, 1.0, PRIM_TEXTURE,0, "", <0.8, 0.8,0>, <0,0,0>, ang]);
                    ang = llList2Float(tk, 2)*DEG_TO_RAD;
                    if (COMPASS) llSetLinkPrimitiveParamsFast(COMPASS, [ PRIM_TEXTURE, 5, "", <.9, .9, 0>, <0,0,0>, -ang]);                
                }
 
                lastStr = str;
            }
        }
    }
}