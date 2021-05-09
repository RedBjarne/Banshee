 using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

/*TODO
 * W/S throttle up/down
 * A/D 
 * 
*/ 

public class Player : MonoBehaviour
{
    public TMPro.TMP_Text text;
    private float mouseTarget = 0;
    private Vector3 velocity = new Vector3(0,0,0);

    public float rollStrength = 10;
    public float rollStabilizer = .01f; //percentage correction pr update.
    private float roll = 0;

    // Start is called before the first frame update
    void Start()
    {
        text.text = "Lort";
    }

    // Update is called once per frame
    void Update()
    {
        /*Vector3 pos = this.transform.position;

        //move plate to mouse target
        float targetDiff = mouseTarget - pos.x;

        if(mouseTarget > 0) pos.x += Mathf.Min(targetDiff * .01f, 1);
        else pos.x += Mathf.Max(targetDiff * .01f, -1);

        this.transform.position = pos;
        */
        Vector3 rot = new Vector3(0, 0, roll);
        this.transform.eulerAngles = rot;
        this.transform.position += velocity;

        //dampen velocity x
        // velocity.x -= (velocity.x * .1f);
        roll -= Mathf.Min(1, (roll * rollStabilizer));

        //update text
        //text.text = "mouseTarget = " + mouseTarget + "\ncurrentPos = " + pos.x;
        text.text = "velocity = " + velocity.x + "\nroll = " + roll;
    }

    public void OnMove(InputValue input)
    {
        Vector2 inVec = input.Get<Vector2>();
        //velocity.x += inVec.x/2;*/
        roll += (-inVec.x * rollStrength);
    }

    private bool noReadings = false;
    private float lastMouseReading = 0;

    public void OnMouseMove(InputValue input)
    {
        float val = input.Get<float>();

        if(noReadings == false)
        {
            lastMouseReading = val;
            noReadings = true;
        }

        float diff =  val - lastMouseReading;
        // mouseTarget += (diff * .1f);
        if (diff > 0) diff = Mathf.Min(diff, 90);
        else diff = Mathf.Max(diff, -90);
        roll -= diff;
        roll = Mathf.Clamp(roll, -90, 90);
        lastMouseReading = val;
    }

    public void OnFire()
    {
        Debug.Log("BANG!");
        mouseTarget = 0;
    }
}
