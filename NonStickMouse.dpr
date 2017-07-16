program NonStickMouse;  { http://www.jawfin.net/nsm }                         (*
Developed by Jonathan Barton to counter sticky corners and edges in Windows 10
Original: 25th November, 2015
This app checks the mouse position 1000 times a second and moves it onto the
  next monitor when it is found to be stuck in a corner or on an edge.
2nd December, 2016: -
     Added stochastic ability. Also some code streamlining.
25th April, 2017: -
     [hoplimit] Locked firing range of stochastic (thus oxymoron!)
     Fixed bug in handling lookahead, it should have priority of all checks
7th July, 2017: -
     Removed significant chunks of code when it was noticed the stochastic
      approach is all that's needed.  In fact, the legacy code was causing
      re-hops (flicking back to first monitor) - not wanted or required!
9th July, 2017: -
     Noted that a nested procedure was now only called once, so moved that
      into the body, makes code and overhead less.
     Removed range check on corner detection, and extended it to just edges.
9th July, 2017: -
     Twice in one day!
     Big rewrite, removed "heavy" units: Forms & Controls.
     Introduced unit MultiMon, and re-wrote code to use this.
     The execuable dropped from 792 KB to 31 KB!
10th July, 2017: -
     Newer approach killed diagonal only monitors.
     Merged older code with newer units to compensate.
     Code is again more complex, but it works!
16th July, 2017: -
     Removed Timer object, just replaced with a loop with CPUs sleeps.
     CPU usage is now about a 10th of what it was, if that!
     Rewrote the checking code, getting a tad more speed out of it.
     Also fixed a minor bug in the corner checking!
     Still hope the less resources I use the less chance it get flagged as a virus...

This mouse... is clean.                                                       *)

uses
  Windows, MultiMon;

var //save runtime stack & other overheads via global vars instead of passed params
  prev:TPoint; //stores where the mouse was last frame, so we can see what direction it's moving in

procedure CheckMouse;
const      //range is how far to move the mouse to get it outside the trapment zones -
  hoplimit=30; //if delta greater than this in 1ms then is either computer controlled or will hop anyway!
