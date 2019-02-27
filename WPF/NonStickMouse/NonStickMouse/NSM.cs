

using System;
using System.Linq;
using System.Runtime.InteropServices;
using System.Timers;
using System.Windows;
using System.Windows.Input;
using WpfScreenHelper;

namespace NonStickMouse
{
    public class NSM
    {
        private Point _prev; //stores where the mouse was last frame, so we can see what direction it's moving in
        private Point _pt; //where the mouse is, and where it's going!
        private readonly double _rangeX = 2; //casting about from mouse position this number of pixels in the x direction
        private readonly double _rangeY = 170; //casting about from mouse position this number of pixels in the y direction
        private readonly double _hopLimit = 30; //if delta greater than this in 50ms  is either computer controlled or will hop anyway!
        private Screen _m = null; //for quick access to the active monitor's dimensions
        private bool _result = false;
        private Rect _br = Rect.Empty;
        #region Imports

        [DllImport("User32.dll")]
        private static extern bool SetCursorPos(int X, int Y);
        #endregion
        private readonly Timer _timer = new Timer(10);

        public NSM(int rangeX = 2, int rangeY = 2, int hopLimit = 30)
        {
            _rangeX = rangeX;
            _rangeY = rangeY;
            _hopLimit = hopLimit;
            _timer.Elapsed += Timer_Elapsed;
        }

        public void Start()
        {
            _timer.Start();
        }

        private void Timer_Elapsed(object sender, ElapsedEventArgs e)
        {
            CheckMouse();
        }

        public void CheckMouse()
        {
            _pt = WpfScreenHelper.MouseHelper.MousePosition;
            if (_pt.X == _prev.X && _pt.Y == _prev.Y)
            {
                return;
            }

            _m = Screen.FromPoint(_pt);
            if (_m == null)
                return;
            if (CheckForMove())
                SetCursorPos((int)_pt.X, (int)_pt.Y);
            _prev = _pt;

        }

        public bool CanMove(double x, double y)
        {
            _result = false;
            Point dp = new Point(x, y); //storage of potential destination
            Screen dm = Screen.FromPoint(dp);
            if (dm != null && dm.DeviceName != _m?.DeviceName)
            {
                _pt = dp;
                _result = true;
            }

            return _result;
        }

        public bool CheckForMove()
        {
            //stochastic ability: it's not stuck in any corner, but see if it's approaching one
            _result = (_pt.X - _prev.X > -_hopLimit) && (_pt.X - _prev.X < _hopLimit) && //limit hop check range
                     (_pt.Y - _prev.Y > -_hopLimit) &&
                     (_pt.Y - _prev.Y < _hopLimit) && // note short-circuit faster than abs()
                     CanMove(_pt.X * 2 - _prev.X, _pt.Y * 2 - _prev.Y); //on it's given trajectory, will it cross a monitor?
            if (_result) //the check above will now cover almost all hops, but keep rest of code for completeness
                return _result;
            //corner checks: check diagonal  horizonal  vertical.
            _br = _m.Bounds; //get the bounds rectangle for the monitor
            if (_pt.Y == _br.Top) //at top, do corners  check above
            {
                if (_pt.X == _br.Left) //top-left
                {
                    _result = CanMove(_br.Left - _rangeX, _br.Top - _rangeY); //check diagonal hop first
                    if (!_result)
                    {
                        if (_prev.X >= _pt.X) //moving left
                            _result = CanMove(_br.Left - _rangeX, _br.Top + _rangeY);
                    }

                    if (!_result)
                    {
                        if (_prev.Y >= _pt.Y) //moving up
                        {
                            _result = CanMove(_br.Left + _rangeX, _br.Top - _rangeY);
                            return _result; //whether found or not, as this condition was true  all below cannot be
                        }
                    }
                }

                if (_pt.X == _br.Right - 1) //top-right
                {
                    {
                        //code logic repeated as above
                        _result = CanMove(_br.Right - 1 + _rangeX, _br.Top - _rangeY);
                        if (!_result)
                            if (_prev.X <= _pt.X) //moving right
                                _result = CanMove(_br.Right - 1 + _rangeX, _br.Top + _rangeY);
                        if (!_result)
                            if (_prev.Y >= _pt.Y) //moving up
                                _result = CanMove(_br.Right - 1 - _rangeX, _br.Top - _rangeY);
                        return _result; //save CPU cycles, the quicker we escape this code-block the better
                    }
                    ;
                }

                if (_prev.Y >= _pt.Y) //top edge and moving up
                {
                    _result = CanMove(_pt.X, _br.Top - _rangeY);
                    return _result; //no more "tops" to check, quit now}
                }
            }

            if (_pt.Y == _br.Bottom - 1) //at bottom
            {

                if (_pt.X == _br.Left) //bottom-left
                {
                    _result = CanMove(_br.Left - _rangeX, _br.Bottom - 1 + _rangeY);
                    if (!_result)
                        if (_prev.X >= _pt.X) //moving left
                            _result = CanMove(_br.Left - _rangeX, _br.Bottom - _rangeY);
                    if (!_result)
                    {
                        if (_prev.Y <= _pt.Y) //moving down
                        {
                            _result = CanMove(_br.Left + _rangeX, _br.Bottom - 1 + _rangeY);
                            return _result;
                        }
                    }
                }

                if (_pt.X == _br.Right - 1) //bottom-right
                {
                    _result = CanMove(_br.Right - 1 + _rangeX, _br.Bottom - 1 + _rangeY);
                    if (!_result)
                    {
                        if (_prev.X <= _pt.X) //moving right
                            _result = CanMove(_br.Right - 1 + _rangeX, _br.Bottom - 1 - _rangeY);
                        return _result;
                    }

                    if (!_result)
                    {
                        if (_prev.Y <= _pt.Y) //moving down
                        {
                            _result = CanMove(_br.Right - 1 - _rangeX, _br.Bottom - 1 + _rangeY);
                            return _result;
                        }
                    }
                } //end of all corner checks, now to check below

                if (_prev.Y <= _pt.Y) //bottom edge and moving down
                {
                    _result = CanMove(_pt.X, _br.Bottom - 1 + _rangeY);
                    return _result;
                }
            } //top and bottom covered its corners edges, so now only need to check sides

            if ((_pt.X == _br.Right - 1) && (_prev.X <= _pt.X)) //right edge and moving right
            {
                //i am not checking if the mouse is dragging a window, just hop it anyway!
                _result = CanMove(_br.Right - 1 + _rangeX, _pt.Y);
                return _result; //note this code could be done with a list of "if  else"
            } // instead of return results - but harder to read even if shorter

            if ((_pt.X == _br.Left) && (_prev.X >= _pt.X)) //left edge and moving left
            {
                _result = CanMove(_br.Left - _rangeX, _pt.Y);
                return _result; //Superfluous return result, but here in case more code goes in below
            }

            return _result;
        }
    }
}
