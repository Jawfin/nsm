unit uNSM;
//Backwardly compatible to Delphi 6 or older.

interface

uses
  Windows, Forms, MultiMon, ExtCtrls, Classes, SysUtils;

type
  Tfrm = class(TForm)
    tim: TTimer;
    procedure timTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frm: Tfrm;

implementation

{$R *.dfm}

var //save runtime stack & other overheads via global vars instead of passed params
  prev:TPoint; //stores where the mouse was last frame, so we can see what direction it's moving in
  corners:boolean; //command-line parameter: when true only hops at corners, ignores the monitors sides
  lag:TDateTime; //command-line parameter: milliseconds to wait between firing, reduce toggling, default 0
  lasthop:TDateTime; //for tracking the lag parameter
const
  hoplimit:integer=0; //was 30. if delta greater than this in 50ms then is either computer controlled or will hop anyway!
  range:integer=1; //was 2. casting about from mouse position this number of pixels

procedure CheckMouse;
var
  pt:TPoint; //where the mouse is, and where it's going!
  m:HMONITOR; //for quick access to the active monitor's dimensions
  hop:boolean; //ties into lag parameter

 function CheckForMove:boolean; //returns true when mouse has to move
 {Pre:: m:HMONITOR; is initialised
 Post:: pt:TPoint; holds new mouse position
 This function is only called once, but not embedded so I can quickly "exit" the checks}
 var
   mi:TMonitorInfo; //get info for monitor's bounds
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
{
//The Trevor special
   if (pt.X=0) and (pt.Y<=113) then //top left
   begin
     pt.X:=-8;
     pt.Y:=121;
     result:=true;
     exit;
   end;
   if (pt.X=0) and (pt.Y>=1193) then //bottom left
   begin
     pt.X:=-8;
     pt.Y:=1185;
     result:=true;
     exit;
   end;
}
{
//Alice
   if (pt.X=0) and (pt.Y<=205) then //top left
   begin
     pt.X:=-8;
     pt.Y:=213;
     result:=true;
     exit;
   end;
   if (pt.X=0) and (pt.Y>=1285) then //bottom left
   begin
     pt.X:=-8;
     pt.Y:=1277;
     result:=true;
     exit;
   end;
   if (pt.X=2559) and (pt.Y<=347) then //top right
   begin
     pt.X:=2567;
     pt.Y:=355;
     result:=true;
     exit;
   end;
   if (pt.X=2559) and (pt.Y>=1115) then //bottom right
   begin
     pt.X:=2567;
     pt.Y:=1107;
     result:=true;
     exit;
   end;
}
{
//The Cameron Special - don't jump the mouse past the Show Desktop bar
   if (pt.X>1914) and (pt.X<1920) and (pt.Y>1038) and (pt.Y<1080) then
   begin
     result:=false;
     exit;
   end;
}
{
//Mine
   if (pt.X=1279) and (pt.Y>=900) then //bottom left
   begin
     pt.X:=1280+range;
     pt.Y:=900-range;
     result:=true;
     exit;
   end;
}
   result:=false;
   if corners then //from the command-line, check if in corner
   begin
     mi.cbSize:=SizeOf(mi); //prepare destination data for next call
     GetMonitorInfo(m,@mi); //get the bounds rectangle for the monitor
     br:=mi.rcMonitor;
     if not //comencify long corner checking thingy
       ((((pt.Y>=br.Top-range) and (pt.Y<=br.Top+range)) or
            ((pt.Y>=br.Bottom-range) and (pt.Y<=br.Bottom+range)))
          and
           (((pt.X>=br.Left-range) and (pt.X<=br.Left+range)) or
            ((pt.X>=br.Right-range) and (pt.X<=br.Right+range)))) then
       exit;
   end;
   //stochastic ability: it's not stuck in any corner, but see if it's approaching one
   result:=(pt.X-prev.X>-hoplimit) and (pt.X-prev.X<hoplimit) and //limit hop check range
           (pt.Y-prev.Y>-hoplimit) and (pt.Y-prev.Y<hoplimit) and // note short-circuit faster than abs()
           CanMove(pt.X*2-prev.X,pt.Y*2-prev.Y); //on it's given trajectory, will it cross a monitor?
   if result then //the check above will now cover almost all hops, but keep rest of code for completeness
     exit; //the quicker I can get out of this routine, the less CPU & memory used
   if not corners then //these var haven't been loaded yet
   begin
     mi.cbSize:=SizeOf(mi); //code repeated as this is written for speed, not optimal coding methodology (not DRY)
     GetMonitorInfo(m,@mi);
     br:=mi.rcMonitor;
   end;
   //corner checks: check diagonal then horizonal then vertical.
   if pt.Y=br.Top then //at top, do corners then check above
   begin
     if pt.X=br.Left then //top-left
     begin
       result:=CanMove(br.Left-range,br.Top-range); //check diagonal hop first
       if not result then
         if prev.X>=pt.X then //moving left
           result:=CanMove(br.Left-range,br.Top+range);
       if not result then
         if prev.Y>=pt.Y then //moving up
           result:=CanMove(br.Left+range,br.Top-range);
       exit; //whether found or not, as this condition was true then all below cannot be
     end;
     if pt.X=br.Right-1 then //top-right
     begin //code logic repeated as above
       result:=CanMove(br.Right-1+range,br.Top-range);
       if not result then
         if prev.X<=pt.X then //moving right
           result:=CanMove(br.Right-1+range,br.Top+range);
       if not result then
         if prev.Y>=pt.Y then //moving up
           result:=CanMove(br.Right-1-range,br.Top-range);
       exit; //save CPU cycles, the quicker we escape this code-block the better
     end;
     if prev.y>=pt.y then //top edge and moving up
       result:=CanMove(pt.x,br.Top-range);
     exit; //no more "tops" to check, quit now
   end;
   if pt.Y=br.Bottom-1 then //at bottom
   begin
     if pt.X=br.Left then //bottom-left
     begin
       result:=CanMove(br.Left-range,br.Bottom-1+range);
       if not result then
         if prev.X>=pt.X then //moving left
           result:=CanMove(br.Left-range,br.Bottom-range);
       if not result then
         if prev.Y<=pt.Y then //moving down
           result:=CanMove(br.Left+range,br.Bottom-1+range);
       exit;
     end;
     if pt.X=br.Right-1 then //bottom-right
     begin
       result:=CanMove(br.Right-1+range,br.Bottom-1+range);
       if not result then
         if prev.X<=pt.X then //moving right
           result:=CanMove(br.Right-1+range,br.Bottom-1-range);
       if not result then
         if prev.Y<=pt.Y then //moving down
           result:=CanMove(br.Right-1-range,br.Bottom-1+range);
       exit;
     end; //end of all corner checks, now to check below
     if prev.y<=pt.y then //bottom edge and moving down
       result:=CanMove(pt.x,br.Bottom-1+range);
     exit;
   end; //top and bottom covered its corners edges, so now only need to check sides
   if (pt.x=br.Right-1) and (prev.x<=pt.x) then //right edge and moving right
   begin //i am not checking if the mouse is dragging a window, just hop it anyway!
     result:=CanMove(br.Right-1+range,pt.y);
     exit; //note this code could be done with a list of "if then else"
   end;    // instead of exits - but harder to read even if shorter
   if (pt.x=br.Left) and (prev.x>=pt.x) then //left edge and moving left
   begin
     result:=CanMove(br.Left-range,pt.y);
     exit; //Superfluous exit, but here in case more code goes in below
   end;
 end; //End CheckForMove

