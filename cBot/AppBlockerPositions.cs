using System;
using System.IO;
using cAlgo.API;

namespace cAlgo.Robots
{
    // Writes how many positions are open on this account so App Blocker can read it.
    [Robot(AccessRights = AccessRights.None)]
    public class AppBlockerPositions : Robot
    {
        protected override void OnStart()
        {
            Report();
            Timer.Start(TimeSpan.FromSeconds(30));
        }

        protected override void OnTimer()
        {
            Report();
        }

        private void Report()
        {
            try
            {
                System.IO.File.WriteAllText($"positions-{Account.Number}.txt", Positions.Count.ToString());
            }
            catch (IOException e)
            {
                // OneDrive can lock the file for a moment. The next timer tick tries again.
                Print(e.Message);
            }
        }
    }
}
