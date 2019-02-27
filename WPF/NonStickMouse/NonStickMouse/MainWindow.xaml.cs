using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Timers;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace NonStickMouse
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            Initialize();
            Start();

        }

        public ICommand QuitCommand => new RelayCommand(()=>Application.Current.Shutdown());

        private void MainWindow_Loaded(object sender, EventArgs eventArgs)
        {
            Start();
        }

        private void Initialize()
        {
            InitializeNsmFromArgs();
        }

        private void InitializeNsmFromArgs()
        {
            string[] args = Environment.GetCommandLineArgs();
            if (!args.Any())
            {
                _nsm = new NSM();
                return;
            }
            if (args.Length == 1 && args[0] == "?")
            {
                Console.WriteLine($"NonStickMouse.exe --rangex=2 --rangey=2 --hoplimit=30");
                Environment.Exit(0);
            }

            int rangex = 2;
            int rangey = 170;
            int hoplimit = 30;
            foreach (string[] param in args.Select(x => x.ToLower().Split('=')))
            {
                try
                {
                    switch (param[0])
                    {
                        case "--rangex":
                            rangex = int.Parse(param[1]);
                            break;
                        case "--rangey":
                            break;
                        case "--hoplimit":
                            break;
                        default:
                            Console.WriteLine($"Unknown param {param[0]}, continue? (y/n)");
                            if (Console.ReadLine() == "n")
                            {
                                Environment.Exit(0);
                            }

                            break;
                    }
                }
                catch (Exception e)
                {
                    Console.Error.WriteLine($"{e.Message}");
                }
            }

            _nsm = new NSM(rangex, rangey, hoplimit);
        }

        private NSM _nsm;
        public void Start()
        {
            _nsm.Start();
        }
    }
}