begin //Begin CheckMouse
  try
    GetCursorPos(pt); //get where our mouse is now, var used in CheckForMove above too
    if (pt.X=prev.X) and (pt.Y=prev.Y) then //mouse not moving, don't check any further
      exit;
    m:=MonitorFromPoint(pt,MONITOR_DEFAULTTONULL); //what monitor our mouse is on?
    if m=0 then //Danger, danger, Will Robinson. ("Lost in Space" reference, I mean literally ... nevermind!)
      exit;
    if CheckForMove then //draws from pt & m, and sets new pt if moving
    begin
      hop:=true;
      if lag>0 then //using the command-line parameter
      begin
        hop:=lasthop+lag<now;  //set back to false if too quick
        if hop then
          lasthop:=now;
      end;
      if hop then
        SetCursorPos(pt.X,pt.Y); //something about the whole point of this application!
    end;
    prev:=pt; //our current point, whether its original or where we placed it, is stored
  finally //user locked screen / logged out? or just some random unhappiness
  end;
end; //End CheckMouse

procedure Tfrm.timTimer(Sender: TObject);
begin
  CheckMouse;
end;

procedure Tfrm.FormActivate(Sender: TObject);
begin
{$IFDEF FPC}
  Hide; //hide this form
  ShowInTaskBar:=stNever; //and remove off taskbar
{$ELSE}
  ShowWindow(handle,sw_hide); //hide this form
  ShowWindow(application.handle,sw_hide); //and remove off taskbar
{$ENDIF}
end;

procedure LoadCommandLineParameterValues;
const
  S_CORNERS='corners';  //command line parameters
  S_LAG='lag';
var
  cl:string; //clean up the command-line string for easier parsing
  i,l:integer;
  lagmsecs:integer; //lag in milliseconds
  lagstr:string; //to see if a value was provided
begin
  cl:=lowercase(GetCommandLine);
  for i:=length(cl) downto 1 do
    if not CharInSet(cl[i],['a'..'z','0'..'9']) then //remove all non alpha-numeric
      Delete(cl,i,1);
  corners:=pos(S_CORNERS,cl)>0; //the word corners is in the command line, set the flag
  lagmsecs:=0;
  l:=pos(S_LAG,cl);
  if l>0 then
  begin
    lagstr:='';
    for i:=l+Length(S_LAG) to Length(cl) do //see if 'lag' has a number after it
      if CharInSet(cl[i],['0'..'9']) then
        lagmsecs:=lagmsecs*10+Ord(cl[i])-Ord('0') //who's an old-school Pascal programmer then?
      else
        break; //on first non-number
    if lagmsecs=0 then //no explicit value set
      lagmsecs:=500; //half a 'sec
  end;
  lag:=lagmsecs/24/60/60/1000; //hours, mins, secs, ms
  lasthop:=0;
end;

initialization
  LoadCommandLineParameterValues;
end.
