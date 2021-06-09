using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RayBoxTest : MonoBehaviour
{
    public GameObject rayOrigin;

    private Vector3 rayDirection = new Vector3(0, 0, 1);

    void Start()
    {
        
    }

    void Update()
    {
        Vector3 exitPos = rayBoxLength(rayOrigin.transform.position, rayDirection);
        //Debug.Log(exitPos);
        this.transform.position = exitPos;
    }
    
    Vector3 rayBoxLength(Vector3 ro, Vector3 rd)
    {
        //rd *= 2; //make sure ray is longer than box
        //hvilken akse er den korteste
        float ratio = 0;
        if(rd.x > rd.y)
        {
            //x er den største
            if(rd.z > rd.x)
            {
                //z er den største
            }
            //x er den største
        } else
        {
            //y er den største
            if(rd.z > rd.y)
            {
                //z er den største
            }
            //y er den største
        }

        //rd *= ratio;

        //exit
        //find længdem af rd.
                

                
        //
        //find dens scale i forhold til 1 

        return ro+rd;
    }
}
