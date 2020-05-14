using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaterialChanger : MonoBehaviour
{

    public GameObject Default;
    public GameObject Gerstner;
    public GameObject Normal;
    public GameObject NormalGerstner;
    public GameObject Flipbook;
    public GameObject FlipbookGerstner;

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha1))
        {
            Default.SetActive(true);
            Gerstner.SetActive(false);
            Normal.SetActive(false);
            NormalGerstner.SetActive(false);
            Flipbook.SetActive(false);
            FlipbookGerstner.SetActive(false);
            FPSCounter.reset = true;
        }
        if (Input.GetKeyDown(KeyCode.Alpha2))
        {
            Default.SetActive(false);
            Gerstner.SetActive(true);
            Normal.SetActive(false);
            NormalGerstner.SetActive(false);
            Flipbook.SetActive(false);
            FlipbookGerstner.SetActive(false);
            FPSCounter.reset = true;
        }
        if (Input.GetKeyDown(KeyCode.Alpha3))
        {
            Default.SetActive(false);
            Gerstner.SetActive(false);
            Normal.SetActive(true);
            NormalGerstner.SetActive(false);
            Flipbook.SetActive(false);
            FlipbookGerstner.SetActive(false);
            FPSCounter.reset = true;
        }
        if (Input.GetKeyDown(KeyCode.Alpha4))
        {
            Default.SetActive(false);
            Gerstner.SetActive(false);
            Normal.SetActive(false);
            NormalGerstner.SetActive(true);
            Flipbook.SetActive(false);
            FlipbookGerstner.SetActive(false);
            FPSCounter.reset = true;
        }
        if (Input.GetKeyDown(KeyCode.Alpha5))
        {
            Default.SetActive(false);
            Gerstner.SetActive(false);
            Normal.SetActive(false);
            NormalGerstner.SetActive(false);
            Flipbook.SetActive(true);
            FlipbookGerstner.SetActive(false);
            FPSCounter.reset = true;
        }
        if (Input.GetKeyDown(KeyCode.Alpha6))
        {
            Default.SetActive(false);
            Gerstner.SetActive(false);
            Normal.SetActive(false);
            NormalGerstner.SetActive(false);
            Flipbook.SetActive(false);
            FlipbookGerstner.SetActive(true);
            FPSCounter.reset = true;
        }
    }
}
