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

This mouse... is clean.                                                       *)

uses
  Windows, MultiMon;

var //save runtime stack & other overheads via global vars instead of passed params
  prev:TPoint; //stores where the mouse was last frame, so we can see what direction it's moving in
  reentry:boolean; //prevent reentry of timer callback

procedure TimerCallback(hwnd:HWND;uMsg:UINT;idEvent:UINT_PTR;dwTime:DWORD);stdcall;
const
  hoplimit=30; //if delta greater than this in 1ms then is either computer controlled or will hop anyway!
var
  pt:TPoint;  //where the mouse is, and where it's going to be!
  m:HMONITOR; //for quick access to the active monitor's dimensions
  doCheck:boolean; //not really needed, but adds to speed and lowers overhead
  dp:TPoint; //storage of potential destination
  mi:TMonitorInfo;  //get info for monitor's bounds
  dm:HMONITOR; //destination monitor, if exists and not same as current monitor
begin //Begin TimerCallback
  if reentry then //one at a time please
    exit;         //ASSERT: Shouldn't happen, but I don't trust the poll enough to not check
  reentry:=true;
  try
    GetCursorPos(pt); //get where our mouse is now
    if (pt.X=prev.X) and (pt.Y=prev.Y) then //mouse not moving, don't check any further
      exit;  //note: the finally block still executes
    m:=MonitorFromPoint(pt,MONITOR_DEFAULTTONULL); //what monitor our mouse is on?
    if m=0 then //Danger, danger, Will Robinson.
      exit;     // our mouse is Lost in Space!
    doCheck:=(pt.X-prev.X>-hoplimit) and (pt.X-prev.X<hoplimit) and //limit hop check range
             (pt.Y-prev.Y>-hoplimit) and (pt.Y-prev.Y<hoplimit);
    if not doCheck then //out of hop range, check for near edges
    begin
      mi.cbSize:=SizeOf(mi); //prepare destination data for next call
      GetMonitorInfo(m,@mi); //get the bounds rectangle for the monitor
      doCheck:=(pt.X=mi.rcMonitor.Left) or (pt.Y=mi.rcMonitor.Top) or //left & top
               (pt.X=mi.rcMonitor.Right-1) or (pt.Y=mi.rcMonitor.Bottom-1); //right & bottom
    end;
    if doCheck then //either under hop range or on an edge
    begin
      dp.X:=pt.X*2-prev.X; //linear projected coordinate of current trajectory
      dp.Y:=pt.Y*2-prev.Y;
      dm:=MonitorFromPoint(dp,MONITOR_DEFAULTTONULL); //what monitor is the projection on?
      if (dm<>0) and (dm<>m) then //valid monitor and different to our current monitor
      begin
        pt:=dp; //we want to be here!
        SetCursorPos(pt.X,pt.Y); //something about the whole point of this application!
      end;
    end;
    prev:=pt; //our current point, whether its original or where we placed it, is stored
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

