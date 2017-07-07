program NonStickMouse;  { http://www.jawfin.net/nsm }
(* Developed by Jonathan Barton to counter sticky corners and edges in Windows 10
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
         re-hops (flicking back to first montitor) - not wanted or required!

   This mouse... is clean.                                                      *)

uses
  Forms, Windows, Controls;

var //save runtime stack & other overheads via global vars instead of passed params
  prev:TPoint; //stores where the mouse was last frame, so we can see what direction it's moving in
  reentry:boolean; //prevent reentry of timer callback

procedure TimerCallback(hwnd:HWND;uMsg:UINT;idEvent:UINT_PTR;dwTime:DWORD);stdcall;
const
  hoplimit=30; //if delta greater than this in 1ms then is either computer controlled or will hop anyway!
  range=8; //how close it is to the corner to check for hop (now only applies when over hop limit)
var
  pt:TPoint;  //where the mouse is, and where it's going to be!
  m:TMonitor; //for quick access to the active monitor's dimensions

 function CanMove(x,y:integer):boolean;      //Tests if the new coords are sound,
{Pre:: m:TMonitor; is initialised            // on a new screen, and sets pt if it is.
 Post:: pt:TPoint; holds new mouse position}
 var
   dp:TPoint; //storage of potential destination
   dm:TMonitor; //destination monitor, if exists and not same as current monitor
 begin
   result:=false; //fails until proven true
   dp.X:=x; dp.Y:=y;
   dm:=Screen.MonitorFromPoint(dp); //now this will return the closest monitor,
   if dm<>nil then // whereas i also want to know if it really is on that screen
     if dm.MonitorNum<>m.MonitorNum then //new point is on another monitor, so move there
       if (x>=dm.BoundsRect.Left) and (x<dm.BoundsRect.Right) and //if it is within that screen's bounds
          (y>=dm.BoundsRect.Top) and (y<dm.BoundsRect.Bottom) then //this is needed to check for true diag hop
       begin
         pt:=dp;
         result:=true;
       end;
 end; //End CanMove

var //declared here so not accidently used in CanMove()
  doCheck:boolean; //not really needed, but adds to speed and lowers overhead
  br:TRect; //just an alias really

begin //Begin TimerCallback
  if reentry then //one at a time please
    exit;         //ASSERT: Shouldn't happen, but I don't trust the poll enough to not check
  reentry:=true;
  try
    pt:=Mouse.CursorPos; //vars used in nested CanMove() above too
    if (pt.X=prev.X) and (pt.Y=prev.Y) then //not moving, don't check any further
      exit;  //note: the finally block still executes
    m:=Screen.MonitorFromPoint(pt);
    if m=nil then //Danger, danger, Will Robinson.
      exit;       //Lost in Space! Our only hope now is Dr. Smith!!
    doCheck:=(pt.X-prev.X>-hoplimit) and (pt.X-prev.X<hoplimit) and //limit hop check range
             (pt.Y-prev.Y>-hoplimit) and (pt.Y-prev.Y<hoplimit);
    if not doCheck then //out of hop range, check for near corner
    begin
      br:=m.BoundsRect; //for checking the corners (if over hop limit but jammed)
      doCheck:=
        ( (pt.X>=br.Left)     and (pt.X<=br.Left+range)    and //checking same screen an very near a corner
          (pt.Y>=br.Top)      and (pt.Y<=br.Top+range)         ) or //top left
        ( (pt.X<=br.Right-1)  and (pt.X>=br.Right-1-range) and //1st check is same screen, 2nd is the range
          (pt.Y>=br.Top)      and (pt.Y<=br.Top+range)         ) or //top right
        ( (pt.X>=br.Left)     and (pt.X<=br.Left+range)    and
          (pt.Y<=br.Bottom-1) and (pt.Y>=br.Bottom-1-range)    ) or //bottom left
        ( (pt.X<=br.Right-1)  and (pt.X>=br.Right-1-range) and
          (pt.Y<=br.Bottom-1) and (pt.Y>=br.Bottom-1-range)    );   //bottom right
    end;
    if doCheck then //either under hop range or near a corner, now check trajectory
      if CanMove(pt.X*2-prev.X,pt.Y*2-prev.Y) then //draws from pt & m, and sets new pt if moving
        SetCursorPos(pt.X,pt.Y); //something about the whole point of this application!
    prev:=pt; //our current point, whether its original or where we placed it is stored
  finally //user locked screen / logged out? or just some random unhappiness
    reentry:=false;
  end;
end; //End TimerCallback

var //"local" vars for the main proc
  Msg:TMsg;
begin //main code, program starts here, contains main loop
  prev.X:=0; prev.Y:=0; //people who comment like "initialise variables" should be fired!
  reentry:=false;       // the code tells us what, the comments tells us why!!
  if SetTimer(0,0,1,@TimerCallback)=0 then //poll mouse position frequently
    exit;   //not enough resources??!?
  while Int32(GetMessage(Msg,0,0,0))<>-1 do //Win32 Native Console Message Loop
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end. //End program

