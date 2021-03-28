using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class Player : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        Debug.Log("swtart");
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void OnMove(InputValue input)
    {
        Vector2 inVec = input.Get<Vector2>();
        Vector3 moveVec = new Vector3(inVec.x, 0, inVec.y);

        this.transform.Translate(moveVec);
    }
}
