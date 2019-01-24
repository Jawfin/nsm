

using System;
using System.Runtime.InteropServices;
using System.Timers;
using System.Windows;
using System.Windows.Input;
using WpfScreenHelper;

namespace NonStickMouse
{
    public static class NSM
    {
        static Point prev; //stores where the mouse was last frame, so we can see what direction it's moving in
        static Point pt; //where the mouse is, and where it's going!
        static double rangex = 2; //casting about from mouse position this number of pixels in the x direction
        static double rangey = 170; //casting about from mouse position this number of pixels in the y direction
        static double hoplimit = 30; //if delta greater than this in 50ms  is either computer controlled or will hop anyway!
        static Screen m = null; //for quick access to the active monitor's dimensions
        static bool result = false;
        static Rect br = Rect.Empty;
        #region Imports

        [DllImport("User32.dll")]
        private static extern bool SetCursorPos(int X, int Y);
        #endregion
        private static readonly Timer _timer = new Timer(10);

        static NSM()
        {
            _timer.Elapsed += Timer_Elapsed;
        }

        public static void Start()
        {
            _timer.Start();
        }

        private static void Timer_Elapsed(object sender, ElapsedEventArgs e)
        {
            CheckMouse();
        }

        static public void CheckMouse()
        {
            pt = WpfScreenHelper.MouseHelper.MousePosition;
            if (pt.X == prev.X && pt.Y == prev.Y)
            {
                return;
            }

            m = Screen.FromPoint(pt);
            if (m == null)
                return;
            if (CheckForMove())
                SetCursorPos((int) pt.X, (int) pt.Y);
            prev = pt;

        }

        static public bool CanMove(double x, double y)
        {
            result = false;
            Point dp = new Point(x, y); //storage of potential destination
            Screen dm = Screen.FromPoint(dp);
            if (dm != null && dm.DeviceName != m?.DeviceName)
            {
                pt = dp;
                result = true;
            }

            return result;
        }

        static public bool CheckForMove()
        {
            //stochastic ability: it's not stuck in any corner, but see if it's approaching one
            result = (pt.X - prev.X > -hoplimit) && (pt.X - prev.X < hoplimit) && //limit hop check range
                     (pt.Y - prev.Y > -hoplimit) &&
                     (pt.Y - prev.Y < hoplimit) && // note short-circuit faster than abs()
                     CanMove(pt.X * 2 - prev.X, pt.Y * 2 - prev.Y); //on it's given trajectory, will it cross a monitor?
            if (result) //the check above will now cover almost all hops, but keep rest of code for completeness
                return result;
            //corner checks: check diagonal  horizonal  vertical.
            br = m.Bounds; //get the bounds rectangle for the monitor
            if (pt.Y == br.Top) //at top, do corners  check above
            {
                if (pt.X == br.Left) //top-left
                {
                    result = CanMove(br.Left - rangex, br.Top - rangey); //check diagonal hop first
                    if (!result)
                    {
                        if (prev.X >= pt.X) //moving left
                            result = CanMove(br.Left - rangex, br.Top + rangey);
                    }

                    if (!result)
                    {
                        if (prev.Y >= pt.Y) //moving up
                        {
                            result = CanMove(br.Left + rangex, br.Top - rangey);
                            return result; //whether found or not, as this condition was true  all below cannot be
                        }
                    }
                }

                if (pt.X == br.Right - 1) //top-right
                {
                    {
                        //code logic repeated as above
                        result = CanMove(br.Right - 1 + rangex, br.Top - rangey);
                        if (!result)
                            if (prev.X <= pt.X) //moving right
                                result = CanMove(br.Right - 1 + rangex, br.Top + rangey);
                        if (!result)
                            if (prev.Y >= pt.Y) //moving up
                                result = CanMove(br.Right - 1 - rangex, br.Top - rangey);
                        return result; //save CPU cycles, the quicker we escape this code-block the better
                    }
                    ;
                }

                if (prev.Y >= pt.Y) //top edge and moving up
                {
                    result = CanMove(pt.X, br.Top - rangey);
                    return result; //no more "tops" to check, quit now}
                }
            }

            if (pt.Y == br.Bottom - 1) //at bottom
            {

                if (pt.X == br.Left) //bottom-left
                {
                    result = CanMove(br.Left - rangex, br.Bottom - 1 + rangey);
                    if (!result)
                        if (prev.X >= pt.X) //moving left
                            result = CanMove(br.Left - rangex, br.Bottom - rangey);
                    if (!result)
                    {
                        if (prev.Y <= pt.Y) //moving down
                        {
                            result = CanMove(br.Left + rangex, br.Bottom - 1 + rangey);
                            return result;
                        }
                    }
                }

                if (pt.X == br.Right - 1) //bottom-right
                {
                    result = CanMove(br.Right - 1 + rangex, br.Bottom - 1 + rangey);
                    if (!result)
                    {
                        if (prev.X <= pt.X) //moving right
                            result = CanMove(br.Right - 1 + rangex, br.Bottom - 1 - rangey);
                        return result;
                    }

                    if (!result)
                    {
                        if (prev.Y <= pt.Y) //moving down
                        {
                            result = CanMove(br.Right - 1 - rangex, br.Bottom - 1 + rangey);
                            return result;
                        }
                    }
                } //end of all corner checks, now to check below

                if (prev.Y <= pt.Y) //bottom edge and moving down
                {
                    result = CanMove(pt.X, br.Bottom - 1 + rangey);
                    return result;
                }
            } //top and bottom covered its corners edges, so now only need to check sides

            if ((pt.X == br.Right - 1) && (prev.X <= pt.X)) //right edge and moving right
            {
                //i am not checking if the mouse is dragging a window, just hop it anyway!
                result = CanMove(br.Right - 1 + rangex, pt.Y);
                return result; //note this code could be done with a list of "if  else"
            } // instead of return results - but harder to read even if shorter

            if ((pt.X == br.Left) && (prev.X >= pt.X)) //left edge and moving left
            {
                result = CanMove(br.Left - rangex, pt.Y);
                return result; //Superfluous return result, but here in case more code goes in below
            }

            return result;
        }
    }

    }
