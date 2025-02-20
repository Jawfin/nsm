program NonStickMouse;  { https://jawfin.net/nsm }                         (*
Developed by Jawfin to counter sticky corners and edges in Windows 10
Original: 25th November, 2015
This app checks the mouse position 200 times a second and moves it onto the
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
9th May, 2018: -
     Very small changes, biggest deal is changing the hop from 8 px down to 2.
     The code changes were mostly done to keep to the same as the debug version.
10th July, 2018: -
     No actual change to the code, but significant changes to the deployment.
     Stupid AVs are firing on the modaless version, so rewritten to use a
       dummy form which is hidden as soon as the app launches.
     Now the app is 3 files and the executable is 10 times original size >.<
25th January, 2019: -
     Recompiled this branch in Delphi 19 for DPI scaling issues.
     App size change: 40KB  -->  400KB  -->  2MB (this)...
20th Feburary, 2025: -
     No actual changes, just updated for latest compilers

This mouse... is clean.                                                       *)

uses
  Forms,
  uNSM in 'uNSM.pas' {frm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Non Stick Mouse';
  Application.CreateForm(Tfrm, frm);
  Application.Run;
end.