var
  pt:TPoint;  //where the mouse is, and where it's going to be!
  m:HMONITOR; //for quick access to the active monitor's dimensions

 function CheckForMove:boolean; //returns true when mouse has to move
 {Pre:: m:HMONITOR; is initialised
 Post:: pt:TPoint; holds new mouse position
 This function is only called once, but not embedded so I can quickly "exit" the checks}
 var
   mi:TMonitorInfo;  //get info for monitor's bounds
   br:TRect; //just an alias really

  function CanMove(x,y:integer):boolean; //tests if the new coords are sound,
  var                                    // on a new screen, and sets pt if it is
    dp:TPoint; //storage of potential destination
    dm:HMONITOR; //destination monitor, if exists and not same as current monitor
  begin
    result:=false; //fails until proven true
    dp.X:=x; dp.Y:=y;
    dm:=MonitorFromPoint(dp,MONITOR_DEFAULTTONULL); //what monitor is the projection on?
    if (dm<>0) and (dm<>m) then //valid monitor and different to our current monitor
    begin
      pt:=dp; //we want to be here!
      result:=true;
    end;
  end; //End CanMove

 begin //Begin CheckForMove
   //stochastic ability: it's not stuck in any corner, but see if it's approaching one
   result:=(pt.X-prev.X>-hoplimit) and (pt.X-prev.X<hoplimit) and //limit hop check range
           (pt.Y-prev.Y>-hoplimit) and (pt.Y-prev.Y<hoplimit) and // note short-circuit faster than abs()
           CanMove(pt.X*2-prev.X,pt.Y*2-prev.Y); //on it's given trajectory, will it cross a monitor?
   if result then //the check above will now cover almost all hops, but keep rest of code for completeness
     exit;
   //corner checks: check diagonal then horizonal then vertical.
   mi.cbSize:=SizeOf(mi); //prepare destination data for next call
   GetMonitorInfo(m,@mi); //get the bounds rectangle for the monitor
   br:=mi.rcMonitor; //check corners first, then edges.
   if pt.Y=br.Top then //at top, do corners then check above
   begin
     if pt.X=br.Left then //top-left
     begin
       result:=CanMove(br.Left-1,br.Top-1); //check diagonal hop first
       if not result then
         if prev.X>=pt.X then //moving left
           result:=CanMove(br.Left-1,br.Top+1);
       if not result then
         if prev.Y>=pt.Y then //moving up
           result:=CanMove(br.Left+1,br.Top-1);
       exit; //whether found or not, as this condition was true then all below cannot be
     end;
     if pt.X=br.Right-1 then //top-right
     begin //code logic repeated as above
       result:=CanMove(br.Right,br.Top-1); //br.Right is really br.Right-1+1
       if not result then
         if prev.X<=pt.X then //moving right
           result:=CanMove(br.Right,br.Top+1); //same here for br.Right
       if not result then
         if prev.Y>=pt.Y then //moving up
           result:=CanMove(br.Right-2,br.Top-1);
       exit; //save CPU cycles, the quicker we escape this code-block the better
     end;
     if prev.y>=pt.y then //top edge and moving up
       result:=CanMove(pt.x,br.Top-1);
     exit; //no more "tops" to check, quit now
   end;
   if pt.Y=br.Bottom-1 then //at bottom
   begin
     if pt.X=br.Left then //bottom-left
     begin
       result:=CanMove(br.Left-1,br.Bottom); //br.Bottom is really -1+1
       if not result then
         if prev.X>=pt.X then //moving left
           result:=CanMove(br.Left-1,br.Bottom-1);
       if not result then
         if prev.Y<=pt.Y then //moving down
           result:=CanMove(br.Left+1,br.Bottom); //br.Bottom is really -1+1
       exit;
     end;
     if pt.X=br.Right-1 then //bottom-right
     begin
       result:=CanMove(br.Right,br.Bottom); //br.Right & br.Bottom is -1+1
       if not result then
         if prev.X<=pt.X then //moving right
           result:=CanMove(br.Right,br.Bottom-2);
       if not result then
         if prev.Y<=pt.Y then //moving down
           result:=CanMove(br.Right-2,br.Bottom);
       exit;
     end; //end of all corner checks, now to check below
     if prev.y<=pt.y then //bottom edge and moving down
       result:=CanMove(pt.x,br.Bottom); //br.Bottom-1+1
     exit;
   end; //top and bottom covered its corners edges, so now only need to check sides
   if (pt.x=br.Right-1) and (prev.x<=pt.x) then //right edge and moving right
   begin //i am not checking if the mouse is dragging a window, just hop it anyway!
     result:=CanMove(br.Right,pt.y); //br.Right+1-1
     exit; //note this code could be done with a list of "if then else"
   end;    // instead of exits - but harder to read even if shorter
   if (pt.x=br.Left) and (prev.x>=pt.x) then //left edge and moving left
   begin
     result:=CanMove(br.Left-1,pt.y);
     exit; //Superfluous exit, but here in case more code goes in below
   end;
 end; //End CheckForMove

begin //Begin CheckMouse
  try
    GetCursorPos(pt); //get where our mouse is now, var used in CheckForMove above too
    if (pt.X=prev.X) and (pt.Y=prev.Y) then //mouse not moving, don't check any further
      exit;
    m:=MonitorFromPoint(pt,MONITOR_DEFAULTTONULL); //what monitor our mouse is on?
    if m=0 then //Danger, danger, Will Robinson.
      exit;
    if CheckForMove then //draws from pt & m, and sets new pt if moving
      SetCursorPos(pt.X,pt.Y); //something about the whole point of this application!
    prev:=pt; //our current point, whether its original or where we placed it, is stored
  finally //user locked screen / logged out? or just some random unhappiness
  end;
end; //End CheckMouse

begin //main code, program starts here, contains main loop
  prev.X:=0; prev.Y:=0; //people who comment like "initialise variables" should be fired!
  repeat
    sleep(50); //50 is near 0 CPU usage, but sensitive enough to hop without lag
    CheckMouse;
  until false;
end. //End program

