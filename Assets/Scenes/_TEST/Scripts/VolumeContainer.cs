using UnityEngine;

public class VolumeContainer : MonoBehaviour
{
    public Vector3 volumeDimensions = new Vector3(1f, 1f, 1f);
    public GameObject lightSource;
    public Material cloudMaterial;
    
    //private Renderer _renderer;
    private MaterialPropertyBlock _matPropBlock;
    
    void Start()
    {
        CreateMesh();
        _matPropBlock = new MaterialPropertyBlock();
        //_renderer = GetComponent<Renderer>();
        updateMatProps();
    }
    
#if UNITY_EDITOR
    private void OnValidate()
    {
        CreateMesh();
        //gameCam = SceneView.lastActiveSceneView.camera;
        _matPropBlock = new MaterialPropertyBlock();
        //_renderer = GetComponent<Renderer>();
        updateMatProps();
    }
#endif
    
    private void CreateMesh()
    {
        MeshRenderer meshRenderer = gameObject.GetComponent<MeshRenderer>();
        
        if (meshRenderer == null)
        {
            meshRenderer = gameObject.AddComponent<MeshRenderer>();
            meshRenderer.sharedMaterial = cloudMaterial;
        }

        Mesh mesh = new Mesh();

        //Create quad vertex data
        Vector3[] verts = new Vector3[8];
        int[] tris = new int[36];
        Vector3[] uvw = new Vector3[8];
        //Color[] cols = new Color[8]; //vertex colors used for debugging
        
        float xPosMin = -volumeDimensions.x / 2;
        float xPosMax = volumeDimensions.x / 2;
        float yPosMin = -volumeDimensions.y / 2;
        float yPosMax = volumeDimensions.y / 2;
        float zPosMin = -volumeDimensions.z / 2;
        float zPosMax = volumeDimensions.z / 2;

        verts[0] = new Vector3(xPosMin, yPosMin, zPosMin);
        verts[1] = new Vector3(xPosMax, yPosMin, zPosMin);
        verts[2] = new Vector3(xPosMin, yPosMax, zPosMin);
        verts[3] = new Vector3(xPosMax, yPosMax, zPosMin);
        
        verts[4] = new Vector3(xPosMin, yPosMin, zPosMax);
        verts[5] = new Vector3(xPosMax, yPosMin, zPosMax);
        verts[6] = new Vector3(xPosMin, yPosMax, zPosMax);
        verts[7] = new Vector3(xPosMax, yPosMax, zPosMax);
            
        //triangles
        int triNum = 0; //2 triangles each with 3 verts
        
        //front
        tris[triNum++] = 1; //first triangle
        tris[triNum++] = 2;
        tris[triNum++] = 0;
        tris[triNum++] = 1; //second triangle
        tris[triNum++] = 3;
        tris[triNum++] = 2;
            
        //back
        tris[triNum++] = 4; //first triangle
        tris[triNum++] = 6;
        tris[triNum++] = 5;
        tris[triNum++] = 6; //second triangle
        tris[triNum++] = 7;
        tris[triNum++] = 5;
        
        //top
        tris[triNum++] = 3; //first triangle
        tris[triNum++] = 6;
        tris[triNum++] = 2;
        tris[triNum++] = 3; //second triangle
        tris[triNum++] = 7;
        tris[triNum++] = 6;
        
        //bottom
        tris[triNum++] = 0; //first triangle
        tris[triNum++] = 5;
        tris[triNum++] = 1;
        tris[triNum++] = 0; //second triangle
        tris[triNum++] = 4;
        tris[triNum++] = 5;
        
        //left
        tris[triNum++] = 0; //first triangle
        tris[triNum++] = 2;
        tris[triNum++] = 4;
        tris[triNum++] = 2; //second triangle
        tris[triNum++] = 6;
        tris[triNum++] = 4;
        
        //right
        tris[triNum++] = 1; //first triangle
        tris[triNum++] = 7;
        tris[triNum++] = 3;
        tris[triNum++] = 5; //second triangle
        tris[triNum++] = 7;
        tris[triNum++] = 1;
            
        //uvw coords
        uvw[0] = new Vector3(0,0,0);
        uvw[1] = new Vector3(1,0,0);
        uvw[2] = new Vector3(0,1,0);
        uvw[3] = new Vector3(1,1,0);
        
        uvw[4] = new Vector3(0,0,1);
        uvw[5] = new Vector3(1,0,1);
        uvw[6] = new Vector3(0,1,1);
        uvw[7] = new Vector3(1,1,1);
        
        //vertex colors
       /* float alpha = 1;
        cols[0] = new Color(0,0,0,alpha);
        cols[1] = new Color(1,0,0,alpha);
        cols[2] = new Color(0,1,0,alpha);
        cols[3] = new Color(1,1,0,alpha);
        
        cols[4] = new Color(0,0,1,alpha);
        cols[5] = new Color(1,0,1,alpha);
        cols[6] = new Color(0,1,1,alpha);
        cols[7] = new Color(1,1,1,alpha);*/

        mesh.vertices = verts;
        mesh.triangles = tris;
        //mesh.colors = cols;
        mesh.SetUVs(0, uvw);
        
        MeshFilter meshFilter = gameObject.GetComponent<MeshFilter>();
        if (meshFilter == null) meshFilter = gameObject.AddComponent<MeshFilter>();

        meshFilter.mesh = mesh;
    }
    
    //private Camera gameCam;

#if UNITY_EDITOR
    void OnDrawGizmos()
    {
        // Your gizmo drawing thing goes here if required...
        updateMatProps();
        
        // Ensure continuous Update calls.
        if (!Application.isPlaying)
        {
            UnityEditor.EditorApplication.QueuePlayerLoopUpdate();
            UnityEditor.SceneView.RepaintAll();
        }
        //gameCam = SceneView.lastActiveSceneView.camera;
        //gameCam.depthTextureMode = DepthTextureMode.DepthNormals;
    }
#endif
    
    void Update()
    {
        updateMatProps();
    }

    private void updateMatProps()
    {
        if (_matPropBlock != null) //if the material have not been defined there's no point in modifying it's parameters
        {
            GetComponent<Renderer>().GetPropertyBlock(_matPropBlock); //ensure shader properties goes into a unique block so that all clouds are rendered differently

            Vector3 volumePosition = gameObject.transform.position;
            _matPropBlock.SetVector("_cloudPos", volumePosition);
            _matPropBlock.SetVector("_cloudScale", volumeDimensions);

            Vector3 halfScale = volumeDimensions / 2;
            _matPropBlock.SetVector("_bbMin", volumePosition - halfScale);
            _matPropBlock.SetVector("_bbMax", volumePosition + halfScale);
            
            if (lightSource != null)
            {
                Vector3 lightPos = lightSource.transform.position;
                _matPropBlock.SetVector("_lightPos", lightPos);
            }
            else
            {
                Vector3 lightPos = new Vector3(-1.5f, 3.0f, 4.0f);
                _matPropBlock.SetVector("_lightPos", gameObject.transform.position+lightPos);
            }

            GetComponent<Renderer>().SetPropertyBlock(_matPropBlock);
        }
    }
}
