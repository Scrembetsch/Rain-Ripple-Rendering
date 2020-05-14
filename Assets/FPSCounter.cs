using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FPSCounter : MonoBehaviour
{
    private int qty = 0;
    private float fpsCount = 0;

    public Text mText;
    // Update is called once per frame
    public static bool reset = false;
    void Update()
    {
        if(Time.realtimeSinceStartup > 2){
            float currentFps = 1 / Time.deltaTime;
            fpsCount += currentFps;
            qty++;
            float avgFps = fpsCount / qty;
            mText.text = "AvgFPS: " + string.Format("{0:N0}", avgFps) + "\n";
        }
        if (reset)
        {
            reset = false;
            qty = 0;
            fpsCount = 0;
        }
    }
}
